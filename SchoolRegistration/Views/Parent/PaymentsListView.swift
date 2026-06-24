import SwiftUI

struct PaymentsListView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }
    private var account: ParentAccount? {
        if case .parent(let a, _) = session.current { return a }
        return nil
    }
    private var children: [Student] {
        parent.map { repo.childrenOf(parentId: $0.id) } ?? []
    }
    private var registeredChildren: [Student] {
        children.filter { $0.registrationStatus == .registered }
    }
    // SR7.3 / SR7.4 — child-scoped lists
    private var scopedRegisteredChildren: [Student] {
        if let cid = session.selectedChildId {
            return registeredChildren.filter { $0.id == cid }
        }
        return registeredChildren
    }
    private var history: [Payment] {
        guard let a = account else { return [] }
        var list = repo.paymentsOf(parentAccountId: a.id)
            .sorted { $0.createdAt > $1.createdAt }
        if let cid = session.selectedChildId {
            list = list.filter { $0.studentId == cid }
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: L.t(.payments), icon: "creditcard.fill")
                if children.count > 1 {
                    ChildScopePicker(children: children)
                }
                if scopedRegisteredChildren.isEmpty {
                    EmptyStateView(icon: "creditcard",
                                   message: loc.language == .ar
                                   ? "لا يوجد أبناء مسجَّلون لدفع الرسوم الدراسية بعد"
                                   : "No registered children for tuition payments yet")
                        .card()
                } else {
                    SectionHeader(title: L.t(.payTuition), icon: "graduationcap.fill")
                    ForEach(scopedRegisteredChildren) { child in
                        TuitionCard(child: child)
                    }
                }
                SectionHeader(title: L.t(.paymentHistory), icon: "clock.arrow.circlepath")
                if history.isEmpty {
                    EmptyStateView(icon: "doc", message: L.t(.noPayments)).card()
                } else {
                    ForEach(history) { p in
                        PaymentHistoryRow(payment: p)
                    }
                }
            }
            .padding(18)
        }
    }
}

struct TuitionCard: View {
    let child: Student
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    @State private var showPlan = false

    private var school: School? {
        child.schoolId.flatMap { repo.school(by: $0) }
    }
    private var record: PaymentRecord? {
        repo.record(for: child.id, type: .tuition)
    }
    private var siblingsCount: Int {
        repo.students.filter { $0.parentId == child.parentId && $0.registrationStatus == .registered }.count
    }
    private var discountPercent: Double {
        // SR8.5 — 5% extra child, cap 10%
        min(0.10, max(0, Double(siblingsCount - 1) * 0.05))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.accentGradient).frame(width: 44, height: 44)
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.white).font(.system(size: 18, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.fullName)
                        .font(.system(size: 16, weight: .bold))
                    Text(school?.schoolName ?? "—")
                        .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            if let r = record {
                VStack(spacing: 8) {
                    progressBar(paid: r.totalPaid, due: r.totalDue)
                    HStack {
                        InfoMini(label: L.t(.paidAmount), value: r.totalPaid.money(),
                                 color: Theme.success)
                        Spacer()
                        InfoMini(label: L.t(.outstandingBalance),
                                 value: r.outstandingBalance.money(),
                                 color: r.outstandingBalance > 0 ? Theme.danger : Theme.success)
                    }
                    if let next = r.nextInstallmentDate {
                        InfoRow(label: L.t(.nextInstallment), value: next.short(),
                                valueColor: Theme.warning)
                    }
                    if discountPercent > 0 {
                        InfoRow(label: L.t(.discount),
                                value: "\(Int(discountPercent*100))%",
                                valueColor: Theme.success)
                    }
                }
                if !r.schedule.isEmpty {
                    InstallmentScheduleView(schedule: r.schedule)
                }
                if r.outstandingBalance > 0 {
                    Button { showPlan = true } label: {
                        Text("\(L.t(.payTuition)) — \(r.outstandingBalance.money())")
                    }.buttonStyle(PrimaryButtonStyle(icon: "creditcard.fill"))
                }
            }
        }
        .card()
        .sheet(isPresented: $showPlan) {
            TuitionPlanView(child: child)
                .environmentObject(loc).environmentObject(repo)
        }
    }

    private func progressBar(paid: Double, due: Double) -> some View {
        let pct = due > 0 ? min(1.0, paid / due) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.surfaceAlt).frame(height: 10)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.success)
                    .frame(width: geo.size.width * pct, height: 10)
            }
        }
        .frame(height: 10)
    }
}

struct InstallmentScheduleView: View {
    let schedule: [ScheduledInstallment]
    @EnvironmentObject var loc: LocalizationManager
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.language == .ar ? "جدول الأقساط" : "Installment Schedule")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            ForEach(Array(schedule.enumerated()), id: \.element.id) { i, ins in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(ins.paid ? Theme.success : Theme.surfaceAlt)
                            .frame(width: 26, height: 26)
                        if ins.paid {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white).font(.system(size: 12, weight: .bold))
                        } else {
                            Text("\(i+1)").font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ins.dueDate.short())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(ins.paid
                             ? (loc.language == .ar ? "مدفوع" : "Paid")
                             : (loc.language == .ar ? "مستحق" : "Due"))
                            .font(.system(size: 10))
                            .foregroundColor(ins.paid ? Theme.success : Theme.warning)
                    }
                    Spacer()
                    Text(ins.amount.money())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ins.paid ? Theme.success : Theme.textPrimary)
                }
                .padding(.vertical, 4)
                if i < schedule.count - 1 {
                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 1)
                        .padding(.leading, 36)
                }
            }
        }
        .padding(12)
        .background(Theme.surfaceAlt)
        .cornerRadius(Theme.smallRadius)
    }
}

struct InfoMini: View {
    var label: String, value: String, color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(color)
        }
    }
}

struct TuitionPlanView: View {
    let child: Student
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    enum Plan { case full, installment }
    @State private var plan: Plan = .full
    @State private var customAmount: String = ""
    @State private var presentedIntent: TuitionIntentBox? = nil
    @State private var inputError: String? = nil

    private var record: PaymentRecord? {
        repo.record(for: child.id, type: .tuition)
    }
    private var balance: Double { record?.outstandingBalance ?? 0 }
    private var minInstallment: Double { balance * 0.5 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summary
                    if balance > 0 {
                        planPicker
                        if plan == .installment { installmentSection }
                        if let err = inputError {
                            Text(err).font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.danger)
                        }
                        Button { proceed() } label: {
                            Text(L.t(.confirm))
                        }
                        .buttonStyle(PrimaryButtonStyle(icon: "arrow.right.circle.fill"))
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Theme.success)
                            Text(loc.language == .ar
                                 ? "تم سداد الرسوم الدراسية بالكامل."
                                 : "Tuition is fully paid.")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.success)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.success.opacity(0.10))
                        .cornerRadius(Theme.smallRadius)
                        Button { dismiss() } label: { Text(L.t(.done)) }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(18)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
        // Sheet is bound to a captured intent — payAmount is baked in at the
        // moment proceed() runs, so SwiftUI never re-evaluates with a stale 0.
        .sheet(item: $presentedIntent, onDismiss: { dismiss() }) { box in
            ESadadPaymentView(intent: box.intent)
                .environmentObject(loc).environmentObject(repo)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(.white)
                    .padding(10).background(Color.white.opacity(0.18)).clipShape(Circle())
            }
            Spacer()
            Text(L.t(.payTuition)).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private var summary: some View {
        VStack(spacing: 8) {
            InfoRow(label: L.t(.child), value: child.fullName)
            InfoRow(label: L.t(.remainingBalance), value: balance.money(),
                    valueColor: Theme.danger)
            if let pct = multiChildDiscountPercent(), pct > 0 {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill").foregroundColor(Theme.success)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("«\(L.t(.multiChildDiscountApplied))»")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.success)
                        Text(loc.language == .ar
                             ? "خصم ٥٪ لكل طفل إضافي، بحد أقصى ١٠٪"
                             : "5% per additional child, capped at 10%")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Text("−\(Int(pct*100))%")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Theme.success)
                }
                .padding(8)
                .background(Theme.success.opacity(0.10))
                .cornerRadius(Theme.smallRadius)
            }
        }
        .card()
    }

    private func multiChildDiscountPercent() -> Double? {
        let count = repo.students.filter {
            $0.parentId == child.parentId && $0.registrationStatus == .registered
        }.count
        guard count > 1 else { return nil }
        return min(0.10, Double(count - 1) * 0.05)
    }

    private var planPicker: some View {
        HStack(spacing: 10) {
            planButton(.full, label: L.t(.fullPayment), icon: "checkmark.circle.fill")
            planButton(.installment, label: L.t(.installmentPlan), icon: "calendar")
        }
    }

    private func planButton(_ p: Plan, label: String, icon: String) -> some View {
        Button { plan = p } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.vertical, 14).frame(maxWidth: .infinity)
            .background(plan == p ? Theme.primary : Theme.surfaceAlt)
            .foregroundColor(plan == p ? .white : Theme.textPrimary)
            .cornerRadius(Theme.smallRadius)
        }
    }

    private var installmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(L.t(.firstPayment)) — \(loc.language == .ar ? "الحد الأدنى:" : "min:") \(minInstallment.money())")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            AppTextField(label: L.t(.amount), text: $customAmount,
                         placeholder: minInstallment.money(),
                         icon: "dollarsign.circle.fill", keyboard: .decimalPad)
            Text(loc.language == .ar
                 ? "سيتم تقسيم الرصيد المتبقي على ٤ أقساط شهرية كحد أقصى."
                 : "Remaining balance will be split across up to 4 monthly installments.")
                .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
        }
        .card()
    }

    private func proceed() {
        inputError = nil
        let amount: Double
        if plan == .full {
            amount = balance
        } else {
            let parsed = Double(customAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
            amount = max(parsed, minInstallment)
        }
        guard amount > 0 else {
            inputError = loc.language == .ar
                ? "أدخل مبلغًا أكبر من صفر." : "Enter an amount greater than zero."
            return
        }
        let intent: PaymentIntent = plan == .full
            ? .tuitionFull(studentId: child.id, amount: amount)
            : .tuitionInstallment(studentId: child.id, amount: amount)
        presentedIntent = TuitionIntentBox(intent: intent)
    }
}

struct TuitionIntentBox: Identifiable {
    let intent: PaymentIntent
    var id: String {
        switch intent {
        case .registration(let appId):            return "reg-" + appId
        case .tuitionFull(let sid, let a):        return "tui-full-\(sid)-\(a)"
        case .tuitionInstallment(let sid, let a): return "tui-ins-\(sid)-\(a)"
        }
    }
}

struct PaymentHistoryRow: View {
    let payment: Payment
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager
    private var studentName: String {
        repo.student(by: payment.studentId)?.fullName ?? "—"
    }
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(payment.status == .paid ? Theme.success.opacity(0.15) :
                          payment.status == .declined ? Theme.danger.opacity(0.15) :
                          Theme.warning.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: payment.paymentType == .registration
                                  ? "doc.text.fill" : "graduationcap.fill")
                    .foregroundColor(payment.status == .paid ? Theme.success :
                                     payment.status == .declined ? Theme.danger : Theme.warning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.paymentType == .registration
                     ? L.t(.payRegistrationFee) : L.t(.payTuition))
                    .font(.system(size: 14, weight: .bold))
                HStack(spacing: 6) {
                    Text(studentName)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                    Text("•").foregroundColor(Theme.textSecondary)
                    Text(payment.referenceNo)
                        .font(.system(size: 10).monospaced())
                        .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.amount.money())
                    .font(.system(size: 14, weight: .bold))
                StatusBadge(text: payment.status.localized, color: payment.status.badgeColor)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(Theme.radius)
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
    }
}
