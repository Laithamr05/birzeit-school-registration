import SwiftUI

/// Switch Between Children (UC from the use-case diagram).
/// Lets the parent pick which linked child record is the active context for
/// applications, payments, and academic information (SR7.2 / SR7.3 / SR7.4).
struct SwitchChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }
    private var children: [Student] {
        parent.map { repo.childrenOf(parentId: $0.id) } ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(loc.language == .ar
                         ? "اختر السجل النشط — سيتم تطبيقه على الطلبات، الدفعات، والمعلومات الأكاديمية."
                         : "Pick the active child record — applies to applications, payments, and academic information.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)

                    Button {
                        session.selectedChildId = nil
                        dismiss()
                    } label: {
                        rowView(
                            title: loc.language == .ar ? "كل الأبناء" : "All children",
                            subtitle: loc.language == .ar
                                ? "عرض جميع السجلات المرتبطة"
                                : "Show every linked record",
                            icon: "person.2.fill",
                            selected: session.selectedChildId == nil,
                            badge: nil
                        )
                    }

                    ForEach(children) { c in
                        Button {
                            session.selectedChildId = c.id
                            dismiss()
                        } label: {
                            rowView(
                                title: c.fullName,
                                subtitle: c.schoolId.flatMap { repo.school(by: $0)?.schoolName } ?? "—",
                                icon: "person.fill",
                                selected: session.selectedChildId == c.id,
                                badge: c.registrationStatus.localized,
                                badgeColor: c.registrationStatus.badgeColor
                            )
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
            Text(L.t(.switchBetweenChildren))
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private func rowView(title: String, subtitle: String, icon: String,
                         selected: Bool, badge: String?,
                         badgeColor: Color = Theme.textSecondary) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(selected ? Theme.primaryGradient : Theme.accentGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(.white).font(.system(size: 18, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if let b = badge {
                StatusBadge(text: b, color: badgeColor)
            }
            if selected {
                Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.primary)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(Theme.radius)
        .overlay(RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(selected ? Theme.primary : Theme.border,
                            lineWidth: selected ? 2 : 1))
    }
}
