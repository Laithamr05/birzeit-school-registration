import SwiftUI

/// Unified "Make Payment" use case (per the use-case diagram).
/// Lists every payable item for the parent — outstanding registration fees
/// for accepted applications, and tuition balances for registered children —
/// and routes the choice into the eSadad payment flow.
struct MakePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    @State private var registrationIntent: PaymentIntent? = nil
    @State private var tuitionTarget: Student? = nil

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
    private var payableApplications: [RegistrationApplication] {
        guard let a = account else { return [] }
        return repo.applicationsOf(parentAccountId: a.id)
            .filter { $0.status == .accepted && !$0.registrationFeePaid }
    }
    private var tuitionDue: [(student: Student, record: PaymentRecord)] {
        children
            .filter { $0.registrationStatus == .registered }
            .compactMap { c in
                if let r = repo.record(for: c.id, type: .tuition), r.outstandingBalance > 0 {
                    return (c, r)
                }
                return nil
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L.t(.choosePaymentType))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)

                    // Registration fees
                    SectionHeader(title: L.t(.registrationFeeUC), icon: "doc.text.fill")
                    if payableApplications.isEmpty {
                        EmptyStateView(icon: "checkmark.circle",
                                       message: loc.language == .ar
                                       ? "لا توجد رسوم تسجيل مستحقة"
                                       : "No registration fees due")
                            .card()
                    } else {
                        ForEach(payableApplications) { app in
                            payableRow(
                                icon: "doc.text.fill",
                                title: app.studentSnapshot.fullName,
                                subtitle: repo.school(by: app.selectedSchoolId)?.schoolName ?? "—",
                                amount: app.registrationFeeAmount,
                                discount: nil
                            ) {
                                registrationIntent = .registration(applicationId: app.id)
                            }
                        }
                    }

                    // Tuition balances — show multi-child discount as an explicit step
                    SectionHeader(title: L.t(.tuitionFeeUC), icon: "graduationcap.fill")
                    if tuitionDue.isEmpty {
                        EmptyStateView(icon: "checkmark.circle",
                                       message: loc.language == .ar
                                       ? "لا توجد رسوم دراسية مستحقة"
                                       : "No tuition balances due")
                            .card()
                    } else {
                        ForEach(tuitionDue, id: \.student.id) { item in
                            payableRow(
                                icon: "graduationcap.fill",
                                title: item.student.fullName,
                                subtitle: repo.school(by: item.student.schoolId ?? "")?.schoolName ?? "—",
                                amount: item.record.outstandingBalance,
                                discount: multiChildDiscountPercent()
                            ) {
                                tuitionTarget = item.student
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
        .sheet(item: Binding(
            get: { registrationIntent.map { IntentBox(intent: $0) } },
            set: { registrationIntent = $0?.intent }
        )) { box in
            ESadadPaymentView(intent: box.intent)
                .environmentObject(loc).environmentObject(repo)
        }
        .sheet(item: $tuitionTarget) { stu in
            TuitionPlanView(child: stu)
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
            Text(L.t(.makePayment)).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private func multiChildDiscountPercent() -> Double? {
        let registered = children.filter { $0.registrationStatus == .registered }.count
        guard registered > 1 else { return nil }
        return min(0.10, Double(registered - 1) * 0.05)
    }

    @ViewBuilder
    private func payableRow(icon: String, title: String, subtitle: String,
                            amount: Double, discount: Double?,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.primaryGradient).frame(width: 40, height: 40)
                        Image(systemName: icon).foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text(subtitle).font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(amount.money())
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.primary)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                    }
                }
                if let d = discount, d > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10)).foregroundColor(Theme.success)
                        Text("«\(L.t(.multiChildDiscountApplied))» −\(Int(d*100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.success)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.success.opacity(0.10))
                    .cornerRadius(8)
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(Theme.radius)
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
        }
    }
}

private struct IntentBox: Identifiable {
    let intent: PaymentIntent
    /// Stable id derived from the payment intent itself. The previous version
    /// used `UUID()`, which created a fresh identity on every re-render of the
    /// parent view, causing SwiftUI to dismiss and re-present the sheet (the
    /// "payment loops" behaviour).
    var id: String {
        switch intent {
        case .registration(let appId):      return "reg-" + appId
        case .tuitionFull(let sid, let a):  return "tui-full-\(sid)-\(a)"
        case .tuitionInstallment(let sid, let a): return "tui-ins-\(sid)-\(a)"
        }
    }
}
