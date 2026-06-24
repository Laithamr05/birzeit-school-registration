import SwiftUI

struct AcademicHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    private var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }
    private var children: [Student] {
        guard let p = parent else { return [] }
        return repo.childrenOf(parentId: p.id).filter { $0.registrationStatus == .registered }
    }
    private var selectedChild: Student? {
        // SR6.1 — explicit parent-child link verification.
        // Only resolve a child if it appears in this parent's children list.
        guard let pid = parent?.id else { return nil }
        if let id = session.selectedChildId,
           let c = repo.students.first(where: { $0.id == id && $0.parentId == pid && $0.registrationStatus == .registered }) {
            return c
        }
        return children.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: L.t(.academic), icon: "book.fill")
                if children.isEmpty {
                    EmptyStateView(icon: "book",
                                   message: loc.language == .ar
                                   ? "لا توجد معلومات أكاديمية. أكمل التسجيل أولاً."
                                   : "No academic info yet. Complete registration first.")
                        .card()
                } else {
                    childSwitcher
                    if let c = selectedChild {
                        GradesSection(studentId: c.id)
                        ScheduleSection(studentId: c.id)
                        if let s = c.schoolId {
                            CalendarSection(schoolId: s)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private var childSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(children) { c in
                    Button {
                        session.selectedChildId = c.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                            Text(c.fullName)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(selectedChild?.id == c.id ? Theme.primary : Theme.surfaceAlt)
                        .foregroundColor(selectedChild?.id == c.id ? .white : Theme.textPrimary)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
}

struct GradesSection: View {
    let studentId: String
    @EnvironmentObject var repo: DataRepository

    var records: [AcademicRecord] {
        repo.academicRecords.filter { $0.studentId == studentId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t(.gradesTitle), icon: "chart.bar.fill")
            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { i, r in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Theme.primary)
                            .frame(width: 22)
                        Text(r.subject)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(r.grade)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(gradeColor(r.grade))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(gradeColor(r.grade).opacity(0.15))
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 10)
                    if i < records.count - 1 { Divider() }
                }
            }
            .card()
        }
    }
    private func gradeColor(_ g: String) -> Color {
        if g.hasPrefix("A") { return Theme.success }
        if g.hasPrefix("B") { return Theme.primary }
        if g.hasPrefix("C") { return Theme.warning }
        return Theme.danger
    }
}

struct ScheduleSection: View {
    let studentId: String
    @EnvironmentObject var repo: DataRepository

    var entries: [ClassScheduleEntry] {
        repo.schedules.filter { $0.studentId == studentId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t(.classScheduleTitle), icon: "calendar")
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { i, e in
                    HStack(spacing: 10) {
                        VStack(spacing: 2) {
                            Text(e.day.prefix(3).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.primary)
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.className)
                                .font(.system(size: 14, weight: .semibold))
                            Text(e.timeSlot)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    if i < entries.count - 1 { Divider() }
                }
            }
            .card()
        }
    }
}

struct CalendarSection: View {
    let schoolId: String
    @EnvironmentObject var repo: DataRepository

    var events: [AcademicCalendarEvent] {
        repo.calendarEvents.filter { $0.schoolId == schoolId }.sorted { $0.eventDate < $1.eventDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t(.academicCalendarTitle), icon: "calendar.badge.clock")
            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { i, e in
                    HStack(spacing: 12) {
                        VStack(spacing: 0) {
                            Text(dayString(e.eventDate))
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)
                            Text(monthString(e.eventDate))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 52, height: 52)
                        .background(Theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.eventName)
                                .font(.system(size: 14, weight: .bold))
                            Text(e.eventDate.short())
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    if i < events.count - 1 { Divider() }
                }
            }
            .card()
        }
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd"; return f.string(from: d)
    }
    private func monthString(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LocalizationManager.shared.language == .ar ? "ar" : "en")
        f.dateFormat = "MMM"
        return f.string(from: d)
    }
}
