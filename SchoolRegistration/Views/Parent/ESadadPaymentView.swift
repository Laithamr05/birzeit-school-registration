import SwiftUI

enum PaymentIntent {
    case registration(applicationId: String)
    case tuitionFull(studentId: String, amount: Double)
    case tuitionInstallment(studentId: String, amount: Double)
}

struct ESadadPaymentView: View {
    let intent: PaymentIntent
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    enum Stage { case review, awaiting, success, declined }
    @State private var stage: Stage = .review
    @State private var reference: String = ""
    @State private var receipt: String = ""
    @State private var showCopied = false
    @State private var declineReason: String = ""

    private var typeForIntent: PaymentType {
        switch intent {
        case .registration: return .registration
        default: return .tuition
        }
    }

    private var amount: Double {
        switch intent {
        case .registration(let id):
            return repo.applications.first { $0.id == id }?.registrationFeeAmount ?? 0
        case .tuitionFull(_, let a), .tuitionInstallment(_, let a):
            return a
        }
    }

    private var studentName: String {
        switch intent {
        case .registration(let id):
            return repo.applications.first { $0.id == id }?.studentSnapshot.fullName ?? "—"
        case .tuitionFull(let sid, _), .tuitionInstallment(let sid, _):
            return repo.student(by: sid)?.fullName ?? "—"
        }
    }

    private var titleText: String {
        switch intent {
        case .registration: return L.t(.payRegistrationFee)
        case .tuitionFull, .tuitionInstallment: return L.t(.payTuition)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 16) {
                        switch stage {
                        case .review: reviewStage
                        case .awaiting: awaitingStage
                        case .success: successStage
                        case .declined: declinedStage
                        }
                    }
                    .padding(18)
                }
                if showCopied {
                    Toast(text: L.t(.paymentReferenceCopied))
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").foregroundColor(.white)
                    .padding(10).background(Color.white.opacity(0.18)).clipShape(Circle())
            }
            Spacer()
            Text(titleText)
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    // MARK: - Stage: review

    private var reviewStage: some View {
        VStack(spacing: 16) {
            esadadBrand
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: loc.language == .ar ? "ملخص الدفع" : "Payment Summary",
                              icon: "doc.text.fill")
                InfoRow(label: L.t(.child), value: studentName)
                InfoRow(label: loc.language == .ar ? "نوع الدفع" : "Type",
                        value: titleText)
                if let pct = applicableDiscountPercent(), pct > 0 {
                    Divider().padding(.vertical, 4)
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill").foregroundColor(Theme.success)
                        Text("«\(L.t(.multiChildDiscountApplied))»")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.success)
                        Spacer()
                        Text("−\(Int(pct*100))%")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Theme.success)
                    }
                }
                Divider().padding(.vertical, 4)
                HStack {
                    Text(L.t(.totalDue))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text(amount.money())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
            }
            .card()

            if amount > 0 {
                Button { startPayment() } label: {
                    Text(L.t(.confirm))
                }.buttonStyle(PrimaryButtonStyle(icon: "creditcard.fill"))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                    Text(loc.language == .ar
                         ? "لا توجد رسوم مستحقة — هذه الفاتورة مدفوعة بالكامل."
                         : "Nothing to pay — this balance is fully settled.")
                        .font(.system(size: 13, weight: .semibold))
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
    }

    private func applicableDiscountPercent() -> Double? {
        guard case .tuitionFull(let sid, _) = intent else {
            if case .tuitionInstallment(let sid, _) = intent {
                return multiChildDiscount(for: sid)
            }
            return nil
        }
        return multiChildDiscount(for: sid)
    }

    private func multiChildDiscount(for studentId: String) -> Double? {
        guard let stu = repo.student(by: studentId) else { return nil }
        let count = repo.students.filter {
            $0.parentId == stu.parentId && $0.registrationStatus == .registered
        }.count
        guard count > 1 else { return nil }
        return min(0.10, Double(count - 1) * 0.05)
    }

    private var esadadBrand: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white).frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                Image(systemName: "banknote.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Theme.accent, Theme.primary],
                                                    startPoint: .leading, endPoint: .trailing))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("eSadad").font(.system(size: 20, weight: .heavy))
                Text(loc.language == .ar ? "بوابة الدفع الموحّدة" : "Unified Payment Gateway")
                    .font(.system(size: 12)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Theme.accent.opacity(0.18), Color.white],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(Theme.radius)
    }

    // MARK: - Stage: awaiting (the user's emphasized flow)

    private var awaitingStage: some View {
        VStack(spacing: 16) {
            esadadBrand

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.primary)
                    Text(L.t(.esadadFlowTitle))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                Text(L.t(.esadadFlowBody))
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Reference number (the centerpiece)
                VStack(spacing: 8) {
                    Text(L.t(.reference))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text(reference)
                        .font(.system(size: 26, weight: .heavy).monospaced())
                        .foregroundColor(Theme.primaryDark)
                        .padding(.vertical, 10).padding(.horizontal, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.primary.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        )
                        .background(Theme.surfaceAlt.cornerRadius(14))
                    Button {
                        UIPasteboard.general.string = reference
                        withAnimation { showCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showCopied = false }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc.fill")
                            Text(L.t(.copyReference))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.primary.opacity(0.1))
                        .foregroundColor(Theme.primary)
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Theme.surface)
                .cornerRadius(Theme.smallRadius)
                .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius)
                            .stroke(Theme.border, lineWidth: 1))

                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 10) {
                    Text(L.t(.paymentInstructions))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    instructionStep(num: 1,
                                    text: loc.language == .ar
                                    ? "افتح تطبيق eSadad على هاتفك."
                                    : "Open the eSadad app on your phone.")
                    instructionStep(num: 2,
                                    text: loc.language == .ar
                                    ? "اختر «استعلام عن فاتورة» وأدخل الرقم المرجعي أعلاه."
                                    : "Choose \"Inquire about a bill\" and enter the reference above.")
                    instructionStep(num: 3,
                                    text: loc.language == .ar
                                    ? "أكّد المبلغ \(amount.money()) ثم أتمم عملية الدفع."
                                    : "Confirm the \(amount.money()) amount and complete payment.")
                    instructionStep(num: 4,
                                    text: loc.language == .ar
                                    ? "عُد إلى هذا التطبيق واضغط «تمت عملية الدفع»."
                                    : "Return here and tap \"I've paid via eSadad\".")
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceAlt)
                .cornerRadius(Theme.smallRadius)
            }
            .card()

            // SR5.4 / SR8.8 — system marks paid only after the parent confirms
            // completion via eSadad and the bank approves.
            Button { confirmPaid() } label: {
                Text(L.t(.markAsPaid))
            }.buttonStyle(PrimaryButtonStyle(icon: "checkmark.seal.fill"))

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                Text(loc.language == .ar
                     ? "بانتظار تأكيد البنك بعد إتمام الدفع في eSadad."
                     : "Waiting for the bank to confirm once you've paid in eSadad.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }
        }
    }

    private func instructionStep(num: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(num)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Theme.primary)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Stage: success

    private var successStage: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Theme.success.opacity(0.15)).frame(width: 110, height: 110)
                Circle().fill(Theme.success).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .heavy)).foregroundColor(.white)
            }
            .padding(.top, 20)
            Text(L.t(.paymentSuccess))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.success)

            VStack(spacing: 10) {
                InfoRow(label: L.t(.amount), value: amount.money(), valueColor: Theme.primary)
                InfoRow(label: L.t(.reference), value: reference)
                InfoRow(label: loc.language == .ar ? "رقم الإيصال" : "Receipt #", value: receipt)
                InfoRow(label: L.t(.date), value: Date().short())
            }
            .card()

            Button { dismiss() } label: { Text(L.t(.done)) }
                .buttonStyle(PrimaryButtonStyle(icon: "checkmark.circle.fill"))
        }
    }

    // MARK: - Stage: declined

    private var declinedStage: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Theme.danger.opacity(0.15)).frame(width: 110, height: 110)
                Circle().fill(Theme.danger).frame(width: 80, height: 80)
                Image(systemName: "xmark")
                    .font(.system(size: 36, weight: .heavy)).foregroundColor(.white)
            }
            .padding(.top, 20)
            Text(L.t(.paymentDeclined))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.danger)
                .multilineTextAlignment(.center)
            if !declineReason.isEmpty {
                Text(declineReason)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button { stage = .review } label: {
                Text(loc.language == .ar ? "إعادة المحاولة" : "Try Again")
            }.buttonStyle(PrimaryButtonStyle(icon: "arrow.clockwise"))
            Button { dismiss() } label: { Text(L.t(.cancel)) }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Actions

    private func startPayment() {
        reference = ESadadBankService.generateReference(type: typeForIntent)
        recordPendingPayment()
        withAnimation { stage = .awaiting }
    }

    private func recordPendingPayment() {
        let (studentId, applicationId, parentAccountId) = paymentParticipants()
        let p = Payment(id: "PAY-\(Int.random(in: 1000...9999))",
                        applicationId: applicationId, studentId: studentId,
                        parentAccountId: parentAccountId, amount: amount,
                        paymentType: typeForIntent, status: .pending,
                        referenceNo: reference, createdAt: Date(),
                        paidAt: nil, failureReason: nil, receiptNumber: nil)
        repo.payments.append(p)
    }

    private func paymentParticipants() -> (String, String?, String) {
        switch intent {
        case .registration(let id):
            if let app = repo.applications.first(where: { $0.id == id }) {
                return (app.studentId, app.id, app.parentAccountId)
            }
        case .tuitionFull(let sid, _), .tuitionInstallment(let sid, _):
            if let stu = repo.student(by: sid),
               let acc = repo.parentAccounts.first(where: { $0.parentId == stu.parentId }) {
                return (sid, nil, acc.id)
            }
        }
        return ("?", nil, "?")
    }

    private func confirmPaid() {
        // SR5.4 / SR8.8 — only mark paid after eSadad confirms (simulated)
        let result = ESadadBankService.confirmPayment(reference: reference)
        switch result {
        case .approved(let r):
            receipt = r
            applyApprovedSideEffects()
            withAnimation { stage = .success }
        case .declined(let reason):
            declineReason = reason
            applyDeclined(reason: reason)
            withAnimation { stage = .declined }
        case .unavailable:
            declineReason = loc.language == .ar ? "تعذّر الاتصال بالبنك" : "Bank unreachable"
            withAnimation { stage = .declined }
        }
    }

    private func applyApprovedSideEffects() {
        // mark payment paid
        if let idx = repo.payments.firstIndex(where: { $0.referenceNo == reference }) {
            repo.payments[idx].status = .paid
            repo.payments[idx].paidAt = Date()
            repo.payments[idx].receiptNumber = receipt
        }
        switch intent {
        case .registration(let appId):
            if let i = repo.applications.firstIndex(where: { $0.id == appId }) {
                repo.applications[i].registrationFeePaid = true
                let stuId = repo.applications[i].studentId
                if let si = repo.students.firstIndex(where: { $0.id == stuId }) {
                    repo.students[si].registrationStatus = .registered
                    repo.students[si].schoolId = repo.applications[i].selectedSchoolId
                    repo.students[si].currentGrade = repo.applications[i].selectedGrade
                }
                // Update / create payment record
                let amount = repo.applications[i].registrationFeeAmount
                if let pri = repo.paymentRecords.firstIndex(where: {
                    $0.studentId == stuId && $0.paymentType == .registration
                }) {
                    repo.paymentRecords[pri].totalPaid += amount
                    repo.paymentRecords[pri].outstandingBalance = max(0, repo.paymentRecords[pri].outstandingBalance - amount)
                    repo.paymentRecords[pri].lastPaymentDate = Date()
                } else {
                    repo.paymentRecords.append(PaymentRecord(
                        studentId: stuId, paymentType: .registration,
                        totalDue: amount, totalPaid: amount,
                        outstandingBalance: 0,
                        lastPaymentDate: Date(),
                        nextInstallmentDate: nil, installmentsCount: 1))
                }
            }
        case .tuitionFull(let sid, let amt):
            applyTuitionPayment(studentId: sid, amount: amt, generateSchedule: false)
        case .tuitionInstallment(let sid, let amt):
            applyTuitionPayment(studentId: sid, amount: amt, generateSchedule: true)
        }
    }

    private func applyTuitionPayment(studentId: String, amount: Double,
                                     generateSchedule: Bool) {
        guard let pri = repo.paymentRecords.firstIndex(where: {
            $0.studentId == studentId && $0.paymentType == .tuition
        }) else { return }
        repo.paymentRecords[pri].totalPaid += amount
        repo.paymentRecords[pri].outstandingBalance =
            max(0, repo.paymentRecords[pri].outstandingBalance - amount)
        repo.paymentRecords[pri].lastPaymentDate = Date()
        repo.paymentRecords[pri].installmentsCount += 1

        // SR8.4 — first installment-plan payment generates the schedule for the
        // remaining balance across up to 4 monthly dates.
        if generateSchedule && repo.paymentRecords[pri].schedule.isEmpty {
            let remaining = repo.paymentRecords[pri].outstandingBalance
            let dates = (1...4).compactMap {
                Calendar.current.date(byAdding: .month, value: $0, to: Date())
            }
            let per = (remaining / Double(dates.count) * 100).rounded() / 100
            repo.paymentRecords[pri].schedule = dates.enumerated().map { i, d in
                ScheduledInstallment(id: "INS-\(studentId)-\(i+1)-\(Int.random(in: 100...999))",
                                     dueDate: d, amount: per, paid: false)
            }
        } else if generateSchedule {
            // Mark the next unpaid scheduled installment as paid
            if let next = repo.paymentRecords[pri].schedule.firstIndex(where: { !$0.paid }) {
                repo.paymentRecords[pri].schedule[next].paid = true
            }
        }
        repo.paymentRecords[pri].nextInstallmentDate =
            repo.paymentRecords[pri].schedule.first(where: { !$0.paid })?.dueDate
    }

    private func applyDeclined(reason: String) {
        if let idx = repo.payments.firstIndex(where: { $0.referenceNo == reference }) {
            repo.payments[idx].status = .declined
            repo.payments[idx].failureReason = reason
        }
    }
}
