import Foundation

// MARK: - National Identity Verification Service (SR1.2)
// External actor (Phase 3): confirms whether a submitted national ID exists.
// In a real system it returns the registered holder's name; in this demo we
// derive a stable mock name from the ID so the parent does NOT have to type
// their name during signup (SR1.1 only collects ID + mobile).
struct NationalIdentityVerification {
    var exists: Bool
    var registeredName: String
}

enum NationalIdentityVerificationService {
    static func verify(nationalId: String) -> NationalIdentityVerification {
        let trimmed = nationalId.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 9, Int(trimmed) != nil, trimmed.first != "0" else {
            return NationalIdentityVerification(exists: false, registeredName: "")
        }
        return NationalIdentityVerification(exists: true,
                                            registeredName: mockName(for: trimmed))
    }

    /// Deterministic mock — same ID always returns the same name in this demo build.
    private static func mockName(for id: String) -> String {
        let firstNames = ["Ahmad", "Hassan", "Omar", "Khaled", "Yousef", "Mohammad",
                          "Ibrahim", "Mahmoud", "Adel", "Rami", "Sami", "Karim",
                          "Fatima", "Layla", "Noor", "Sara", "Hala", "Rana"]
        let familyNames = ["Mansour", "Haddad", "Khoury", "Saleh", "Odeh", "Nassar",
                           "Hijazi", "Barakat", "Awad", "Salameh", "Qasem", "Zahran"]
        let digits = id.compactMap { $0.wholeNumberValue }
        let f = firstNames[(digits.first ?? 0) % firstNames.count]
        let l = familyNames[(digits.last  ?? 0) % familyNames.count]
        return "\(f) \(l)"
    }
}

// MARK: - SMS Gateway (SR1.4, SR1.7, SR1.8, SR2.6)
final class SMSGateway {
    /// Demo switch — when on, the next `deliverCredentials` call returns failure.
    /// Used to demonstrate the SR1.8 "SMS delivery failed" error path.
    static var simulateDeliveryFailure = false

    @discardableResult
    static func sendVerificationCode(to mobile: String) -> String {
        return "1234"
    }

    /// SR1.7 — request delivery of credentials via SMS.
    /// SR1.8 — return failure when delivery cannot complete so the caller can
    /// keep the account in `pendingActivation` and surface a clear reason.
    static func deliverCredentials(username: String, tempPassword: String, to mobile: String) -> Bool {
        if simulateDeliveryFailure {
            simulateDeliveryFailure = false
            return false
        }
        return true
    }
}

// MARK: - eSadad Bank Service (SR5.3, SR5.4, SR8.7, SR8.8)
// The user explicitly asked: we generate a reference number and ask the
// parent to use it inside eSadad. The bank's confirmation is simulated by
// the user pressing "I've paid" (success) or "Decline" (failure).
enum ESadadResult {
    case approved(receiptRef: String)
    case declined(reason: String)
    case unavailable
}

enum ESadadBankService {
    /// Generates a unique eSadad reference for a payment request.
    static func generateReference(type: PaymentType) -> String {
        let prefix = type == .registration ? "ESD-REG-" : "ESD-TUI-"
        let suffix = String(Int.random(in: 100000...999999))
        return prefix + suffix
    }

    /// Simulates the parent completing payment in the eSadad app using the reference.
    static func confirmPayment(reference: String) -> ESadadResult {
        // In demo we always approve; UI exposes a "decline" simulator too.
        let receipt = "RCP-" + String(Int.random(in: 10000...99999))
        return .approved(receiptRef: receipt)
    }
}

// MARK: - Credential generator
enum CredentialGenerator {
    static func generateUsername(from fullName: String) -> String {
        let parts = fullName.lowercased().split(separator: " ")
        let base = parts.first.map(String.init) ?? "user"
        let cleaned = base.unicodeScalars.filter { CharacterSet.lowercaseLetters.contains($0) }
        let baseAscii = String(String.UnicodeScalarView(cleaned))
        let suffix = String(Int.random(in: 1000...9999))
        return (baseAscii.isEmpty ? "user" : baseAscii) + suffix
    }

    static func generateTemporaryPassword() -> String {
        let letters = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz"
        let digits = "23456789"
        let all = letters + digits
        return String((0..<8).map { _ in all.randomElement()! })
    }
}
