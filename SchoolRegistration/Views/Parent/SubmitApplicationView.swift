import SwiftUI

struct SubmitApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var repo: DataRepository
    @EnvironmentObject var loc: LocalizationManager

    @State private var step: Int = 0   // 0: choose grade, 1: child info, 2: review
    @State private var selectedGrade: String = ""
    @State private var childMode: ChildMode = .existing
    @State private var existingChildId: String? = nil

    enum ChildMode { case existing, new }

    // Single-school system — the only school is the active one.
    private var school: School? { repo.schools.first }
    @State private var childName: String = ""
    @State private var childDOB: Date = Calendar.current.date(byAdding: .year, value: -6, to: Date())!
    @State private var gender: Gender = .male
    @State private var notes: String = ""
    @State private var error: String? = nil
    @State private var success: String? = nil

    private var parentAccount: ParentAccount? {
        if case .parent(let a, _) = session.current { return a }
        return nil
    }
    private var parent: Parent? {
        if case .parent(_, let p) = session.current { return p }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    progressBar
                    Group {
                        switch step {
                        case 0: chooseGrade
                        case 1: childInfo
                        default: review
                        }
                    }
                    if let error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Theme.danger)
                            Text(error).font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.danger)
                        }
                        .padding(.horizontal, 4)
                    }
                    if let success {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.success)
                                Text(loc.language == .ar ? "تم تقديم الطلب بنجاح" : "Application submitted")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.success)
                            }
                            Text("\(L.t(.applicationRef)): \(success)")
                                .font(.system(size: 13).monospaced())
                                .foregroundColor(Theme.textSecondary)
                            Button { dismiss() } label: { Text(L.t(.done)) }
                                .buttonStyle(PrimaryButtonStyle(icon: "checkmark.circle.fill"))
                        }
                        .card()
                    } else {
                        navigationButtons
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
            Text(L.t(.submitApplication))
                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Spacer()
            LanguageToggle()
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 22)
        .background(Theme.primaryGradient)
        .clipShape(BottomRoundedShape(radius: 28))
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= step ? Theme.primary : Theme.border)
                    .frame(height: 6)
            }
        }
    }

    private var chooseGrade: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let s = school {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(Theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.schoolName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(L.t(.amount)): \(s.registrationFee.money())")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .card()
            }

            SectionHeader(title: L.t(.grade), icon: "graduationcap.fill")
            let grades = school.map { repo.openGrades(for: $0.id) } ?? []
            if grades.isEmpty {
                EmptyStateView(icon: "calendar.badge.exclamationmark",
                               message: loc.language == .ar
                               ? "لا توجد صفوف متاحة حاليًا"
                               : "No grades currently open")
                    .card()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(grades) { gl in
                        Button {
                            selectedGrade = gl.gradeName
                        } label: {
                            HStack(spacing: 4) {
                                Text(gl.gradeName)
                                Text("(\(gl.availableSeats))")
                                    .font(.system(size: 11)).opacity(0.7)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(selectedGrade == gl.gradeName ? Theme.primary : Theme.surfaceAlt)
                            .foregroundColor(selectedGrade == gl.gradeName ? .white : Theme.textPrimary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
                .cornerRadius(Theme.radius)
                .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
            }
        }
    }

    private var childInfo: some View {
        let existing = parent.map { repo.childrenOf(parentId: $0.id) } ?? []
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: L.t(.child), icon: "person.crop.circle.fill")

            if !existing.isEmpty {
                HStack(spacing: 0) {
                    modeTab(.existing,
                            label: loc.language == .ar ? "طفل موجود" : "Existing child",
                            icon: "person.fill")
                    modeTab(.new,
                            label: loc.language == .ar ? "إضافة طفل جديد" : "Add new child",
                            icon: "person.fill.badge.plus")
                }
                .padding(4)
                .background(Theme.surfaceAlt)
                .cornerRadius(Theme.smallRadius + 4)
            }

            if childMode == .existing && !existing.isEmpty {
                VStack(spacing: 8) {
                    ForEach(existing) { c in
                        Button {
                            existingChildId = c.id
                            childName = c.fullName
                            childDOB = c.dateOfBirth
                            gender = c.gender
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(Theme.accentGradient).frame(width: 40, height: 40)
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.fullName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("\(c.dateOfBirth.short()) • \(c.gender == .male ? L.t(.male) : L.t(.female))")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                if existingChildId == c.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.primary)
                                }
                            }
                            .padding(12)
                            .background(Theme.surface)
                            .cornerRadius(Theme.smallRadius)
                            .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius)
                                        .stroke(existingChildId == c.id ? Theme.primary : Theme.border,
                                                lineWidth: existingChildId == c.id ? 2 : 1))
                        }
                    }
                }
            } else {
                // New child form
                AppTextField(label: L.t(.childFullName), text: $childName,
                             placeholder: "—", icon: "person.fill")
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.t(.childDOB))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    DatePicker("", selection: $childDOB, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface)
                        .cornerRadius(Theme.smallRadius)
                        .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius)
                                    .stroke(Theme.border, lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.t(.childGender))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    HStack(spacing: 10) {
                        genderPill(.male, label: L.t(.male), icon: "figure.child")
                        genderPill(.female, label: L.t(.female), icon: "figure.child")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L.t(.supportingInfo))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                TextEditor(text: $notes)
                    .frame(height: 70)
                    .padding(8)
                    .background(Theme.surface)
                    .cornerRadius(Theme.smallRadius)
                    .overlay(RoundedRectangle(cornerRadius: Theme.smallRadius)
                                .stroke(Theme.border, lineWidth: 1))
            }
        }
        .card()
        .onAppear {
            // Default to "Add new child" if there are no existing children
            if existing.isEmpty { childMode = .new }
        }
    }

    private func modeTab(_ mode: ChildMode, label: String, icon: String) -> some View {
        Button {
            withAnimation { childMode = mode }
            if mode == .new {
                existingChildId = nil
                childName = ""
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(childMode == mode ? .white : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(childMode == mode ? AnyView(Theme.primaryGradient) : AnyView(Color.clear))
            .cornerRadius(Theme.smallRadius)
        }
    }

    private func genderPill(_ g: Gender, label: String, icon: String) -> some View {
        Button { gender = g } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(gender == g ? Theme.primary : Theme.surfaceAlt)
            .foregroundColor(gender == g ? .white : Theme.textPrimary)
            .cornerRadius(Theme.smallRadius)
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: loc.language == .ar ? "مراجعة" : "Review", icon: "checkmark.seal")
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: L.t(.school), value: school?.schoolName ?? "—")
                InfoRow(label: L.t(.grade), value: selectedGrade)
                InfoRow(label: L.t(.childFullName), value: childName)
                InfoRow(label: L.t(.childDOB), value: childDOB.short())
                InfoRow(label: L.t(.childGender),
                        value: gender == .male ? L.t(.male) : L.t(.female))
                InfoRow(label: L.t(.amount),
                        value: (school?.registrationFee ?? 0).money(),
                        valueColor: Theme.accent)
            }
            .card()

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundColor(Theme.primary)
                Text(loc.language == .ar
                     ? "سيتم تعيين حالة الطلب «قيد المراجعة» ويتم إخطارك عند صدور القرار."
                     : "Status will be set to Pending. You'll be notified when the decision is recorded.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 10) {
            if step > 0 {
                Button { withAnimation { step -= 1 } } label: {
                    Text(L.t(.back))
                }.buttonStyle(SecondaryButtonStyle())
            }
            Button { stepForward() } label: {
                Text(step == 2 ? L.t(.submit) : L.t(.next))
            }.buttonStyle(PrimaryButtonStyle(icon: step == 2 ? "paperplane.fill" : "arrow.right"))
        }
    }

    private func stepForward() {
        error = nil
        switch step {
        case 0:
            if selectedGrade.isEmpty {
                error = L.t(.errorRequiredFields); return
            }
        case 1:
            if childMode == .existing {
                if existingChildId == nil {
                    error = loc.language == .ar
                        ? "اختر طفلًا من القائمة" : "Pick a child from the list"
                    return
                }
            } else if childName.trimmingCharacters(in: .whitespaces).isEmpty {
                error = L.t(.errorRequiredFields); return
            }
        default:
            submit(); return
        }
        withAnimation { step += 1 }
    }

    private func submit() {
        guard let school = school, let acc = parentAccount, let p = parent else { return }

        // SR3.4 - prevent duplicate active application for same child/school/grade/year
        let year = "2026/2027"
        let duplicate = repo.applications.contains {
            $0.studentSnapshot.fullName.caseInsensitiveCompare(childName) == .orderedSame &&
            $0.selectedSchoolId == school.id &&
            $0.selectedGrade == selectedGrade &&
            $0.academicYear == year &&
            $0.status != .rejected
        }
        if duplicate {
            error = loc.language == .ar
                ? "يوجد طلب فعّال لنفس الطفل والمدرسة والصف."
                : "An active application already exists for this child/school/grade."
            return
        }

        let student: Student
        if childMode == .existing, let id = existingChildId,
           let e = repo.students.first(where: { $0.id == id }) {
            student = e
        } else if let e = repo.students.first(where: {
            $0.parentId == p.id && $0.fullName == childName && $0.dateOfBirth == childDOB
        }) {
            student = e
        } else {
            student = Student(id: "STU-\(Int.random(in: 1000...9999))",
                              fullName: childName, dateOfBirth: childDOB,
                              gender: gender, currentGrade: nil,
                              parentId: p.id, schoolId: nil,
                              registrationStatus: .unregistered)
            repo.students.append(student)
        }

        let appId = "APP-2026-\(String(format: "%04d", repo.applications.count + 1))"
        let app = RegistrationApplication(
            id: appId, parentAccountId: acc.id, studentId: student.id,
            studentSnapshot: student, selectedSchoolId: school.id,
            selectedGrade: selectedGrade, academicYear: year,
            supportingInfo: notes, submissionDate: Date(), status: .pending,
            decisionDate: nil, decisionByAdminId: nil, rejectionReason: nil,
            registrationFeeAmount: school.registrationFee
        )
        repo.applications.append(app)
        success = appId
    }
}

// Simple flow layout for the grade chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > width {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowH: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}
