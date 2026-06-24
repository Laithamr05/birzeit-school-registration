import Foundation
import Combine

final class DataRepository: ObservableObject {
    static let shared = DataRepository()

    @Published var parents: [Parent] = [] { didSet { persist() } }
    @Published var parentAccounts: [ParentAccount] = [] { didSet { persist() } }
    @Published var students: [Student] = [] { didSet { persist() } }
    @Published var schools: [School] = [] { didSet { persist() } }
    @Published var gradeLevels: [GradeLevel] = [] { didSet { persist() } }
    @Published var applications: [RegistrationApplication] = [] { didSet { persist() } }
    @Published var payments: [Payment] = [] { didSet { persist() } }
    @Published var paymentRecords: [PaymentRecord] = [] { didSet { persist() } }
    @Published var academicRecords: [AcademicRecord] = [] { didSet { persist() } }
    @Published var schedules: [ClassScheduleEntry] = [] { didSet { persist() } }
    @Published var calendarEvents: [AcademicCalendarEvent] = [] { didSet { persist() } }
    @Published var administrators: [SchoolAdministrator] = [] { didSet { persist() } }
    @Published var financeStaff: [FinanceStaff] = [] { didSet { persist() } }
    @Published var financeAccessLogs: [FinanceAccessLog] = [] { didSet { persist() } }
    @Published var notifications: [ParentNotification] = [] { didSet { persist() } }

    @Published var pendingOtp: String? = nil
    @Published var pendingRegistration: (nationalId: String, mobile: String, fullName: String)? = nil

    private var loading = false
    private var storageURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("school_registration_state.json")
    }

    private init() {
        if !loadFromDisk() {
            seed()
        }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var parents: [Parent]
        var parentAccounts: [ParentAccount]
        var students: [Student]
        var schools: [School]
        var gradeLevels: [GradeLevel]
        var applications: [RegistrationApplication]
        var payments: [Payment]
        var paymentRecords: [PaymentRecord]
        var academicRecords: [AcademicRecord]
        var schedules: [ClassScheduleEntry]
        var calendarEvents: [AcademicCalendarEvent]
        var administrators: [SchoolAdministrator]
        var financeStaff: [FinanceStaff]
        var financeAccessLogs: [FinanceAccessLog]
        var notifications: [ParentNotification]
        var seedVersion: Int
    }

    // Bump this whenever the seed shape changes so existing devices reseed.
    private static let currentSeedVersion = 4

    private func persist() {
        guard !loading else { return }
        let snap = Snapshot(
            parents: parents, parentAccounts: parentAccounts, students: students,
            schools: schools, gradeLevels: gradeLevels, applications: applications,
            payments: payments, paymentRecords: paymentRecords,
            academicRecords: academicRecords, schedules: schedules,
            calendarEvents: calendarEvents, administrators: administrators,
            financeStaff: financeStaff, financeAccessLogs: financeAccessLogs,
            notifications: notifications,
            seedVersion: Self.currentSeedVersion
        )
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Demo: ignore persistence errors
        }
    }

    @discardableResult
    private func loadFromDisk() -> Bool {
        guard let data = try? Data(contentsOf: storageURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data),
              snap.seedVersion == Self.currentSeedVersion else {
            return false
        }
        loading = true
        parents = snap.parents
        parentAccounts = snap.parentAccounts
        students = snap.students
        schools = snap.schools
        gradeLevels = snap.gradeLevels
        applications = snap.applications
        payments = snap.payments
        paymentRecords = snap.paymentRecords
        academicRecords = snap.academicRecords
        schedules = snap.schedules
        calendarEvents = snap.calendarEvents
        administrators = snap.administrators
        financeStaff = snap.financeStaff
        financeAccessLogs = snap.financeAccessLogs
        notifications = snap.notifications
        loading = false
        return true
    }

    func resetToSeed() {
        try? FileManager.default.removeItem(at: storageURL)
        loading = true
        parents.removeAll(); parentAccounts.removeAll(); students.removeAll()
        schools.removeAll(); gradeLevels.removeAll(); applications.removeAll()
        payments.removeAll(); paymentRecords.removeAll()
        academicRecords.removeAll(); schedules.removeAll(); calendarEvents.removeAll()
        administrators.removeAll(); financeStaff.removeAll(); financeAccessLogs.removeAll()
        notifications.removeAll()
        loading = false
        seed()
        persist()
    }

    // MARK: - Seed data
    private func seed() {
        loading = true
        defer { loading = false; persist() }
        // Single school: Birzeit School
        let s1 = School(id: "SCH-001", schoolName: "Birzeit School",
                        acceptingApplications: true, administratorId: "ADM-001",
                        registrationFee: 200, annualTuition: 3500)
        schools = [s1]

        // Full Birzeit School grade list — KG1, KG2, Grade 1 … Grade 12.
        let seatsByGrade: [(String, Int)] = [
            ("KG1", 24), ("KG2", 22),
            ("Grade 1", 30), ("Grade 2", 28), ("Grade 3", 25),
            ("Grade 4", 22), ("Grade 5", 20), ("Grade 6", 18),
            ("Grade 7", 18), ("Grade 8", 16), ("Grade 9", 16),
            ("Grade 10", 14), ("Grade 11", 12), ("Grade 12", 10),
        ]
        gradeLevels = seatsByGrade.map { name, seats in
            GradeLevel(schoolId: s1.id, gradeName: name, availableSeats: seats)
        }

        // Administrators (Group 6 team — Saleem Daqa, PM)
        administrators = [
            SchoolAdministrator(id: "ADM-001", fullName: "Saleem Daqa",
                                assignedSchoolId: s1.id, username: "admin1", passwordHash: "pass"),
        ]

        // Finance staff (Tala Dana, technical architect)
        financeStaff = [
            FinanceStaff(id: "FIN-001", fullName: "Tala Dana",
                         username: "finance1", passwordHash: "pass"),
        ]

        // Demo parent: Laith Amro (programmer), children named after the team
        let demoParent = Parent(id: "PAR-001", fullName: "Laith Amro",
                                nationalId: "123456789", phoneNumber: "+970599123456",
                                email: "laith@example.com")
        let demoAccount = ParentAccount(id: "ACC-001", parentId: demoParent.id,
                                        username: "parent1", passwordHash: "pass",
                                        status: "active", failedLoginAttempts: 0)
        parents = [demoParent]
        parentAccounts = [demoAccount]

        // Children: Tala Shareef (registered demo), Shahd Shahin (pending demo)
        let stu1 = Student(id: "STU-1001", fullName: "Tala Shareef",
                           dateOfBirth: Calendar.current.date(from: DateComponents(year: 2016, month: 4, day: 12))!,
                           gender: .female, currentGrade: "Grade 3",
                           parentId: demoParent.id, schoolId: s1.id,
                           registrationStatus: .registered)
        let stu2 = Student(id: "STU-1002", fullName: "Shahd Shahin",
                           dateOfBirth: Calendar.current.date(from: DateComponents(year: 2019, month: 9, day: 2))!,
                           gender: .female, currentGrade: nil,
                           parentId: demoParent.id, schoolId: nil,
                           registrationStatus: .unregistered)
        students = [stu1, stu2]

        // Existing applications
        let appAccepted = RegistrationApplication(
            id: "APP-2026-0001", parentAccountId: demoAccount.id, studentId: stu1.id,
            studentSnapshot: stu1, selectedSchoolId: s1.id, selectedGrade: "Grade 3",
            academicYear: "2026/2027", supportingInfo: "Transfer from public school.",
            submissionDate: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            status: .accepted,
            decisionDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
            decisionByAdminId: "ADM-001", rejectionReason: nil,
            registrationFeeAmount: s1.registrationFee, registrationFeePaid: true
        )
        let appPending = RegistrationApplication(
            id: "APP-2026-0002", parentAccountId: demoAccount.id, studentId: stu2.id,
            studentSnapshot: stu2, selectedSchoolId: s1.id, selectedGrade: "KG2",
            academicYear: "2026/2027", supportingInfo: "",
            submissionDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            status: .pending,
            decisionDate: nil, decisionByAdminId: nil, rejectionReason: nil,
            registrationFeeAmount: s1.registrationFee, registrationFeePaid: false
        )
        applications = [appAccepted, appPending]

        // Payments and records
        let regPayment = Payment(
            id: "PAY-0001", applicationId: appAccepted.id, studentId: stu1.id,
            parentAccountId: demoAccount.id, amount: s1.registrationFee,
            paymentType: .registration, status: .paid,
            referenceNo: "ESD-REG-748213",
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            paidAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
            failureReason: nil, receiptNumber: "RCP-00001"
        )
        let firstTuition = Payment(
            id: "PAY-0002", applicationId: nil, studentId: stu1.id,
            parentAccountId: demoAccount.id, amount: 1800,
            paymentType: .tuition, status: .paid,
            referenceNo: "ESD-TUI-552901",
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            paidAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            failureReason: nil, receiptNumber: "RCP-00002"
        )
        payments = [regPayment, firstTuition]
        paymentRecords = [
            PaymentRecord(studentId: stu1.id, paymentType: .registration,
                          totalDue: s1.registrationFee, totalPaid: s1.registrationFee,
                          outstandingBalance: 0,
                          lastPaymentDate: regPayment.paidAt, nextInstallmentDate: nil,
                          installmentsCount: 1),
            {
                let remaining = s1.annualTuition - 1800
                let dates = (1...4).compactMap {
                    Calendar.current.date(byAdding: .month, value: $0, to: Date())
                }
                let perInstallment = (remaining / Double(dates.count) * 100).rounded() / 100
                let schedule = dates.enumerated().map { i, d in
                    ScheduledInstallment(id: "INS-\(stu1.id)-\(i+1)",
                                         dueDate: d, amount: perInstallment, paid: false)
                }
                return PaymentRecord(studentId: stu1.id, paymentType: .tuition,
                              totalDue: s1.annualTuition, totalPaid: 1800,
                              outstandingBalance: remaining,
                              lastPaymentDate: firstTuition.paidAt,
                              nextInstallmentDate: dates.first,
                              installmentsCount: 1,
                              schedule: schedule)
            }(),
        ]

        // Academic data for stu1
        academicRecords = [
            AcademicRecord(id: "AR-1", studentId: stu1.id, subject: "Arabic", grade: "A", period: "T1"),
            AcademicRecord(id: "AR-2", studentId: stu1.id, subject: "English", grade: "A-", period: "T1"),
            AcademicRecord(id: "AR-3", studentId: stu1.id, subject: "Mathematics", grade: "B+", period: "T1"),
            AcademicRecord(id: "AR-4", studentId: stu1.id, subject: "Science", grade: "A", period: "T1"),
            AcademicRecord(id: "AR-5", studentId: stu1.id, subject: "Islamic Studies", grade: "A", period: "T1"),
        ]
        schedules = [
            ClassScheduleEntry(id: "SCH-1", studentId: stu1.id, className: "Arabic", day: "Sunday", timeSlot: "08:00 - 08:45"),
            ClassScheduleEntry(id: "SCH-2", studentId: stu1.id, className: "Mathematics", day: "Sunday", timeSlot: "08:55 - 09:40"),
            ClassScheduleEntry(id: "SCH-3", studentId: stu1.id, className: "English", day: "Monday", timeSlot: "09:00 - 09:45"),
            ClassScheduleEntry(id: "SCH-4", studentId: stu1.id, className: "Science", day: "Tuesday", timeSlot: "10:00 - 10:45"),
            ClassScheduleEntry(id: "SCH-5", studentId: stu1.id, className: "PE", day: "Wednesday", timeSlot: "11:00 - 11:45"),
            ClassScheduleEntry(id: "SCH-6", studentId: stu1.id, className: "Art", day: "Thursday", timeSlot: "12:00 - 12:45"),
        ]
        calendarEvents = [
            AcademicCalendarEvent(id: "EV-1", schoolId: s1.id, academicYear: "2026/2027",
                                  eventName: "First day of school",
                                  eventDate: Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1))!),
            AcademicCalendarEvent(id: "EV-2", schoolId: s1.id, academicYear: "2026/2027",
                                  eventName: "Mid-term break",
                                  eventDate: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 15))!),
            AcademicCalendarEvent(id: "EV-3", schoolId: s1.id, academicYear: "2026/2027",
                                  eventName: "Final exams begin",
                                  eventDate: Calendar.current.date(from: DateComponents(year: 2027, month: 5, day: 20))!),
        ]
    }

    // MARK: - Lookups
    func school(by id: String) -> School? { schools.first { $0.id == id } }
    func student(by id: String) -> Student? { students.first { $0.id == id } }
    func parentAccount(by id: String) -> ParentAccount? { parentAccounts.first { $0.id == id } }
    func parent(by id: String) -> Parent? { parents.first { $0.id == id } }
    func childrenOf(parentId: String) -> [Student] { students.filter { $0.parentId == parentId } }
    func applicationsOf(parentAccountId: String) -> [RegistrationApplication] {
        applications.filter { $0.parentAccountId == parentAccountId }
    }
    func applicationsForSchool(_ schoolId: String) -> [RegistrationApplication] {
        applications.filter { $0.selectedSchoolId == schoolId }
    }
    func paymentsOf(parentAccountId: String) -> [Payment] {
        payments.filter { $0.parentAccountId == parentAccountId }
    }
    func paymentsForStudent(_ studentId: String) -> [Payment] {
        payments.filter { $0.studentId == studentId }
    }
    func record(for studentId: String, type: PaymentType) -> PaymentRecord? {
        paymentRecords.first { $0.studentId == studentId && $0.paymentType == type }
    }
    func openGrades(for schoolId: String) -> [GradeLevel] {
        gradeLevels.filter { $0.schoolId == schoolId && $0.availableSeats > 0 }
    }

    func notifications(for accountId: String) -> [ParentNotification] {
        notifications.filter { $0.parentAccountId == accountId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func unreadCount(for accountId: String) -> Int {
        notifications.filter { $0.parentAccountId == accountId && !$0.read }.count
    }

    func notify(parentAccountId: String, title: String, body: String,
                applicationId: String? = nil) {
        notifications.append(ParentNotification(
            id: "NOTIF-\(UUID().uuidString.prefix(8))",
            parentAccountId: parentAccountId,
            title: title, body: body, createdAt: Date(),
            read: false, relatedApplicationId: applicationId))
    }

    func markAllRead(for accountId: String) {
        for i in notifications.indices where notifications[i].parentAccountId == accountId {
            notifications[i].read = true
        }
    }
}
