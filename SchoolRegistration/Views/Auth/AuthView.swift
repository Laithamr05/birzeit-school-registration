import SwiftUI

struct AuthView: View {
    var startInSignup: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository

    enum Mode { case login, signup }
    @State private var mode: Mode = .login

    // Login fields
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false

    // Recovery flow
    @State private var showRecovery = false

    // Signup state
    // 0: collect, 1: otp, 2: success, 3: SMS delivery failed (SR1.8)
    @State private var signupStep: Int = 0
    @State private var nationalId = ""
    @State private var mobile = ""
    @State private var otp = ""
    @State private var signupError: String? = nil
    @State private var generatedUsername = ""
    @State private var generatedPassword = ""
    @State private var sentOtp = ""
    @State private var verifiedName = ""
    @State private var simulateSmsFailure = false
    @State private var pendingAccountId: String? = nil

    init(startInSignup: Bool = false) {
        self.startInSignup = startInSignup
        _mode = State(initialValue: startInSignup ? .signup : .login)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 18) {
                        if mode == .login {
                            loginCard
                        } else {
                            signupCard
                        }
                    }
                    .padding(18)
                }
            }
        }
        .environment(\.layoutDirection, loc.layoutDirection)
        .sheet(isPresented: $showRecovery) {
            CredentialRecoveryView()
                .environmentObject(loc)
                .environmentObject(repo)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: loc.language == .ar ? "chevron.forward" : "chevron.backward")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            Text(mode == .login ? L.t(.login) : L.t(.signUp))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    // MARK: - Login

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: L.t(.login), icon: "person.crop.circle.badge.checkmark")
            Text(loc.language == .ar
                 ? "أدخل بيانات الدخول وسيتم تحديد نوع الحساب تلقائيًا."
                 : "Enter your credentials — your account type is detected automatically.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            AppTextField(label: L.t(.username), text: $username,
                         placeholder: "username", icon: "person.fill")
            AppTextField(label: L.t(.password), text: $password,
                         placeholder: "••••••••", icon: "lock.fill",
                         isSecure: true)
            if showError, let err = session.lastLoginError {
                let msg: String = {
                    switch err {
                    case "account_suspended":
                        return loc.language == .ar
                            ? "تم تعليق الحساب بعد محاولات فاشلة متكررة." : "Account suspended after repeated failures."
                    case "pending_activation":
                        return loc.language == .ar
                            ? "الحساب بانتظار التفعيل — لم يتم تسليم بيانات الدخول عبر SMS بعد."
                            : "Account pending activation — credentials SMS not delivered yet."
                    default:
                        return L.t(.errorLogin)
                    }
                }()
                Text(msg)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.danger)
            }

            Button { tryLogin() } label: {
                Text(L.t(.login))
            }.buttonStyle(PrimaryButtonStyle(icon: "arrow.right.circle.fill"))

            HStack {
                Button { showRecovery = true } label: {
                    Text(L.t(.forgotPassword))
                }
                .buttonStyle(GhostButtonStyle())
                Spacer()
                Button { withAnimation { mode = .signup; signupStep = 0 } } label: {
                    Text(L.t(.signUp))
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .card()
    }

    private func tryLogin() {
        let ok = session.attemptLogin(username: username.trimmingCharacters(in: .whitespaces),
                                       password: password, repo: repo)
        if ok {
            dismiss()
        } else {
            showError = true
        }
    }

    // MARK: - Signup

    private var signupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: L.t(.signUp), icon: "person.crop.circle.badge.plus")
                Spacer()
                Button { withAnimation { mode = .login } } label: {
                    Text(L.t(.login))
                }.buttonStyle(GhostButtonStyle())
            }

            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= signupStep ? Theme.primary : Theme.border)
                        .frame(width: i == signupStep ? 22 : 8, height: 6)
                }
                Spacer()
            }

            Group {
                switch signupStep {
                case 0: signupCollect
                case 1: signupOtp
                case 3: signupDeliveryFailed
                default: signupResult
                }
            }
        }
        .card()
    }

    private var signupCollect: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show the include relationship explicitly — Create Parent Account
            // includes Verify National ID via the National Records Database.
            HStack(spacing: 8) {
                Image(systemName: "rectangle.connected.to.line.below")
                    .foregroundColor(Theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.t(.verifyNationalIdStep))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(loc.language == .ar
                         ? "يتم التحقق عبر «\(L.t(.nationalRecordsDatabase))»"
                         : "Verified via the \(L.t(.nationalRecordsDatabase))")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(10)
            .background(Theme.primary.opacity(0.08))
            .cornerRadius(Theme.smallRadius)

            AppTextField(label: L.t(.nationalId), text: $nationalId,
                         placeholder: "9 digits", icon: "person.text.rectangle.fill",
                         keyboard: .numberPad)
            AppTextField(label: L.t(.mobile), text: $mobile,
                         placeholder: "+970599...", icon: "phone.fill",
                         keyboard: .phonePad)
            if let err = signupError {
                Text(err)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.danger)
            }
            Button { startSignup() } label: {
                Text(loc.language == .ar ? "التحقق وإرسال الرمز" : "Verify ID & Send Code")
            }.buttonStyle(PrimaryButtonStyle(icon: "paperplane.fill"))
        }
    }

    private var signupOtp: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Verified holder block — shows the parent the name returned
            // by the National Identity Verification Service.
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22)).foregroundColor(Theme.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.language == .ar ? "تم التحقق من الهوية" : "Identity verified")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text(verifiedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
            }
            .padding(12)
            .background(Theme.success.opacity(0.10))
            .cornerRadius(Theme.smallRadius)

            HStack(spacing: 8) {
                Image(systemName: "message.fill").foregroundColor(Theme.primary)
                Text("\(L.t(.otpSentTo)) \(mobile)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
            Text(L.t(.otpHint))
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            AppTextField(label: L.t(.verifyCode), text: $otp,
                         placeholder: "1234", icon: "lock.shield.fill",
                         keyboard: .numberPad)
            if let err = signupError {
                Text(err).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.danger)
            }
            Button { verifyOtp() } label: { Text(L.t(.verifyCode)) }
                .buttonStyle(PrimaryButtonStyle(icon: "checkmark.shield.fill"))

            Button {
                withAnimation { signupStep = 0 }
            } label: { Text(L.t(.back)) }
                .buttonStyle(GhostButtonStyle())
        }
    }

    private var signupDeliveryFailed: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28)).foregroundColor(Theme.danger)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.language == .ar
                         ? "تعذّر تسليم بيانات الدخول عبر SMS"
                         : "Credentials SMS delivery failed")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.danger)
                    Text(loc.language == .ar
                         ? "تم إنشاء الحساب بحالة «بانتظار التفعيل». لا يمكن استخدامه لتسجيل الدخول حتى تتم إعادة الإرسال بنجاح."
                         : "Your account is created in Pending Activation. It cannot be used to sign in until credentials are re-delivered.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button { retryDelivery() } label: {
                Text(loc.language == .ar ? "إعادة محاولة الإرسال" : "Resend credentials")
            }.buttonStyle(PrimaryButtonStyle(icon: "arrow.clockwise"))
            Button {
                withAnimation { signupStep = 0 }
            } label: { Text(L.t(.back)) }
                .buttonStyle(GhostButtonStyle())
        }
    }

    private var signupResult: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.t(.successAccountCreated))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(L.t(.weSentCredentials))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            credentialBlock(label: L.t(.generatedUsername), value: generatedUsername, icon: "person.fill")
            credentialBlock(label: L.t(.tempPassword), value: generatedPassword, icon: "key.fill")

            Button {
                username = generatedUsername
                password = generatedPassword
                withAnimation { mode = .login }
            } label: { Text(L.t(.login)) }
                .buttonStyle(PrimaryButtonStyle(icon: "arrow.right.circle.fill"))
        }
    }

    private func credentialBlock(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11)).foregroundColor(Theme.textSecondary)
                Text(value).font(.system(size: 17, weight: .bold).monospaced())
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value
            } label: {
                Image(systemName: "doc.on.doc.fill").foregroundColor(Theme.primary)
            }
        }
        .padding(14)
        .background(Theme.surfaceAlt)
        .cornerRadius(Theme.smallRadius)
    }

    private func startSignup() {
        signupError = nil
        guard !nationalId.isEmpty, !mobile.isEmpty else {
            signupError = L.t(.errorRequiredFields); return
        }
        // SR1.3 — block second active account for same ID
        if repo.parents.contains(where: { $0.nationalId == nationalId }) {
            signupError = L.t(.errorAccountExists); return
        }
        // SR1.2 — verify via National Identity Verification Service
        let result = NationalIdentityVerificationService.verify(nationalId: nationalId)
        guard result.exists else {
            signupError = L.t(.errorIdNotVerified); return
        }
        verifiedName = result.registeredName
        // SR1.4 — send OTP via SMS Gateway
        sentOtp = SMSGateway.sendVerificationCode(to: mobile)
        withAnimation { signupStep = 1 }
    }

    private func verifyOtp() {
        signupError = nil
        // SR1.5 — create account only after correct code
        guard otp == sentOtp else {
            signupError = L.t(.errorBadOtp); return
        }
        let newParent = Parent(id: "PAR-\(Int.random(in: 100...999))",
                               fullName: verifiedName, nationalId: nationalId,
                               phoneNumber: mobile, email: nil)
        // SR1.6 — generate unique username + temp password
        let uname = CredentialGenerator.generateUsername(from: verifiedName)
        let pwd = CredentialGenerator.generateTemporaryPassword()
        // SR1.7 — request credential delivery via SMS Gateway
        SMSGateway.simulateDeliveryFailure = simulateSmsFailure
        let delivered = SMSGateway.deliverCredentials(username: uname,
                                                     tempPassword: pwd, to: mobile)
        let status = delivered ? "active" : "pendingActivation"
        let account = ParentAccount(id: "ACC-\(Int.random(in: 100...999))",
                                    parentId: newParent.id,
                                    username: uname, passwordHash: pwd,
                                    status: status, failedLoginAttempts: 0)
        repo.parents.append(newParent)
        repo.parentAccounts.append(account)
        pendingAccountId = account.id
        generatedUsername = uname
        generatedPassword = pwd
        if delivered {
            withAnimation { signupStep = 2 }
        } else {
            // SR1.8 — report SMS delivery failure
            withAnimation { signupStep = 3 }
        }
    }

    private func retryDelivery() {
        // Demo: succeed on retry.
        SMSGateway.simulateDeliveryFailure = false
        let ok = SMSGateway.deliverCredentials(username: generatedUsername,
                                               tempPassword: generatedPassword,
                                               to: mobile)
        if ok, let id = pendingAccountId,
           let idx = repo.parentAccounts.firstIndex(where: { $0.id == id }) {
            repo.parentAccounts[idx].status = "active"
            withAnimation { signupStep = 2 }
        }
    }

    // MARK: - Demo hint
    private var demoHintCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill").foregroundColor(Theme.accent)
                Text(L.t(.demoCredentials))
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(loc.language == .ar ? "اضغط للدخول" : "Tap to sign in")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
            quickLoginRow(label: L.t(.parent), username: "parent1", icon: "person.2.fill")
            quickLoginRow(label: L.t(.admin), username: "admin1", icon: "building.columns.fill")
            quickLoginRow(label: L.t(.finance), username: "finance1", icon: "creditcard.fill")
        }
        .card()
    }

    private func quickLoginRow(label: String, username u: String, icon: String) -> some View {
        Button {
            username = u
            password = "pass"
            tryLogin()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Theme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(u) / pass")
                        .font(.system(size: 11).monospaced())
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(Theme.primary)
            }
            .padding(10)
            .background(Theme.surfaceAlt)
            .cornerRadius(Theme.smallRadius)
        }
    }
}

struct CredentialRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var repo: DataRepository
    @State private var nationalId = ""
    @State private var mobile = ""
    @State private var result: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L.t(.recoverCredentials))
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.2)).clipShape(Circle())
                }
            }
            .padding(18)
            .background(Theme.primaryGradient)

            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(label: L.t(.nationalId), text: $nationalId,
                                 placeholder: "9 digits", icon: "person.text.rectangle.fill",
                                 keyboard: .numberPad)
                    AppTextField(label: L.t(.mobile), text: $mobile,
                                 placeholder: "+970...", icon: "phone.fill",
                                 keyboard: .phonePad)
                    if let result {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                            Text(result).font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.success)
                        }
                    }
                    Button { send() } label: {
                        Text(L.t(.recoverCredentials))
                    }.buttonStyle(PrimaryButtonStyle(icon: "paperplane.fill"))
                }
                .padding(18)
            }
        }
        .environment(\.layoutDirection, loc.layoutDirection)
    }

    private func send() {
        if let parent = repo.parents.first(where: { $0.nationalId == nationalId && $0.phoneNumber == mobile }),
           let account = repo.parentAccounts.first(where: { $0.parentId == parent.id }) {
            _ = SMSGateway.deliverCredentials(username: account.username,
                                              tempPassword: account.passwordHash, to: mobile)
            result = "\(L.t(.recovered)) (\(loc.language == .ar ? "للتجربة" : "demo"): \(account.username) / \(account.passwordHash))"
        } else {
            result = L.t(.errorIdNotVerified)
        }
    }
}
