import Foundation

// MARK: - Enums

enum UserRole: String, Codable, CaseIterable {
    case parent, administrator, finance
}

enum ApplicationStatus: String, Codable {
    case pending, accepted, rejected
}

enum PaymentType: String, Codable {
    case registration, tuition
}

enum PaymentStatus: String, Codable {
    case pending, paid, declined, unconfirmed
}

enum RegistrationStatus: String, Codable {
    case unregistered, pendingPayment, registered
}

enum Gender: String, Codable, CaseIterable {
    case male, female
}

// MARK: - Domain

struct Parent: Identifiable, Codable, Hashable {
    var id: String
    var fullName: String
    var nationalId: String
    var phoneNumber: String
    var email: String?
}

struct ParentAccount: Identifiable, Codable {
    var id: String
    var parentId: String
    var username: String
    var passwordHash: String   // demo only — plain-equal compare
    var status: String         // active, pendingActivation, suspended
    var failedLoginAttempts: Int = 0
}

struct School: Identifiable, Codable, Hashable {
    var id: String
    var schoolName: String
    var acceptingApplications: Bool
    var administratorId: String
    var registrationFee: Double
    var annualTuition: Double
}

struct GradeLevel: Identifiable, Codable, Hashable {
    var id: String { "\(schoolId)-\(gradeName)" }
    var schoolId: String
    var gradeName: String
    var availableSeats: Int
}

struct Student: Identifiable, Codable, Hashable {
    var id: String
    var fullName: String
    var dateOfBirth: Date
    var gender: Gender
    var currentGrade: String?
    var parentId: String
    var schoolId: String?
    var registrationStatus: RegistrationStatus
}

struct RegistrationApplication: Identifiable, Codable {
    var id: String                   // also the applicationRef
    var parentAccountId: String
    var studentId: String            // links to (possibly new) Student
    var studentSnapshot: Student     // captured at submission
    var selectedSchoolId: String
    var selectedGrade: String
    var academicYear: String
    var supportingInfo: String
    var submissionDate: Date
    var status: ApplicationStatus
    var decisionDate: Date?
    var decisionByAdminId: String?
    var rejectionReason: String?
    var registrationFeeAmount: Double
    var registrationFeePaid: Bool = false
}

struct Payment: Identifiable, Codable {
    var id: String
    var applicationId: String?       // for registration fee
    var studentId: String            // for tuition / lookup
    var parentAccountId: String
    var amount: Double
    var paymentType: PaymentType
    var status: PaymentStatus
    var referenceNo: String          // unique eSadad reference
    var createdAt: Date
    var paidAt: Date?
    var failureReason: String?
    var receiptNumber: String?
}

struct ScheduledInstallment: Identifiable, Codable, Hashable {
    var id: String
    var dueDate: Date
    var amount: Double
    var paid: Bool
}

struct PaymentRecord: Identifiable, Codable {
    var id: String { studentId + "-" + paymentType.rawValue }
    var studentId: String
    var paymentType: PaymentType
    var totalDue: Double
    var totalPaid: Double
    var outstandingBalance: Double
    var lastPaymentDate: Date?
    var nextInstallmentDate: Date?
    var installmentsCount: Int = 0
    var schedule: [ScheduledInstallment] = []   // SR8.4 — up to 4 monthly installments
}

struct AcademicRecord: Identifiable, Codable, Hashable {
    var id: String
    var studentId: String
    var subject: String
    var grade: String
    var period: String
}

struct ClassScheduleEntry: Identifiable, Codable, Hashable {
    var id: String
    var studentId: String
    var className: String
    var day: String
    var timeSlot: String
}

struct AcademicCalendarEvent: Identifiable, Codable, Hashable {
    var id: String
    var schoolId: String
    var academicYear: String
    var eventName: String
    var eventDate: Date
}

struct SchoolAdministrator: Identifiable, Codable {
    var id: String
    var fullName: String
    var assignedSchoolId: String
    var username: String
    var passwordHash: String
}

struct FinanceStaff: Identifiable, Codable {
    var id: String
    var fullName: String
    var username: String
    var passwordHash: String
}

struct FinanceAccessLog: Identifiable, Codable {
    var id: String
    var staffId: String
    var studentId: String
    var accessedAt: Date
}

struct ParentNotification: Identifiable, Codable {
    var id: String
    var parentAccountId: String
    var title: String
    var body: String
    var createdAt: Date
    var read: Bool = false
    var relatedApplicationId: String?
}
