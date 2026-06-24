import SwiftUI

struct AppHeaderBar: View {
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    var title: String
    var showLogout: Bool = true
    var showNotifications: Bool = false
    @State private var showInbox = false

    private var accountId: String? {
        if case .parent(let a, _) = session.current { return a.id }
        return nil
    }
    private var unread: Int {
        accountId.map { repo.unreadCount(for: $0) } ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                if !session.displayName.isEmpty {
                    Text(session.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            Spacer()
            if showNotifications, accountId != nil {
                Button { showInbox = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                        if unread > 0 {
                            Text("\(unread)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.danger)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -2)
                        }
                    }
                }
            }
            LanguageToggle()
            if showLogout, session.current != nil {
                Button {
                    session.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
        .shadow(color: Theme.primary.opacity(0.25), radius: 12, x: 0, y: 6)
        .sheet(isPresented: $showInbox) {
            if let id = accountId {
                NotificationInboxView(accountId: id)
                    .environmentObject(loc).environmentObject(repo)
            }
        }
    }
}

struct NotificationInboxView: View {
    let accountId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var items: [ParentNotification] {
        repo.notifications(for: accountId)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").foregroundColor(.white)
                        .padding(10).background(Color.white.opacity(0.18)).clipShape(Circle())
                }
                Spacer()
                Text(loc.language == .ar ? "الإشعارات" : "Notifications")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
                LanguageToggle()
            }
            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
            .background(Theme.primaryGradient)
            .clipShape(BottomRoundedShape(radius: 28))

            ScrollView {
                VStack(spacing: 10) {
                    if items.isEmpty {
                        EmptyStateView(icon: "bell.slash",
                                       message: loc.language == .ar
                                       ? "لا توجد إشعارات بعد" : "No notifications yet")
                            .card()
                    } else {
                        ForEach(items) { n in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: n.read ? "envelope.open.fill" : "envelope.badge.fill")
                                    .foregroundColor(n.read ? Theme.textSecondary : Theme.primary)
                                    .font(.system(size: 16))
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(n.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(n.body)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(n.createdAt.short())
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(Theme.surface)
                            .cornerRadius(Theme.radius)
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius)
                                        .stroke(n.read ? Theme.border : Theme.primary.opacity(0.4),
                                                lineWidth: n.read ? 1 : 1.5))
                        }
                    }
                }
                .padding(18)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .environment(\.layoutDirection, loc.layoutDirection)
        .onAppear { repo.markAllRead(for: accountId) }
    }
}

struct BottomRoundedShape: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        path.addQuadCurve(to: CGPoint(x: rect.width - radius, y: rect.height),
                          control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: radius, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - radius),
                          control: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct LanguageToggle: View {
    @EnvironmentObject var loc: LocalizationManager
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                loc.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                Text(loc.language == .ar ? "EN" : "ع")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.18))
            .cornerRadius(20)
        }
    }
}

struct AppTextField: View {
    var label: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var capitalize: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(Theme.primary)
                }
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(capitalize)
                        .autocorrectionDisabled()
                }
            }
            .padding(14)
            .background(Theme.surface)
            .cornerRadius(Theme.smallRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.smallRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
}

struct InfoRow: View {
    var label: String
    var value: String
    var valueColor: Color = Theme.textPrimary
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

struct ChildScopePicker: View {
    let children: [Student]
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { session.selectedChildId = nil } label: {
                    chip(text: loc.language == .ar ? "كل الأبناء" : "All children",
                         active: session.selectedChildId == nil, icon: "person.2.fill")
                }
                ForEach(children) { c in
                    Button { session.selectedChildId = c.id } label: {
                        chip(text: c.fullName,
                             active: session.selectedChildId == c.id,
                             icon: "person.fill")
                    }
                }
            }
        }
    }

    private func chip(text: String, active: Bool, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(active ? Theme.primary : Theme.surfaceAlt)
        .foregroundColor(active ? .white : Theme.textPrimary)
        .cornerRadius(20)
    }
}

struct EmptyStateView: View {
    var icon: String
    var message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Theme.textSecondary.opacity(0.6))
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct SectionHeader: View {
    var title: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
            }
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }
}

struct Toast: View {
    var text: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = Theme.success
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.white)
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color)
        .cornerRadius(28)
        .shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

extension Date {
    func short() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: LocalizationManager.shared.language == .ar ? "ar" : "en")
        return f.string(from: self)
    }
}

extension Double {
    func money() -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "ILS"
        f.currencySymbol = LocalizationManager.shared.language == .ar ? "₪ " : "₪"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: self)) ?? "₪\(self)"
    }
}
