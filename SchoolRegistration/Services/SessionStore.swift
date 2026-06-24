import Foundation
import Combine

enum AuthenticatedUser {
    case parent(account: ParentAccount, parent: Parent)
    case administrator(SchoolAdministrator)
    case finance(FinanceStaff)
}

final class SessionStore: ObservableObject {
    @Published var current: AuthenticatedUser? = nil
    @Published var selectedChildId: String? = nil   // SR7.2
    @Published var lastLoginError: String? = nil
    @Published var locked: Bool = false

    var role: UserRole? {
        switch current {
        case .parent: return .parent
        case .administrator: return .administrator
        case .finance: return .finance
        case .none: return nil
        }
    }

    var displayName: String {
        switch current {
        case .parent(_, let parent): return parent.fullName
        case .administrator(let a): return a.fullName
        case .finance(let f): return f.fullName
        case .none: return ""
        }
    }

    func logout() {
        current = nil
        selectedChildId = nil
        lastLoginError = nil
        locked = false
    }

    /// Returns true if login succeeded.
    @discardableResult
    func attemptLogin(username: String, password: String, repo: DataRepository) -> Bool {
        lastLoginError = nil

        // Parent
        if var account = repo.parentAccounts.first(where: { $0.username == username }),
           let parent = repo.parent(by: account.parentId) {
            if account.status == "suspended" {
                lastLoginError = "account_suspended"
                locked = true
                return false
            }
            if account.status == "pendingActivation" {
                lastLoginError = "pending_activation"
                return false
            }
            if account.passwordHash == password {
                account.failedLoginAttempts = 0
                if let idx = repo.parentAccounts.firstIndex(where: { $0.id == account.id }) {
                    repo.parentAccounts[idx] = account
                }
                current = .parent(account: account, parent: parent)
                return true
            } else {
                account.failedLoginAttempts += 1
                if account.failedLoginAttempts >= 5 {
                    account.status = "suspended"
                    locked = true
                }
                if let idx = repo.parentAccounts.firstIndex(where: { $0.id == account.id }) {
                    repo.parentAccounts[idx] = account
                }
                lastLoginError = "invalid_credentials"
                return false
            }
        }
        // Admin
        if let admin = repo.administrators.first(where: { $0.username == username && $0.passwordHash == password }) {
            current = .administrator(admin)
            return true
        }
        // Finance
        if let f = repo.financeStaff.first(where: { $0.username == username && $0.passwordHash == password }) {
            current = .finance(f)
            return true
        }
        lastLoginError = "invalid_credentials"
        return false
    }
}
