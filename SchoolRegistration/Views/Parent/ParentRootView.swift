import SwiftUI

struct ParentRootView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var repo: DataRepository
    @State private var tab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderBar(title: L.t(.parentDashboard), showNotifications: true)
            ZStack(alignment: .bottom) {
                Group {
                    switch tab {
                    case 0: ParentHomeView()
                    case 1: ApplicationsListView()
                    case 2: PaymentsListView()
                    default: AcademicHomeView()
                    }
                }
                .padding(.bottom, 72)
                ParentTabBar(selected: $tab)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

struct ParentTabBar: View {
    @Binding var selected: Int
    @EnvironmentObject var loc: LocalizationManager

    struct Item { let icon: String; let title: String }

    var items: [Item] {
        [
            Item(icon: "house.fill", title: loc.language == .ar ? "الرئيسية" : "Home"),
            Item(icon: "doc.text.fill", title: L.t(.myApplications)),
            Item(icon: "creditcard.fill", title: L.t(.payments)),
            Item(icon: "book.fill", title: L.t(.academic)),
        ]
    }

    var body: some View {
        HStack {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selected = i
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[i].icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(items[i].title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selected == i ? Theme.primary : Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            Theme.surface
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -2)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}

struct ParentHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    @State private var showSubmit = false
    @State private var showMakePayment = false
    @State private var showSwitchChildren = false

    var account: ParentAccount? {
        if case .parent(let a, _) = session.current { return a }
        return nil
    }
    var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }
    var children: [Student] {
        guard let parent else { return [] }
        return repo.childrenOf(parentId: parent.id)
    }
    var applications: [RegistrationApplication] {
        guard let acc = account else { return [] }
        return repo.applicationsOf(parentAccountId: acc.id)
    }
    var accepted: Int { applications.filter { $0.status == .accepted }.count }
    var pending: Int { applications.filter { $0.status == .pending }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                quickActions
                childSwitcher
                applicationsSummary
            }
            .padding(18)
        }
        .sheet(isPresented: $showSubmit) {
            SubmitApplicationView()
                .environmentObject(loc)
                .environmentObject(repo)
                .environmentObject(session)
        }
        .sheet(isPresented: $showMakePayment) {
            MakePaymentView()
                .environmentObject(loc)
                .environmentObject(repo)
                .environmentObject(session)
        }
        .sheet(isPresented: $showSwitchChildren) {
            SwitchChildView()
                .environmentObject(loc)
                .environmentObject(repo)
                .environmentObject(session)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accentGradient).frame(width: 52, height: 52)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.t(.welcome))
                        .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                    Text(parent?.fullName ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                statTile(num: children.count, label: L.t(.myChildren),
                         icon: "person.2.fill", color: Theme.primary)
                statTile(num: accepted, label: L.t(.accepted),
                         icon: "checkmark.seal.fill", color: Theme.success)
                statTile(num: pending, label: L.t(.pending),
                         icon: "hourglass", color: Theme.warning)
            }
        }
        .card()
    }

    private func statTile(num: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text("\(num)")
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .cornerRadius(Theme.smallRadius)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionTile(icon: "plus.circle.fill", title: L.t(.submitApplication),
                       gradient: Theme.primaryGradient) {
                showSubmit = true
            }
            actionTile(icon: "creditcard.fill", title: L.t(.makePayment),
                       gradient: Theme.accentGradient) {
                showMakePayment = true
            }
        }
    }

    @ViewBuilder
    private func actionTile(icon: String, title: String,
                            gradient: LinearGradient, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(gradient)
            .cornerRadius(Theme.radius)
            .shadow(color: Theme.primary.opacity(0.20), radius: 8, x: 0, y: 4)
        }
    }

    private var childSwitcher: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t(.myChildren), icon: "person.2.fill")
            if children.isEmpty {
                EmptyStateView(icon: "person.crop.circle.badge.questionmark",
                               message: L.t(.noChildren))
                    .card()
            } else {
                ForEach(children) { child in
                    ChildCardView(child: child,
                                  selected: session.selectedChildId == child.id) {
                        session.selectedChildId = child.id
                    }
                }
            }
        }
    }

    private var applicationsSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t(.myApplications), icon: "doc.text.fill")
            if applications.isEmpty {
                EmptyStateView(icon: "tray", message: L.t(.noApplications)).card()
            } else {
                ForEach(applications.prefix(3)) { app in
                    ApplicationCardView(app: app)
                }
            }
        }
    }
}

struct ChildCardView: View {
    @EnvironmentObject var repo: DataRepository
    let child: Student
    let selected: Bool
    let onTap: () -> Void

    var schoolName: String? {
        guard let s = child.schoolId else { return nil }
        return repo.school(by: s)?.schoolName
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(selected ? Theme.primaryGradient : Theme.accentGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: child.gender == .female ? "figure.child" : "figure.child")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.fullName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    HStack(spacing: 6) {
                        if let s = schoolName {
                            Text(s).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                            Text("•").foregroundColor(Theme.textSecondary)
                        }
                        if let g = child.currentGrade {
                            Text(g).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                Spacer()
                StatusBadge(text: child.registrationStatus.localized,
                            color: child.registrationStatus.badgeColor)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.primary)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(Theme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(selected ? Theme.primary : Theme.border,
                            lineWidth: selected ? 2 : 1)
            )
        }
    }
}

struct ApplicationCardView: View {
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    let app: RegistrationApplication
    @State private var showDetails = false

    var schoolName: String {
        repo.school(by: app.selectedSchoolId)?.schoolName ?? "—"
    }

    var body: some View {
        Button { showDetails = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(app.studentSnapshot.fullName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    StatusBadge(text: app.status.localized, color: app.status.badgeColor)
                }
                HStack(spacing: 4) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.primary)
                    Text("\(L.t(.gradeLabel)): \(app.selectedGrade)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text(app.academicYear)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                HStack {
                    Text("\(L.t(.applicationRef)): \(app.id)")
                        .font(.system(size: 11).monospaced())
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text(app.submissionDate.short())
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(Theme.radius)
            .overlay(RoundedRectangle(cornerRadius: Theme.radius)
                        .stroke(Theme.border, lineWidth: 1))
        }
        .sheet(isPresented: $showDetails) {
            ApplicationDetailView(applicationId: app.id)
                .environmentObject(loc)
                .environmentObject(repo)
        }
    }
}
