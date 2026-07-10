import Foundation
import Testing
@testable import Loadout

struct BudgetFitTests {
    private let meal = Macros(calories: 600, proteinGrams: 45, carbGrams: 50, fatGrams: 20)
    private let target = Macros(calories: 2000, proteinGrams: 150, carbGrams: 200, fatGrams: 60)

    @Test func noTargetMeansNoFit() {
        #expect(BudgetFit.make(meal: meal, target: nil, remaining: nil) == nil)
    }

    @Test func fallsBackToTargetWithoutHealth() {
        let fit = BudgetFit.make(meal: meal, target: target, remaining: nil)
        #expect(fit?.basis == .target)
        #expect(fit?.budget == target)
    }

    @Test func prefersHealthRemaining() {
        let remaining = Macros(calories: 850, proteinGrams: 55, carbGrams: 90, fatGrams: 25)
        let fit = BudgetFit.make(meal: meal, target: target, remaining: remaining)
        #expect(fit?.basis == .remaining)
        #expect(fit?.budget == remaining)
    }

    @Test func fitsWhenUnderBudget() {
        let remaining = Macros(calories: 850, proteinGrams: 55, carbGrams: 90, fatGrams: 25)
        let fit = BudgetFit.make(meal: meal, target: target, remaining: remaining)!
        #expect(fit.fitsCalories)
        #expect(fit.caloriesLeftAfter == 250)                 // 850 − 600
        #expect(abs(fit.calorieFraction - 600.0 / 850.0) < 1e-9)
    }

    @Test func reportsOverBudget() {
        let remaining = Macros(calories: 500, proteinGrams: 30, carbGrams: 40, fatGrams: 10)
        let fit = BudgetFit.make(meal: meal, target: target, remaining: remaining)!
        #expect(!fit.fitsCalories)
        #expect(fit.caloriesLeftAfter == -100)                // over by 100
        #expect(fit.calorieFraction == 1)                     // clamped for the gauge
        #expect(fit.isOver(\.proteinGrams))                   // 45 > 30
        #expect(fit.isOver(\.fatGrams))                       // 20 > 10
    }

    @Test func perMacroFractionsAndOverFlags() {
        let remaining = Macros(calories: 700, proteinGrams: 40, carbGrams: 100, fatGrams: 30)
        let fit = BudgetFit.make(meal: meal, target: target, remaining: remaining)!
        #expect(fit.isOver(\.proteinGrams))                   // 45 > 40
        #expect(!fit.isOver(\.carbGrams))                     // 50 < 100
        #expect(abs(fit.fraction(\.carbGrams) - 0.5) < 1e-9)  // 50 / 100
        #expect(fit.fraction(\.proteinGrams) == 1)            // 45 > 40 → clamped
    }
}
