import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Codable {
    case ar, en
    var displayName: String { self == .ar ? "العربية" : "English" }
    var isRTL: Bool { self == .ar }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app.lang") }
    }

    var layoutDirection: LayoutDirection {
        language.isRTL ? .rightToLeft : .leftToRight
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app.lang") ?? "ar"
        self.language = AppLanguage(rawValue: saved) ?? .ar
    }

    func toggle() {
        language = language == .ar ? .en : .ar
    }

    func t(_ key: LocalizedKey) -> String {
        key.value(for: language)
    }
}

struct L {
    static func t(_ key: LocalizedKey) -> String {
        LocalizationManager.shared.t(key)
    }
}

enum LocalizedKey {
    case appName, login, signUp, logout, language
    case nationalId, mobile, sendCode, verifyCode, otpHint
    case username, password, generatedUsername, tempPassword
    case parent, admin, finance, role
    case parentDashboard, adminDashboard, financeDashboard
    case myChildren, myApplications, payments, academic, schedule, calendar, grades
    case submitApplication, newApplication, child, school, grade, academicYear
    case childFullName, childDOB, childGender, male, female, supportingInfo
    case submit, cancel, confirm, save, back, next, done, view, pay
    case pending, accepted, rejected, paid, unpaid, registered
    case status, decisionDate, rejectionReason, applicationRef, submittedAt
    case payRegistrationFee, payTuition, amount, reference, paymentInstructions
    case esadadFlowTitle, esadadFlowBody, copyReference, paymentReferenceCopied
    case markAsPaid, simulatePaid, simulateDeclined, paymentDeclined, paymentSuccess
    case fullPayment, installmentPlan, firstPayment, remainingBalance, nextInstallment
    case discount, totalDue, paymentHistory, viewReceipt, receipt
    case selectChild, noChildren, noApplications, noPayments
    case decision, accept, reject, rejectReasonPlaceholder, mustProvideReason
    case studentSearch, searchPlaceholder, paidAmount, outstandingBalance
    case applicationsForReview, applicationDetails, financialRecord
    case forgotPassword, recoverCredentials, recovered
    case errorIdNotVerified, errorAccountExists, errorBadOtp, errorLogin, errorRequiredFields
    case successAccountCreated, sendingOtp, otpSentTo
    case classScheduleTitle, academicCalendarTitle, gradesTitle, subject, gradeMark, day, time, event, date
    case viewDetails, schoolName, availableSeats, openSchools
    case demoCredentials, parentDemo, adminDemo, financeDemo
    case welcome, welcomeSubtitle, getStarted
    case english, arabic
    case allApplications, mineOnly, schoolFilter
    case studentId, regStatus, transactions
    case credentialDeliveredViaSMS, weSentCredentials
    case appliedTo, gradeLabel
    case appHeadline
    case applicationStatusTitle
    case parentLoginInstr, adminLoginInstr, financeLoginInstr
    case makePayment, switchChild, switchBetweenChildren
    case reviewApplication, viewPaymentRecords, paymentRecords
    case verifyNationalIdStep, nationalRecordsDatabase
    case verifyingId, idVerified, choosePaymentType
    case registrationFeeUC, tuitionFeeUC, multiChildDiscountApplied

    func value(for lang: AppLanguage) -> String {
        lang == .ar ? Self.ar[self]! : Self.en[self]!
    }

    private static let ar: [LocalizedKey: String] = [
        .appName: "نظام تسجيل مدرسة بيرزيت",
        .login: "تسجيل الدخول",
        .signUp: "إنشاء حساب",
        .logout: "تسجيل الخروج",
        .language: "اللغة",
        .nationalId: "رقم الهوية الوطنية",
        .mobile: "رقم الجوال",
        .sendCode: "إرسال رمز التحقق",
        .verifyCode: "تأكيد الرمز",
        .otpHint: "أدخل الرمز المرسل عبر الرسائل القصيرة (للتجربة: 1234)",
        .username: "اسم المستخدم",
        .password: "كلمة المرور",
        .generatedUsername: "اسم المستخدم المُولّد",
        .tempPassword: "كلمة المرور المؤقتة",
        .parent: "وليّ الأمر",
        .admin: "مدير المدرسة",
        .finance: "موظف الشؤون المالية",
        .role: "الدور",
        .parentDashboard: "لوحة وليّ الأمر",
        .adminDashboard: "لوحة مدير المدرسة",
        .financeDashboard: "لوحة المالية",
        .myChildren: "أبنائي",
        .myApplications: "طلباتي",
        .payments: "المدفوعات",
        .academic: "المعلومات الأكاديمية",
        .schedule: "الجدول الدراسي",
        .calendar: "التقويم الأكاديمي",
        .grades: "العلامات",
        .submitApplication: "تقديم طلب تسجيل",
        .newApplication: "طلب جديد",
        .child: "الطفل",
        .school: "المدرسة",
        .grade: "الصف",
        .academicYear: "السنة الدراسية",
        .childFullName: "اسم الطفل الكامل",
        .childDOB: "تاريخ الميلاد",
        .childGender: "الجنس",
        .male: "ذكر",
        .female: "أنثى",
        .supportingInfo: "ملاحظات داعمة (اختياري)",
        .submit: "إرسال",
        .cancel: "إلغاء",
        .confirm: "تأكيد",
        .save: "حفظ",
        .back: "رجوع",
        .next: "التالي",
        .done: "تم",
        .view: "عرض",
        .pay: "ادفع",
        .pending: "قيد المراجعة",
        .accepted: "مقبول",
        .rejected: "مرفوض",
        .paid: "مدفوع",
        .unpaid: "غير مدفوع",
        .registered: "مسجَّل",
        .status: "الحالة",
        .decisionDate: "تاريخ القرار",
        .rejectionReason: "سبب الرفض",
        .applicationRef: "مرجع الطلب",
        .submittedAt: "تاريخ التقديم",
        .payRegistrationFee: "دفع رسوم التسجيل",
        .payTuition: "دفع الرسوم الدراسية",
        .amount: "المبلغ",
        .reference: "الرقم المرجعي",
        .paymentInstructions: "تعليمات الدفع",
        .esadadFlowTitle: "إكمال الدفع عبر eSadad",
        .esadadFlowBody: "افتح تطبيق eSadad وأدخل الرقم المرجعي أدناه للاستعلام عن الفاتورة وإتمام الدفع. سيتم تحديث الحالة تلقائيًا بعد تأكيد البنك.",
        .copyReference: "نسخ الرقم المرجعي",
        .paymentReferenceCopied: "تم نسخ الرقم المرجعي",
        .markAsPaid: "تمت عملية الدفع",
        .simulatePaid: "محاكاة: نجاح الدفع",
        .simulateDeclined: "محاكاة: رفض الدفع",
        .paymentDeclined: "تم رفض الدفع من eSadad",
        .paymentSuccess: "تمت عملية الدفع بنجاح",
        .fullPayment: "دفع كامل",
        .installmentPlan: "خطة أقساط",
        .firstPayment: "الدفعة الأولى (≥ 50%)",
        .remainingBalance: "الرصيد المتبقي",
        .nextInstallment: "القسط القادم",
        .discount: "الخصم",
        .totalDue: "الإجمالي المستحق",
        .paymentHistory: "سجل المدفوعات",
        .viewReceipt: "عرض الإيصال",
        .receipt: "إيصال الدفع",
        .selectChild: "اختر طفلًا",
        .noChildren: "لا يوجد أبناء مسجَّلون بعد",
        .noApplications: "لا توجد طلبات",
        .noPayments: "لا توجد مدفوعات",
        .decision: "القرار",
        .accept: "قبول",
        .reject: "رفض",
        .rejectReasonPlaceholder: "اكتب سبب الرفض...",
        .mustProvideReason: "يجب كتابة سبب الرفض",
        .studentSearch: "بحث عن طالب",
        .searchPlaceholder: "اكتب اسم الطالب أو الرقم...",
        .paidAmount: "المبلغ المدفوع",
        .outstandingBalance: "الرصيد المستحق",
        .applicationsForReview: "الطلبات للمراجعة",
        .applicationDetails: "تفاصيل الطلب",
        .financialRecord: "السجل المالي",
        .forgotPassword: "هل نسيت كلمة المرور؟",
        .recoverCredentials: "استعادة بيانات الدخول عبر SMS",
        .recovered: "تم إرسال بيانات الدخول عبر الرسائل القصيرة",
        .errorIdNotVerified: "تعذر التحقق من رقم الهوية",
        .errorAccountExists: "يوجد حساب فعّال لهذا الرقم بالفعل",
        .errorBadOtp: "الرمز غير صحيح",
        .errorLogin: "بيانات الدخول غير صحيحة",
        .errorRequiredFields: "يرجى تعبئة جميع الحقول المطلوبة",
        .successAccountCreated: "تم إنشاء الحساب بنجاح",
        .sendingOtp: "جارٍ إرسال الرمز...",
        .otpSentTo: "تم إرسال الرمز إلى",
        .classScheduleTitle: "الجدول الأسبوعي",
        .academicCalendarTitle: "أحداث السنة الدراسية",
        .gradesTitle: "علامات المواد",
        .subject: "المادة",
        .gradeMark: "الدرجة",
        .day: "اليوم",
        .time: "الوقت",
        .event: "الحدث",
        .date: "التاريخ",
        .viewDetails: "عرض التفاصيل",
        .schoolName: "اسم المدرسة",
        .availableSeats: "المقاعد المتاحة",
        .openSchools: "المدارس التي تستقبل طلبات",
        .demoCredentials: "بيانات تجريبية",
        .parentDemo: "وليّ أمر تجريبي: parent1 / pass",
        .adminDemo: "مدير تجريبي: admin1 / pass",
        .financeDemo: "مالية تجريبي: finance1 / pass",
        .welcome: "مرحبًا بك",
        .welcomeSubtitle: "بوابة تسجيل المدارس الموحدة",
        .getStarted: "ابدأ الآن",
        .english: "English",
        .arabic: "العربية",
        .allApplications: "كل الطلبات",
        .mineOnly: "مدرستي فقط",
        .schoolFilter: "تصفية بالمدرسة",
        .studentId: "رقم الطالب",
        .regStatus: "حالة التسجيل",
        .transactions: "العمليات",
        .credentialDeliveredViaSMS: "تم تسليم بيانات الدخول عبر SMS",
        .weSentCredentials: "أرسلنا اسم المستخدم وكلمة المرور المؤقتة إلى رقم جوالك.",
        .appliedTo: "تقديم إلى",
        .gradeLabel: "الصف",
        .appHeadline: "تسجيل أبنائك في المدرسة بخطوات بسيطة",
        .applicationStatusTitle: "حالة الطلبات",
        .parentLoginInstr: "للوصول كولي أمر، أنشئ حسابًا جديدًا أو استخدم البيانات التجريبية.",
        .adminLoginInstr: "للوصول كمدير مدرسة، استخدم البيانات التجريبية.",
        .financeLoginInstr: "للوصول كموظف مالي، استخدم البيانات التجريبية.",
        .makePayment: "إجراء دفعة",
        .switchChild: "تبديل الطفل",
        .switchBetweenChildren: "التبديل بين الأبناء",
        .reviewApplication: "مراجعة طلب التسجيل",
        .viewPaymentRecords: "عرض سجلات الدفع",
        .paymentRecords: "سجلات الدفع",
        .verifyNationalIdStep: "التحقق من رقم الهوية",
        .nationalRecordsDatabase: "قاعدة بيانات السجلات الوطنية",
        .verifyingId: "جارٍ التحقق من الهوية...",
        .idVerified: "تم التحقق من الهوية بنجاح",
        .choosePaymentType: "اختر نوع الدفعة",
        .registrationFeeUC: "رسوم تسجيل",
        .tuitionFeeUC: "رسوم دراسية",
        .multiChildDiscountApplied: "خصم تعدد الأبناء مُطبَّق",
    ]

    private static let en: [LocalizedKey: String] = [
        .appName: "Birzeit School Registration",
        .login: "Sign In",
        .signUp: "Create Account",
        .logout: "Sign Out",
        .language: "Language",
        .nationalId: "National ID",
        .mobile: "Mobile Number",
        .sendCode: "Send Verification Code",
        .verifyCode: "Verify Code",
        .otpHint: "Enter the SMS code (demo code: 1234)",
        .username: "Username",
        .password: "Password",
        .generatedUsername: "Generated Username",
        .tempPassword: "Temporary Password",
        .parent: "Parent",
        .admin: "School Administrator",
        .finance: "Finance Staff",
        .role: "Role",
        .parentDashboard: "Parent Dashboard",
        .adminDashboard: "Administrator Dashboard",
        .financeDashboard: "Finance Dashboard",
        .myChildren: "My Children",
        .myApplications: "My Applications",
        .payments: "Payments",
        .academic: "Academic Info",
        .schedule: "Class Schedule",
        .calendar: "Academic Calendar",
        .grades: "Grades",
        .submitApplication: "Submit Application",
        .newApplication: "New Application",
        .child: "Child",
        .school: "School",
        .grade: "Grade",
        .academicYear: "Academic Year",
        .childFullName: "Child Full Name",
        .childDOB: "Date of Birth",
        .childGender: "Gender",
        .male: "Male",
        .female: "Female",
        .supportingInfo: "Supporting notes (optional)",
        .submit: "Submit",
        .cancel: "Cancel",
        .confirm: "Confirm",
        .save: "Save",
        .back: "Back",
        .next: "Next",
        .done: "Done",
        .view: "View",
        .pay: "Pay",
        .pending: "Pending",
        .accepted: "Accepted",
        .rejected: "Rejected",
        .paid: "Paid",
        .unpaid: "Unpaid",
        .registered: "Registered",
        .status: "Status",
        .decisionDate: "Decision Date",
        .rejectionReason: "Rejection Reason",
        .applicationRef: "Application Ref.",
        .submittedAt: "Submitted At",
        .payRegistrationFee: "Pay Registration Fee",
        .payTuition: "Pay Tuition Fee",
        .amount: "Amount",
        .reference: "Reference Number",
        .paymentInstructions: "Payment Instructions",
        .esadadFlowTitle: "Complete Payment via eSadad",
        .esadadFlowBody: "Open the eSadad app and enter the reference number below to inquire about the bill and complete the payment. Status will update automatically once the bank confirms.",
        .copyReference: "Copy Reference",
        .paymentReferenceCopied: "Reference copied",
        .markAsPaid: "I've Paid via eSadad",
        .simulatePaid: "Simulate: Payment Success",
        .simulateDeclined: "Simulate: Payment Declined",
        .paymentDeclined: "Payment was declined by eSadad",
        .paymentSuccess: "Payment completed successfully",
        .fullPayment: "Full Payment",
        .installmentPlan: "Installment Plan",
        .firstPayment: "First Payment (≥ 50%)",
        .remainingBalance: "Remaining Balance",
        .nextInstallment: "Next Installment",
        .discount: "Discount",
        .totalDue: "Total Due",
        .paymentHistory: "Payment History",
        .viewReceipt: "View Receipt",
        .receipt: "Payment Receipt",
        .selectChild: "Select a child",
        .noChildren: "No registered children yet",
        .noApplications: "No applications yet",
        .noPayments: "No payments yet",
        .decision: "Decision",
        .accept: "Accept",
        .reject: "Reject",
        .rejectReasonPlaceholder: "Write rejection reason...",
        .mustProvideReason: "Rejection reason is required",
        .studentSearch: "Find Student",
        .searchPlaceholder: "Search by name or ID...",
        .paidAmount: "Paid Amount",
        .outstandingBalance: "Outstanding Balance",
        .applicationsForReview: "Applications for Review",
        .applicationDetails: "Application Details",
        .financialRecord: "Financial Record",
        .forgotPassword: "Forgot password?",
        .recoverCredentials: "Recover credentials via SMS",
        .recovered: "Credentials sent via SMS",
        .errorIdNotVerified: "National ID could not be verified",
        .errorAccountExists: "An active account already exists for this ID",
        .errorBadOtp: "Incorrect verification code",
        .errorLogin: "Invalid credentials",
        .errorRequiredFields: "Please fill all required fields",
        .successAccountCreated: "Account created successfully",
        .sendingOtp: "Sending code...",
        .otpSentTo: "Code sent to",
        .classScheduleTitle: "Weekly Schedule",
        .academicCalendarTitle: "School Year Events",
        .gradesTitle: "Subject Grades",
        .subject: "Subject",
        .gradeMark: "Grade",
        .day: "Day",
        .time: "Time",
        .event: "Event",
        .date: "Date",
        .viewDetails: "View Details",
        .schoolName: "School Name",
        .availableSeats: "Available Seats",
        .openSchools: "Schools Accepting Applications",
        .demoCredentials: "Demo Credentials",
        .parentDemo: "Demo parent: parent1 / pass",
        .adminDemo: "Demo admin: admin1 / pass",
        .financeDemo: "Demo finance: finance1 / pass",
        .welcome: "Welcome",
        .welcomeSubtitle: "The unified school registration portal",
        .getStarted: "Get Started",
        .english: "English",
        .arabic: "العربية",
        .allApplications: "All Applications",
        .mineOnly: "My School Only",
        .schoolFilter: "Filter by School",
        .studentId: "Student ID",
        .regStatus: "Registration Status",
        .transactions: "Transactions",
        .credentialDeliveredViaSMS: "Credentials delivered via SMS",
        .weSentCredentials: "We sent your username and temporary password to your mobile.",
        .appliedTo: "Applied to",
        .gradeLabel: "Grade",
        .appHeadline: "Register your children with simple, clear steps",
        .applicationStatusTitle: "Application Status",
        .parentLoginInstr: "Sign in as a parent or create a new account.",
        .adminLoginInstr: "Sign in using administrator credentials.",
        .financeLoginInstr: "Sign in using finance credentials.",
        .makePayment: "Make Payment",
        .switchChild: "Switch Child",
        .switchBetweenChildren: "Switch Between Children",
        .reviewApplication: "Review Registration Application",
        .viewPaymentRecords: "View Payment Records",
        .paymentRecords: "Payment Records",
        .verifyNationalIdStep: "Verify National ID",
        .nationalRecordsDatabase: "National Records Database",
        .verifyingId: "Verifying your national ID...",
        .idVerified: "National ID verified",
        .choosePaymentType: "Choose payment type",
        .registrationFeeUC: "Registration Fee",
        .tuitionFeeUC: "Tuition Fee",
        .multiChildDiscountApplied: "Multi-Child Discount applied",
    ]
}
