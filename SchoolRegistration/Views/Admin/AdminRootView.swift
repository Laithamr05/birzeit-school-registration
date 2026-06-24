import SwiftUI

struct AdminRootView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    @State private var statusFilter: ApplicationStatus? = .pending

    private var admin: SchoolAdministrator? {
        if case .administrator(let a) = session.current { return a }
        return nil
    }
    private var schoolName: String {
        guard let a = admin else { return "" }
        return repo.school(by: a.assignedSchoolId)?.schoolName ?? ""
    }
    private var applications: [RegistrationApplication] {
        guard let a = admin else { return [] }
        let list = repo.applicationsForSchool(a.assignedSchoolId)
        if let f = statusFilter { return list.filter { $0.status == f } }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderBar(title: L.t(.adminDashboard))
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    filterChips
                    SectionHeader(title: L.t(.applicationsForReview),
                                  icon: "tray.full.fill")
                    if applications.isEmpty {
                        EmptyStateView(icon: "tray", message: L.t(.noApplications)).card()
                    } else {
                        ForEach(applications) { app in
                            AdminApplicationCard(app: app)
                        }
                    }
                }
                .padding(18)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.primaryGradient).frame(width: 50, height: 50)
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.white).font(.system(size: 20, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(schoolName).font(.system(size: 17, weight: .bold))
                    Text(loc.language == .ar ? "مدير المدرسة" : "School Administrator")
                        .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                statTile(count: count(.pending), label: L.t(.pending), color: Theme.warning)
                statTile(count: count(.accepted), label: L.t(.accepted), color: Theme.success)
                statTile(count: count(.rejected), label: L.t(.rejected), color: Theme.danger)
            }
        }
        .card()
    }

    private func count(_ s: ApplicationStatus) -> Int {
        guard let a = admin else { return 0 }
        return repo.applicationsForSchool(a.assignedSchoolId).filter { $0.status == s }.count
    }

    private func statTile(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.system(size: 22, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.10))
        .cornerRadius(Theme.smallRadius)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: loc.language == .ar ? "الكل" : "All", value: nil)
                chip(title: L.t(.pending), value: .pending)
                chip(title: L.t(.accepted), value: .accepted)
                chip(title: L.t(.rejected), value: .rejected)
            }
        }
    }
    private func chip(title: String, value: ApplicationStatus?) -> some View {
        Button { statusFilter = value } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(statusFilter == value ? Theme.primary : Theme.surfaceAlt)
                .foregroundColor(statusFilter == value ? .white : Theme.textPrimary)
                .cornerRadius(20)
        }
    }
}

struct AdminApplicationCard: View {
    let app: RegistrationApplication
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    @State private var showDecision = false

    var body: some View {
        Button { showDecision = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(app.studentSnapshot.fullName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    StatusBadge(text: app.status.localized, color: app.status.badgeColor)
                }
                HStack(spacing: 4) {
                    Text("\(L.t(.grade)): \(app.selectedGrade)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text(app.submissionDate.short())
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Text("\(L.t(.applicationRef)): \(app.id)")
                    .font(.system(size: 10).monospaced())
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(Theme.radius)
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
        }
        .sheet(isPresented: $showDecision) {
            AdminDecisionView(applicationId: app.id)
                .environmentObject(loc).environmentObject(repo)
        }
    }
}

struct AdminDecisionView: View {
    let applicationId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var loc: LocalizationManager

    @State private var reason: String = ""
    @State private var error: String? = nil
    @State private var success: String? = nil

    private var app: RegistrationApplication? {
        repo.applications.first { $0.id == applicationId }
    }
    private var school: School? {
        app.flatMap { repo.school(by: $0.selectedSchoolId) }
    }
    private var parent: Parent? {
        guard let a = app,
              let acc = repo.parentAccount(by: a.parentAccountId)
        else { return nil }
        return repo.parent(by: acc.parentId)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                if let app, let school {
                    VStack(spacing: 16) {
                        applicantCard(app)
                        detailCard(app, school)
                        if app.status == .pending {
                            decisionCard(app)
                        } else if let success {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                                Text(success).font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.success)
                            }
                            .card()
                        }
                    }
                    .padding(18)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(.white)
                    .padding(10).background(Color.white.opacity(0.18)).clipShape(Circle())
            }
            Spacer()
            Text(L.t(.reviewApplication)).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private func applicantCard(_ app: RegistrationApplication) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentGradient).frame(width: 52, height: 52)
                Image(systemName: "person.fill")
                    .foregroundColor(.white).font(.system(size: 22, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.studentSnapshot.fullName)
                    .font(.system(size: 17, weight: .bold))
                Text("\(L.t(.applicationRef)): \(app.id)")
                    .font(.system(size: 11).monospaced())
                    .foregroundColor(Theme.textSecondary)
                if let p = parent {
                    Text("\(loc.language == .ar ? "ولي الأمر" : "Parent"): \(p.fullName)")
                        .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            StatusBadge(text: app.status.localized, color: app.status.badgeColor)
        }
        .card()
    }

    private func detailCard(_ app: RegistrationApplication, _ school: School) -> some View {
        VStack(spacing: 10) {
            InfoRow(label: L.t(.school), value: school.schoolName)
            InfoRow(label: L.t(.grade), value: app.selectedGrade)
            InfoRow(label: L.t(.academicYear), value: app.academicYear)
            InfoRow(label: L.t(.childDOB), value: app.studentSnapshot.dateOfBirth.short())
            InfoRow(label: L.t(.childGender),
                    value: app.studentSnapshot.gender == .male ? L.t(.male) : L.t(.female))
            InfoRow(label: L.t(.submittedAt), value: app.submissionDate.short())
            if !app.supportingInfo.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t(.supportingInfo))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text(app.supportingInfo)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
        .card()
    }

    private func decisionCard(_ app: RegistrationApplication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t(.decision), icon: "checkmark.seal")
            VStack(alignment: .leading, spacing: 6) {
                Text(L.t(.rejectionReason))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                TextEditor(text: $reason)
                    .frame(height: 80)
                    .padding(8)
                    .background(Theme.surface)
                    .cornerRadius(Theme.smallRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius)
                                .stroke(Theme.border, lineWidth: 1))
            }
            if let error {
                Text(error).font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.danger)
            }
            HStack(spacing: 10) {
                Button { decide(.rejected) } label: {
                    HStack { Image(systemName: "xmark.circle.fill"); Text(L.t(.reject)) }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.danger)
                        .cornerRadius(Theme.radius)
                }
                Button { decide(.accepted) } label: {
                    HStack { Image(systemName: "checkmark.circle.fill"); Text(L.t(.accept)) }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.success)
                        .cornerRadius(Theme.radius)
                }
            }
        }
        .card()
    }

    private func decide(_ status: ApplicationStatus) {
        error = nil
        if status == .rejected, reason.trimmingCharacters(in: .whitespaces).isEmpty {
            error = L.t(.mustProvideReason); return
        }
        guard let idx = repo.applications.firstIndex(where: { $0.id == applicationId }) else { return }
        repo.applications[idx].status = status
        repo.applications[idx].decisionDate = Date()
        repo.applications[idx].rejectionReason = status == .rejected ? reason : nil
        if case .administrator(let a) = session.current {
            repo.applications[idx].decisionByAdminId = a.id
        }
        // SR4.5 / SR9.6 — request a notification to the parent.
        let app = repo.applications[idx]
        let childName = app.studentSnapshot.fullName
        let title: String
        let body: String
        if status == .accepted {
            title = loc.language == .ar
                ? "تم قبول طلب \(childName)"
                : "\(childName)'s application accepted"
            body = loc.language == .ar
                ? "يرجى دفع رسوم التسجيل لإكمال تسجيل طفلك."
                : "Please pay the registration fee to complete your child's registration."
        } else {
            title = loc.language == .ar
                ? "تم رفض طلب \(childName)"
                : "\(childName)'s application rejected"
            body = reason
        }
        repo.notify(parentAccountId: app.parentAccountId,
                    title: title, body: body, applicationId: app.id)
        success = loc.language == .ar
            ? "تم تسجيل القرار وإخطار ولي الأمر."
            : "Decision recorded. Parent has been notified."
    }
}
