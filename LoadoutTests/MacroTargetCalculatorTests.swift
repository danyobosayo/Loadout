import Foundation
import Testing
@testable import Loadout

struct MacroTargetCalculatorTests {
    private func profile(
        sex: BiologicalSex = .unspecified,
        age: Int = 30,
        heightCm: Double = 180,
        weightKg: Double = 80,
        activity: ActivityLevel = .moderate,
        direction: GoalDirection = .maintain,
        goalWeightKg: Double? = nil,
        weeks: Int? = nil
    ) -> BodyProfile {
        BodyProfile(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
                    activity: activity, direction: direction,
                    goalWeightKg: goalWeightKg, timeframeWeeks: weeks)
    }

    // MARK: BMR / TDEE

    @Test func bmrMatchesMifflinStJeor() {
        let male = MacroTargetCalculator.target(for: profile(sex: .male, heightCm: 180, weightKg: 80)).bmr
        #expect(abs(male - 1780) < 0.5)                       // 10·80+6.25·180−5·30+5
        let female = MacroTargetCalculator.target(for: profile(sex: .female, heightCm: 165, weightKg: 65)).bmr
        #expect(abs(female - 1370.25) < 0.5)                  // …−161
    }

    @Test func unspecifiedBmrIsMeanOfMaleAndFemale() {
        let p = profile(sex: .unspecified, heightCm: 180, weightKg: 80)
        let male = MacroTargetCalculator.target(for: profile(sex: .male, heightCm: 180, weightKg: 80)).bmr
        let female = MacroTargetCalculator.target(for: profile(sex: .female, heightCm: 180, weightKg: 80)).bmr
        #expect(abs(MacroTargetCalculator.target(for: p).bmr - (male + female) / 2) < 0.5)
    }

    @Test func tdeeAppliesActivityMultiplier() {
        let out = MacroTargetCalculator.target(for: profile(activity: .moderate))
        #expect(abs(out.tdee - out.bmr * 1.55) < 0.5)
    }

    // MARK: Goal calories

    @Test func moderateDeficitLandsHalfAKiloBelowMaintenance() {
        // 90 kg male, moderate; −8 kg in 16 wk = −0.5 kg/wk (within the 0.9 cap).
        let out = MacroTargetCalculator.target(
            for: profile(sex: .male, weightKg: 90, direction: .lose, goalWeightKg: 82, weeks: 16))
        #expect(out.rateClamped == false)
        #expect(out.floorApplied == false)
        #expect(abs(out.target.calories - (out.tdee - 550)) < 6)   // ≈ TDEE − 500 kcal/day, round-10
    }

    @Test func aggressivePaceIsClampedToASafeRate() {
        // −20 kg in 10 wk = −2 kg/wk → clamps to 0.9 kg/wk; floor doesn't bind here.
        let out = MacroTargetCalculator.target(
            for: profile(sex: .male, weightKg: 90, direction: .lose, goalWeightKg: 70, weeks: 10))
        #expect(out.rateClamped == true)
        #expect(out.floorApplied == false)
        #expect(out.achievableWeeks == 23)                    // honest timeline, not the requested 10
    }

    @Test func gainIsSurplusClampedToHalfPercent() {
        // +10 kg in 10 wk = +1 kg/wk → clamps to 0.35 kg/wk (0.5% of 70).
        let out = MacroTargetCalculator.target(
            for: profile(sex: .male, weightKg: 70, direction: .gain, goalWeightKg: 80, weeks: 10))
        #expect(out.rateClamped == true)
        #expect(out.target.calories > out.tdee)               // a surplus
        #expect(out.achievableWeeks != nil)
    }

    // MARK: Floor

    @Test func calorieFloorClampsAndStaysRoundToTen() {
        let out = MacroTargetCalculator.target(
            for: profile(sex: .female, heightCm: 160, weightKg: 55, activity: .sedentary,
                         direction: .lose, goalWeightKg: 50, weeks: 4))
        #expect(out.floorApplied == true)
        #expect(out.target.calories >= 1200)
        #expect(out.target.calories.truncatingRemainder(dividingBy: 10) == 0)
    }

    @Test func floorEatingTheDeficitSuppressesTheTimeline() {
        // Tiny profile whose safe floor sits above maintenance — no real deficit.
        let out = MacroTargetCalculator.target(
            for: profile(sex: .female, age: 25, heightCm: 150, weightKg: 30, activity: .sedentary,
                         direction: .lose, goalWeightKg: 28, weeks: 8))
        #expect(out.floorApplied == true)
        #expect(out.achievableWeeks == nil)                   // don't lie about weeks
    }

    // MARK: Macro split

    @Test func proteinAnchorsToOneGramPerPound() {
        let out = MacroTargetCalculator.target(for: profile(sex: .male, weightKg: 80))  // maintain
        #expect(out.target.proteinGrams == (Units.lb(fromKg: 80)).rounded())  // ≈ 176 g
        #expect(out.target.carbGrams >= 0)
    }

    @Test func macrosAlwaysSumToTheCalorieTarget() {
        // Heavy floored cutter: the case a naive dual-floor cascade gets wrong
        // (it would emit ~1660 kcal with ~1550 kcal of macros).
        let out = MacroTargetCalculator.target(
            for: profile(sex: .female, age: 40, heightCm: 165, weightKg: 140, activity: .sedentary,
                         direction: .lose, goalWeightKg: 120, weeks: 10))
        #expect(out.floorApplied == true)
        let m = out.target
        let sum = 4 * m.proteinGrams + 4 * m.carbGrams + 9 * m.fatGrams
        #expect(abs(sum - m.calories) <= 20)
        #expect(m.proteinGrams <= 250)                        // never above the cap
        #expect(m.carbGrams >= 0)
    }

    @Test func terminalStepReducesProteinAndNeverRaisesIt() {
        // >160 kg anchor forces the protein-reduction terminal step, where a
        // fixed 0.7 g/lb "floor" would EXCEED the 250 g cap and raise protein.
        let out = MacroTargetCalculator.target(
            for: profile(sex: .female, age: 99, heightCm: 120, weightKg: 200, activity: .sedentary,
                         direction: .lose, goalWeightKg: 190, weeks: 4))
        let m = out.target
        #expect(m.proteinGrams < 250)                         // reduced, not raised
        #expect(m.fatGrams >= (Units.lb(fromKg: 190) * 0.25).rounded() - 1)  // fat at its floor
        let sum = 4 * m.proteinGrams + 4 * m.carbGrams + 9 * m.fatGrams
        #expect(abs(sum - m.calories) <= 20)
    }

    // MARK: Units

    @Test func unitRoundTrips() {
        #expect(abs(Units.kg(fromLb: Units.lb(fromKg: 80)) - 80) < 1e-9)
        let (ft, inch) = Units.feetInches(fromCm: 180)
        #expect(abs(Units.cm(fromFeet: ft, inches: inch) - 180) < 1e-6)
    }
}
