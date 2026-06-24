import SwiftUI

struct ApplicationsListView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    @State private var showSubmit = false
    @State private var statusFilter: ApplicationStatus? = nil

    private var account: ParentAccount? {
        if case .parent(let a, _) = session.current { return a }
        return nil
    }
    private var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }
    private var children: [Student] {
        parent.map { repo.childrenOf(parentId: $0.id) } ?? []
    }
    private var all: [RegistrationApplication] {
        guard let acc = account else { return [] }
        return repo.applicationsOf(parentAccountId: acc.id)
            .sorted { $0.submissionDate > $1.submissionDate }
    }
    private var filtered: [RegistrationApplication] {
        var list = all
        // SR7.3 / SR7.4 — narrow to the selected child's records.
        if let cid = session.selectedChildId {
            list = list.filter { $0.studentId == cid }
        }
        if let f = statusFilter { list = list.filter { $0.status == f } }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: L.t(.applicationStatusTitle), icon: "doc.text.magnifyingglass")
                    Spacer()
                    Button { showSubmit = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text(L.t(.newApplication))
                        }.font(.system(size: 13, weight: .semibold))
                    }.buttonStyle(SecondaryButtonStyle())
                }
                if children.count > 1 {
                    ChildScopePicker(children: children)
                }
                filterChips
                if filtered.isEmpty {
                    EmptyStateView(icon: "tray", message: L.t(.noApplications)).card()
                } else {
                    ForEach(filtered) { app in
                        ApplicationCardView(app: app)
                    }
                }
            }
            .padding(18)
        }
        .sheet(isPresented: $showSubmit) {
            SubmitApplicationView()
                .environmentObject(loc).environmentObject(repo).environmentObject(session)
        }
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

struct ApplicationDetailView: View {
    let applicationId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    @State private var showPay = false

    private var app: RegistrationApplication? {
        repo.applications.first { $0.id == applicationId }
    }
    private var school: School? {
        guard let app else { return nil }
        return repo.school(by: app.selectedSchoolId)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                if let app, let school {
                    VStack(spacing: 16) {
                        statusCard(app)
                        detailsCard(app, school)
                        if app.status == .accepted && !app.registrationFeePaid {
                            payCard(app, school)
                        }
                    }
                    .padding(18)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
        .sheet(isPresented: $showPay) {
            if let app {
                ESadadPaymentView(intent: .registration(applicationId: app.id))
                    .environmentObject(loc).environmentObject(repo)
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(.white)
                    .padding(10).background(Color.white.opacity(0.18)).clipShape(Circle())
            }
            Spacer()
            Text(L.t(.applicationDetails))
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private func statusCard(_ app: RegistrationApplication) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadge(text: app.status.localized, color: app.status.badgeColor)
                Spacer()
                Text(app.id).font(.system(size: 11).monospaced())
                    .foregroundColor(Theme.textSecondary)
            }
            Text(app.studentSnapshot.fullName)
                .font(.system(size: 20, weight: .bold))
            if app.status == .rejected, let r = app.rejectionReason {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t(.rejectionReason))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.danger)
                    Text(r).font(.system(size: 13))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(10).background(Theme.danger.opacity(0.08))
                .cornerRadius(Theme.smallRadius)
            }
        }
        .card()
    }

    private func detailsCard(_ app: RegistrationApplication, _ school: School) -> some View {
        VStack(spacing: 10) {
            InfoRow(label: L.t(.school), value: school.schoolName)
            InfoRow(label: L.t(.grade), value: app.selectedGrade)
            InfoRow(label: L.t(.academicYear), value: app.academicYear)
            InfoRow(label: L.t(.submittedAt), value: app.submissionDate.short())
            if let d = app.decisionDate {
                InfoRow(label: L.t(.decisionDate), value: d.short())
            }
            InfoRow(label: L.t(.amount), value: app.registrationFeeAmount.money())
        }
        .card()
    }

    private func payCard(_ app: RegistrationApplication, _ school: School) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "creditcard.fill").foregroundColor(Theme.accent)
                Text(L.t(.payRegistrationFee)).font(.system(size: 15, weight: .bold))
            }
            Text(loc.language == .ar
                 ? "ادفع رسوم التسجيل عبر eSadad لإكمال تسجيل طفلك."
                 : "Pay the registration fee through eSadad to complete your child's registration.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
            Button { showPay = true } label: {
                Text("\(L.t(.pay)) — \(app.registrationFeeAmount.money())")
            }.buttonStyle(PrimaryButtonStyle(icon: "creditcard.fill"))
        }
        .card()
    }
}
