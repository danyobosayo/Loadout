import Foundation

/// A daily macro target plus the body profile it came from (so it stays
/// re-editable) — the foundation of the premium targeting layer. Phases 2–4
/// (HealthKit remaining, Budget Mode, the auto-build solver) read `target`.
/// All value types, `Codable`/`Sendable`, matching `Macros` / `BuiltMeal`.

nonisolated enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male, female, unspecified

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .unspecified: "Prefer not to say"
        }
    }
}

nonisolated enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary, light, moderate, veryActive, extraActive

    /// TDEE = BMR × multiplier (Mifflin–St Jeor convention).
    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .veryActive: 1.725
        case .extraActive: 1.9
        }
    }

    var label: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Lightly active"
        case .moderate: "Moderately active"
        case .veryActive: "Very active"
        case .extraActive: "Extremely active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: "Desk day, little exercise"
        case .light: "Light exercise 1–3 days/week"
        case .moderate: "Moderate exercise 3–5 days/week"
        case .veryActive: "Hard exercise 6–7 days/week"
        case .extraActive: "Physical job or 2× training"
        }
    }
}

nonisolated enum GoalDirection: String, Codable, CaseIterable, Sendable {
    case lose, maintain, gain

    var label: String {
        switch self {
        case .lose: "Lose"
        case .maintain: "Maintain"
        case .gain: "Gain"
        }
    }
}

/// The inputs to the calculator. Stored **metric always**; the UI is
/// imperial-first and converts via `Units`.
nonisolated struct BodyProfile: Codable, Hashable, Sendable {
    var sex: BiologicalSex
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var activity: ActivityLevel
    var direction: GoalDirection
    var goalWeightKg: Double?   // nil when `.maintain`
    var timeframeWeeks: Int?    // nil when `.maintain`

    init(
        sex: BiologicalSex = .unspecified,
        age: Int = 30,
        heightCm: Double = 170,
        weightKg: Double = 75,
        activity: ActivityLevel = .moderate,
        direction: GoalDirection = .maintain,
        goalWeightKg: Double? = nil,
        timeframeWeeks: Int? = nil
    ) {
        self.sex = sex
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activity = activity
        self.direction = direction
        self.goalWeightKg = goalWeightKg
        self.timeframeWeeks = timeframeWeeks
    }
}

nonisolated struct MacroGoal: Codable, Hashable, Sendable {
    enum Source: String, Codable, Sendable { case generated, manual }

    var target: Macros
    var source: Source
    /// Present when `.generated` — re-opens the setup form pre-filled.
    var profile: BodyProfile?
    var updatedAt: Date
    /// The calorie floor raised the target → UI shows the safe-minimum note.
    var floorApplied: Bool
    /// The requested pace was unsafe and was slowed → UI shows the note.
    var rateClamped: Bool

    init(
        target: Macros,
        source: Source,
        profile: BodyProfile? = nil,
        updatedAt: Date = .now,
        floorApplied: Bool = false,
        rateClamped: Bool = false
    ) {
        self.target = target
        self.source = source
        self.profile = profile
        self.updatedAt = updatedAt
        self.floorApplied = floorApplied
        self.rateClamped = rateClamped
    }
}

/// Imperial ↔ metric. Storage is metric; the form is imperial-first.
nonisolated enum Units {
    static let lbPerKg = 2.2046226218

    static func kg(fromLb lb: Double) -> Double { lb / lbPerKg }
    static func lb(fromKg kg: Double) -> Double { kg * lbPerKg }

    static func cm(fromFeet feet: Int, inches: Double) -> Double {
        (Double(feet) * 12 + inches) * 2.54
    }

    static func feetInches(fromCm cm: Double) -> (feet: Int, inches: Double) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        return (feet, totalInches - Double(feet) * 12)
    }

    static func cm(fromInches inches: Double) -> Double { inches * 2.54 }
    static func inches(fromCm cm: Double) -> Double { cm / 2.54 }
}
