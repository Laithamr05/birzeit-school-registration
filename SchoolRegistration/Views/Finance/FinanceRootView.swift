import SwiftUI

struct FinanceRootView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    @State private var query: String = ""
    @State private var selectedStudent: Student? = nil

    private var registered: [Student] {
        repo.students.filter { $0.registrationStatus == .registered }
    }
    private var filtered: [Student] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return registered }
        return registered.filter {
            $0.fullName.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderBar(title: L.t(.financeDashboard))
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    searchBar
                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       message: loc.language == .ar
                                       ? "لا توجد نتائج" : "No results")
                            .card()
                    } else {
                        ForEach(filtered) { s in
                            Button {
                                selectedStudent = s
                                // SR10.6 audit
                                if case .finance(let f) = session.current {
                                    repo.financeAccessLogs.append(
                                        FinanceAccessLog(id: UUID().uuidString,
                                                         staffId: f.id, studentId: s.id,
                                                         accessedAt: Date())
                                    )
                                }
                            } label: {
                                FinanceStudentRow(student: s)
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: $selectedStudent) { s in
            FinanceStudentDetail(student: s)
                .environmentObject(repo).environmentObject(loc)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.primaryGradient).frame(width: 50, height: 50)
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.white).font(.system(size: 20, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(L.t(.paymentRecords))
                    .font(.system(size: 17, weight: .bold))
                Text("\(registered.count) \(loc.language == .ar ? "طالب مسجَّل" : "registered students")")
                    .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .card()
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.textSecondary)
            TextField(L.t(.searchPlaceholder), text: $query)
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(Theme.smallRadius)
        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius).stroke(Theme.border, lineWidth: 1))
    }
}

struct FinanceStudentRow: View {
    let student: Student
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var school: School? {
        student.schoolId.flatMap { repo.school(by: $0) }
    }
    private var record: PaymentRecord? {
        repo.record(for: student.id, type: .tuition)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accentGradient).frame(width: 42, height: 42)
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName).font(.system(size: 15, weight: .bold))
                Text("\(student.id) • \(school?.schoolName ?? "—")")
                    .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if let r = record, r.outstandingBalance > 0 {
                StatusBadge(text: r.outstandingBalance.money(), color: Theme.danger)
            } else {
                StatusBadge(text: L.t(.paid), color: Theme.success)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(Theme.radius)
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
    }
}

struct FinanceStudentDetail: View {
    let student: Student
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var school: School? {
        student.schoolId.flatMap { repo.school(by: $0) }
    }
    private var transactions: [Payment] {
        repo.paymentsForStudent(student.id).sorted { $0.createdAt > $1.createdAt }
    }
    private var regRecord: PaymentRecord? {
        repo.record(for: student.id, type: .registration)
    }
    private var tuiRecord: PaymentRecord? {
        repo.record(for: student.id, type: .tuition)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileCard
                    if let r = regRecord {
                        balanceCard(title: L.t(.payRegistrationFee), record: r)
                    }
                    if let t = tuiRecord {
                        balanceCard(title: L.t(.payTuition), record: t)
                    }
                    SectionHeader(title: L.t(.transactions), icon: "list.bullet.rectangle")
                    if transactions.isEmpty {
                        EmptyStateView(icon: "tray", message: L.t(.noPayments)).card()
                    } else {
                        ForEach(transactions) { p in
                            PaymentHistoryRow(payment: p)
                        }
                    }
                }
                .padding(18)
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
            Text(L.t(.viewPaymentRecords)).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private var profileCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.primaryGradient).frame(width: 54, height: 54)
                Image(systemName: "person.fill")
                    .foregroundColor(.white).font(.system(size: 22, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.system(size: 18, weight: .bold))
                HStack(spacing: 6) {
                    Text(student.id).font(.system(size: 11).monospaced())
                        .foregroundColor(Theme.textSecondary)
                    Text("•").foregroundColor(Theme.textSecondary)
                    Text(school?.schoolName ?? "—")
                        .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                }
                StatusBadge(text: student.registrationStatus.localized,
                            color: student.registrationStatus.badgeColor)
            }
            Spacer()
        }
        .card()
    }

    private func balanceCard(title: String, record: PaymentRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, icon: "doc.text.magnifyingglass")
            InfoRow(label: L.t(.totalDue), value: record.totalDue.money())
            InfoRow(label: L.t(.paidAmount), value: record.totalPaid.money(),
                    valueColor: Theme.success)
            InfoRow(label: L.t(.outstandingBalance),
                    value: record.outstandingBalance.money(),
                    valueColor: record.outstandingBalance > 0 ? Theme.danger : Theme.success)
            if let d = record.lastPaymentDate {
                InfoRow(label: loc.language == .ar ? "آخر دفعة" : "Last Payment",
                        value: d.short())
            }
            if let next = record.nextInstallmentDate {
                InfoRow(label: L.t(.nextInstallment), value: next.short(),
                        valueColor: Theme.warning)
            }
            if !record.schedule.isEmpty {
                InstallmentScheduleView(schedule: record.schedule)
            }
        }
        .card()
    }
}
