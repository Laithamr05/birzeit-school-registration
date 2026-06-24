import SwiftUI

enum Theme {
    static let primary = Color(red: 0.14, green: 0.45, blue: 0.36)        // deep teal-green (Birzeit-inspired)
    static let primaryDark = Color(red: 0.08, green: 0.30, blue: 0.24)
    static let accent = Color(red: 0.94, green: 0.68, blue: 0.20)         // warm gold
    static let danger = Color(red: 0.85, green: 0.30, blue: 0.30)
    static let success = Color(red: 0.28, green: 0.68, blue: 0.45)
    static let warning = Color(red: 0.96, green: 0.78, blue: 0.30)

    static let bg = Color(red: 0.97, green: 0.97, blue: 0.96)
    static let surface = Color.white
    static let surfaceAlt = Color(red: 0.95, green: 0.96, blue: 0.95)
    static let textPrimary = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let textSecondary = Color(red: 0.40, green: 0.44, blue: 0.50)
    static let border = Color(red: 0.88, green: 0.90, blue: 0.88)

    static let radius: CGFloat = 16
    static let smallRadius: CGFloat = 10

    static let primaryGradient = LinearGradient(
        colors: [primaryDark, primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.97, green: 0.80, blue: 0.40)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shared components

struct PrimaryButtonStyle: ButtonStyle {
    var icon: String? = nil
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon) }
            configuration.label
        }
        .font(.system(size: 16, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundColor(.white)
        .background(Theme.primaryGradient)
        .cornerRadius(Theme.radius)
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .shadow(color: Theme.primary.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Theme.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(Theme.primary.opacity(0.10))
            .cornerRadius(Theme.smallRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Theme.textSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .cornerRadius(Theme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = 18) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .cornerRadius(20)
    }
}

extension ApplicationStatus {
    var badgeColor: Color {
        switch self {
        case .pending: return Theme.warning
        case .accepted: return Theme.success
        case .rejected: return Theme.danger
        }
    }
    var localized: String {
        switch self {
        case .pending: return L.t(.pending)
        case .accepted: return L.t(.accepted)
        case .rejected: return L.t(.rejected)
        }
    }
}

extension PaymentStatus {
    var badgeColor: Color {
        switch self {
        case .pending, .unconfirmed: return Theme.warning
        case .paid: return Theme.success
        case .declined: return Theme.danger
        }
    }
    var localized: String {
        switch self {
        case .pending: return L.t(.pending)
        case .paid: return L.t(.paid)
        case .declined: return L.t(.paymentDeclined)
        case .unconfirmed: return L.t(.pending)
        }
    }
}

extension RegistrationStatus {
    var badgeColor: Color {
        switch self {
        case .unregistered: return Theme.textSecondary
        case .pendingPayment: return Theme.warning
        case .registered: return Theme.success
        }
    }
    var localized: String {
        switch self {
        case .unregistered: return L.t(.unpaid)
        case .pendingPayment: return L.t(.pending)
        case .registered: return L.t(.registered)
        }
    }
}
