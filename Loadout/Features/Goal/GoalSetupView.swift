import SwiftUI

/// Sets the user's daily macro target — either **calculated** from body + goal
/// or entered **manually** (copied from MacroFactor). Reusable: the presenter
/// owns the chrome. `onSkip == nil` hides the skip button (Settings edit mode).
struct GoalSetupView: View {
    var onSave: (MacroGoal) -> Void
    var onSkip: (() -> Void)? = nil

    @Environment(ProfileStore.self) private var profile

    private enum Mode: String, CaseIterable {
        case calculate, manual
        var label: String { self == .calculate ? "Calculate for me" : "I have my numbers" }
        var detail: String { self == .calculate ? "From your body + goal" : "Copy from MacroFactor" }
        var icon: String { self == .calculate ? "function" : "square.and.pencil" }
    }

    @State private var mode: Mode = .calculate

    // Calculate-mode inputs (UI imperial-first; converted to metric on build).
    @State private var sex: BiologicalSex = .unspecified
    @State private var ageText = ""
    @State private var useMetric = false
    @State private var heightFtText = ""
    @State private var heightInText = ""
    @State private var heightCmText = ""
    @State private var weightText = ""
    @State private var activity: ActivityLevel = .moderate
    @State private var direction: GoalDirection = .lose
    @State private var goalWeightText = ""
    @State private var weeks = 12
    @State private var computed: MacroTargetCalculator.Output?

    // The four numbers that get saved (calculate fills them; manual types them).
    @State private var calText = ""
    @State private var proteinText = ""
    @State private var carbText = ""
    @State private var fatText = ""

    @FocusState private var keyboardUp: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                modePicker
                Group {
                    if mode == .calculate { calculateSection } else { manualSection }
                }
                disclaimer
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, 160)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { actionBar }
        .onAppear(perform: prefill)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { keyboardUp = false }
            }
        }
    }

    // MARK: Header / mode

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Daily target").microLabelStyle(.volt)
            Text("Set your macros")
                .font(.displayTitle)
                .foregroundStyle(.textPrimary)
            Text("It powers the targeting features — build meals that fit what you've got left.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modePicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Mode.allCases, id: \.self) { m in
                Button {
                    withAnimation(Motion.snap) { mode = m }
                } label: {
                    Card(padding: Spacing.md, highlight: mode == m ? .volt : nil) {
                        VStack(alignment: .leading, spacing: 5) {
                            Image(systemName: m.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(mode == m ? .volt : .textSecondary)
                            Text(m.label).font(.appHeadline).foregroundStyle(.textPrimary)
                            Text(m.detail).font(.appCaption).foregroundStyle(.textTertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
                    }
                }
                .buttonStyle(.pressable)
            }
        }
    }

    // MARK: Calculate

    private var calculateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            field("You are") {
                Picker("", selection: $sex) {
                    ForEach(BiologicalSex.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            field("Age") {
                inputBox { intField($ageText, "30", suffix: "yrs", id: "goalField.age") }
            }

            unitToggle

            field(useMetric ? "Height (cm)" : "Height") {
                if useMetric {
                    inputBox { decimalTextField($heightCmText, "175", id: "goalField.heightCm") }
                } else {
                    HStack(spacing: Spacing.sm) {
                        inputBox { decimalTextField($heightFtText, "5", suffix: "ft", id: "goalField.heightFt") }
                        inputBox { decimalTextField($heightInText, "10", suffix: "in", id: "goalField.heightIn") }
                    }
                }
            }

            field("Current weight") {
                inputBox { decimalTextField($weightText, useMetric ? "70" : "160", suffix: useMetric ? "kg" : "lb", id: "goalField.weight") }
            }

            field("Activity") {
                Picker(selection: $activity) {
                    ForEach(ActivityLevel.allCases, id: \.self) { Text("\($0.label) — \($0.detail)").tag($0) }
                } label: { EmptyView() }
                .pickerStyle(.menu)
                .tint(.volt)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.xs)
            }

            field("Goal") {
                Picker("", selection: $direction) {
                    ForEach(GoalDirection.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            if direction != .maintain {
                field("Goal weight") {
                    inputBox { decimalTextField($goalWeightText, useMetric ? "65" : "145", suffix: useMetric ? "kg" : "lb", id: "goalField.goalWeight") }
                }
                field("Timeframe") {
                    inputBox {
                        Stepper("^[\(weeks) week](inflect: true)", value: $weeks, in: 4...104)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)
                    }
                }
            }

            Button { calculate() } label: {
                Label("Calculate my target", systemImage: "function")
            }
            .buttonStyle(.primaryAction)
            .disabled(buildProfile() == nil)
            .opacity(buildProfile() == nil ? 0.5 : 1)

            if computed != nil {
                reviewCard
                fineTune
            }
        }
    }

    private var unitToggle: some View {
        Picker("", selection: $useMetric) {
            Text("Imperial").tag(false)
            Text("Metric").tag(true)
        }
        .pickerStyle(.segmented)
    }

    // MARK: Manual

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            macroFields
            if let target = currentTarget {
                GoalReviewCard(target: target)
            } else {
                Text("Enter your daily numbers — copy them straight from MacroFactor.")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }

    private var reviewCard: some View {
        Group {
            if let computed {
                GoalReviewCard(
                    target: currentTarget ?? computed.target,
                    maintenance: computed.tdee,
                    floorApplied: computed.floorApplied,
                    rateClamped: computed.rateClamped,
                    achievableWeeks: computed.achievableWeeks
                )
            }
        }
    }

    private var fineTune: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Fine-tune").microLabelStyle()
            macroFields
        }
    }

    private var macroFields: some View {
        VStack(spacing: Spacing.sm) {
            macroRow("Calories", $calText, .kcal, "kcal")
            if calText.isEmpty, let derived = derivedCalories {
                Button {
                    calText = String(derived)
                } label: {
                    Text("≈ \(derived) kcal from your macros — tap to use")
                        .font(.appCaption)
                        .foregroundStyle(.volt)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            macroRow("Protein", $proteinText, .protein, "g")
            macroRow("Carbs", $carbText, .carbs, "g")
            macroRow("Fat", $fatText, .fat, "g")
        }
    }

    // MARK: Disclaimer / actions

    private var disclaimer: some View {
        Text("This is an estimate for healthy adults, not medical advice. Talk to a professional before making significant dietary changes.")
            .font(.appCaption)
            .foregroundStyle(.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionBar: some View {
        VStack(spacing: Spacing.sm) {
            Button { save() } label: {
                Label("Save target", systemImage: "checkmark")
            }
            .buttonStyle(.primaryAction)
            .disabled(currentTarget == nil)
            .opacity(currentTarget == nil ? 0.5 : 1)

            if let onSkip {
                Button("Skip for now") { onSkip() }
                    .buttonStyle(.ghost)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background {
            Rectangle()
                .fill(Color.void)
                .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 1) }
                .ignoresSafeArea()
        }
    }

    // MARK: Reusable field chrome

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label).font(.appCaption).foregroundStyle(.textSecondary)
            content()
        }
    }

    private func inputBox<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)
            .background {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .strokeBorder(Color.hairline, lineWidth: 1))
            }
    }

    private func intField(_ text: Binding<String>, _ placeholder: String, suffix: String? = nil, id: String? = nil) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(.numeral)
                .foregroundStyle(.textPrimary)
                .focused($keyboardUp)
                .accessibilityIdentifier(id ?? placeholder)
            if let suffix {
                Text(suffix).font(.appCaption).foregroundStyle(.textTertiary)
            }
        }
    }

    private func decimalTextField(_ text: Binding<String>, _ placeholder: String, suffix: String? = nil, id: String? = nil) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.numeral)
                .foregroundStyle(.textPrimary)
                .focused($keyboardUp)
                .accessibilityIdentifier(id ?? placeholder)
            if let suffix {
                Text(suffix).font(.appCaption).foregroundStyle(.textTertiary)
            }
        }
    }

    private func macroRow(_ label: String, _ text: Binding<String>, _ color: Color, _ suffix: String) -> some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(.appBody).foregroundStyle(.textPrimary)
            }
            .frame(width: 110, alignment: .leading)
            inputBox {
                HStack {
                    TextField("0", text: text)
                        .keyboardType(.decimalPad)
                        .font(.numeral)
                        .foregroundStyle(.textPrimary)
                        .focused($keyboardUp)
                        .accessibilityIdentifier("goalField.\(label)")
                    Text(suffix).font(.appCaption).foregroundStyle(.textTertiary)
                }
            }
        }
    }

    // MARK: Derived values

    private var derivedCalories: Int? {
        guard let p = Double(proteinText), let c = Double(carbText), let f = Double(fatText),
              p + c + f > 0 else { return nil }
        return Int((4 * p + 4 * c + 9 * f).rounded())
    }

    /// The Macros the four fields describe, or nil until valid.
    private var currentTarget: Macros? {
        guard let cal = Double(calText), cal > 0,
              let p = Double(proteinText), let c = Double(carbText), let f = Double(fatText),
              p >= 0, c >= 0, f >= 0 else { return nil }
        return Macros(calories: cal.rounded(), proteinGrams: p.rounded(),
                      carbGrams: c.rounded(), fatGrams: f.rounded())
    }

    private var parsedHeightCm: Double? {
        if useMetric { return Double(heightCmText) }
        guard let ft = Double(heightFtText) else { return nil }
        let inch = Double(heightInText) ?? 0
        return Units.cm(fromFeet: Int(ft), inches: inch)
    }

    private var parsedWeightKg: Double? {
        guard let w = Double(weightText) else { return nil }
        return useMetric ? w : Units.kg(fromLb: w)
    }

    private var parsedGoalKg: Double? {
        guard let w = Double(goalWeightText) else { return nil }
        return useMetric ? w : Units.kg(fromLb: w)
    }

    private func buildProfile() -> BodyProfile? {
        guard let age = Int(ageText), (18...99).contains(age),
              let heightCm = parsedHeightCm, (120...230).contains(heightCm),
              let weightKg = parsedWeightKg, (30...300).contains(weightKg) else { return nil }
        var goalKg: Double?
        var wk: Int?
        if direction != .maintain {
            guard let g = parsedGoalKg, (30...300).contains(g) else { return nil }
            goalKg = g
            wk = weeks
        }
        return BodyProfile(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
                           activity: activity, direction: direction,
                           goalWeightKg: goalKg, timeframeWeeks: wk)
    }

    // MARK: Actions

    private func calculate() {
        guard let prof = buildProfile() else { return }
        let out = MacroTargetCalculator.target(for: prof)
        withAnimation(Motion.snap) { computed = out }
        calText = String(Int(out.target.calories))
        proteinText = String(Int(out.target.proteinGrams))
        carbText = String(Int(out.target.carbGrams))
        fatText = String(Int(out.target.fatGrams))
        keyboardUp = false
        Haptics.tap()
    }

    private func save() {
        guard let target = currentTarget else { return }
        let source: MacroGoal.Source
        let savedProfile: BodyProfile?
        if mode == .calculate, let computed {
            savedProfile = buildProfile()
            source = target == computed.target ? .generated : .manual
        } else {
            savedProfile = nil
            source = .manual
        }
        Haptics.success()
        onSave(MacroGoal(target: target, source: source, profile: savedProfile))
    }

    private func prefill() {
        guard let goal = profile.goal else { return }
        calText = String(Int(goal.target.calories))
        proteinText = String(Int(goal.target.proteinGrams))
        carbText = String(Int(goal.target.carbGrams))
        fatText = String(Int(goal.target.fatGrams))

        if goal.source == .generated, let p = goal.profile {
            mode = .calculate
            sex = p.sex
            ageText = String(p.age)
            activity = p.activity
            direction = p.direction
            let (ft, inch) = Units.feetInches(fromCm: p.heightCm)
            heightFtText = String(ft)
            heightInText = String(Int(inch.rounded()))
            heightCmText = String(Int(p.heightCm.rounded()))
            weightText = String(Int(Units.lb(fromKg: p.weightKg).rounded()))
            if let g = p.goalWeightKg { goalWeightText = String(Int(Units.lb(fromKg: g).rounded())) }
            if let w = p.timeframeWeeks { weeks = w }
            computed = MacroTargetCalculator.target(for: p)
        } else {
            mode = .manual
        }
    }
}
