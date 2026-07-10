import Foundation

/// Turns a `BodyProfile` into a daily macro `target`: Mifflin–St Jeor BMR →
/// TDEE → goal-adjusted calories → protein-anchored split. Pure and **total**
/// — it never crashes on odd input; the setup form validates sane ranges.
/// See `PREMIUM_PHASE1_PLAN.md` §3. Tunables are named constants below.
nonisolated enum MacroTargetCalculator {
    struct Output: Sendable, Hashable {
        var target: Macros
        var bmr: Double          // shown as "maintenance ≈ …" on the review card
        var tdee: Double
        var floorApplied: Bool
        var rateClamped: Bool
        /// Honest timeline after BOTH clamps (rate + calorie floor); nil for
        /// maintain, or when the floor eats the whole deficit/surplus.
        var achievableWeeks: Int?
    }

    // MARK: Tunables
    private static let kcalPerKg = 7700.0          // ≈ 3500 kcal/lb
    private static let proteinPerLb = 1.0
    private static let proteinCapGrams = 250.0
    private static let fatPerLb = 0.35
    private static let fatFloorPerLb = 0.25
    private static let maxLossFractionPerWeek = 0.01     // ≤ 1% bodyweight/week
    private static let maxGainFractionPerWeek = 0.005    // ≤ 0.5% bodyweight/week
    private static let maxWeeklyKg = 0.91                // hard cap (~2 lb/week)
    private static let floorMale = 1500.0
    private static let floorFemale = 1200.0
    private static let floorUnspecified = 1350.0

    static func target(for profile: BodyProfile) -> Output {
        let bmr = basalMetabolicRate(for: profile)
        let tdee = bmr * profile.activity.multiplier

        let (weeklyDeltaKg, rateClamped) = weeklyDelta(for: profile)
        let rawCalories = tdee + weeklyDeltaKg * kcalPerKg / 7.0

        // Floor first, THEN round to 10, so floored targets are round too.
        let floor = calorieFloor(sex: profile.sex, bmr: bmr)
        var floorApplied = false
        var calories = rawCalories
        if calories < floor {
            calories = floor
            floorApplied = true
        }
        calories = (calories / 10).rounded() * 10

        let split = macroSplit(calories: calories, profile: profile)

        return Output(
            target: Macros(
                calories: calories,
                proteinGrams: split.protein,
                carbGrams: split.carbs,
                fatGrams: split.fat
            ),
            bmr: bmr,
            tdee: tdee,
            floorApplied: floorApplied,
            rateClamped: rateClamped,
            achievableWeeks: achievableWeeks(profile: profile, tdee: tdee, calories: calories)
        )
    }

    // MARK: BMR / floor

    private static func basalMetabolicRate(for p: BodyProfile) -> Double {
        let base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * Double(p.age)
        switch p.sex {
        case .male: return base + 5
        case .female: return base - 161
        case .unspecified: return base + (5 - 161) / 2   // mean of male/female
        }
    }

    private static func calorieFloor(sex: BiologicalSex, bmr: Double) -> Double {
        let sexFloor: Double
        switch sex {
        case .male: sexFloor = floorMale
        case .female: sexFloor = floorFemale
        case .unspecified: sexFloor = floorUnspecified
        }
        return max(sexFloor, bmr * 0.8)
    }

    // MARK: Rate

    /// Signed weekly weight change (kg), clamped to a safe pace. Returns
    /// whether clamping occurred.
    private static func weeklyDelta(for p: BodyProfile) -> (kg: Double, clamped: Bool) {
        guard p.direction != .maintain,
              let goalKg = p.goalWeightKg,
              let weeks = p.timeframeWeeks, weeks > 0 else {
            return (0, false)
        }
        let requested = (goalKg - p.weightKg) / Double(weeks)
        let cap: Double
        switch p.direction {
        case .lose: cap = min(p.weightKg * maxLossFractionPerWeek, maxWeeklyKg)
        case .gain: cap = min(p.weightKg * maxGainFractionPerWeek, maxWeeklyKg)
        case .maintain: cap = 0
        }
        let clamped = max(-cap, min(cap, requested))
        return (clamped, abs(clamped) < abs(requested) - 1e-9)
    }

    // MARK: Macro split (calories authoritative; monotone cascade)

    private static func macroSplit(
        calories: Double,
        profile: BodyProfile
    ) -> (protein: Double, carbs: Double, fat: Double) {
        let anchorKg = min(profile.weightKg, profile.goalWeightKg ?? profile.weightKg)
        let anchorLb = Units.lb(fromKg: anchorKg)

        var protein = min(proteinPerLb * anchorLb, proteinCapGrams)
        var fat = fatPerLb * anchorLb
        var carbs = (calories - 4 * protein - 9 * fat) / 4

        if carbs < 0 {
            // Reduce fat toward its floor.
            fat = max(fatFloorPerLb * anchorLb, (calories - 4 * protein) / 9)
            carbs = (calories - 4 * protein - 9 * fat) / 4
        }
        if carbs < 0 {
            // Fat pinned at its floor; take protein down to whatever the
            // calories afford. Monotone — never *raises* protein (no fixed
            // protein floor that could exceed the 250 g cap for heavy anchors).
            protein = max(0, (calories - 9 * fat) / 4)
            carbs = 0
        }

        return (protein.rounded(), carbs.rounded(), fat.rounded())
    }

    // MARK: Timeline

    private static func achievableWeeks(
        profile: BodyProfile,
        tdee: Double,
        calories: Double
    ) -> Int? {
        guard profile.direction != .maintain,
              let goalKg = profile.goalWeightKg else { return nil }
        // Positive when eating below maintenance (loss), negative for a surplus.
        let dailyDelta = tdee - calories
        let wantsDeficit = profile.direction == .lose
        // The floor may have flipped or erased the intended deficit/surplus.
        guard (dailyDelta > 0) == wantsDeficit, abs(dailyDelta) > 1e-6 else { return nil }
        let weeklyKg = abs(dailyDelta) * 7 / kcalPerKg
        guard weeklyKg > 1e-6 else { return nil }
        let magnitudeKg = abs(goalKg - profile.weightKg)
        return Int((magnitudeKg / weeklyKg).rounded(.up))
    }
}
