import Foundation
import Testing
@testable import Loadout

struct MacroRemainingTests {
    @Test func subtractionYieldsRemaining() {
        let target = Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60)
        let consumed = Macros(calories: 500, proteinGrams: 40, carbGrams: 50, fatGrams: 15)
        #expect(target - consumed == Macros(calories: 1700, proteinGrams: 140, carbGrams: 150, fatGrams: 45))
    }

    @Test func remainingGoesNegativeWhenOverBudget() {
        let target = Macros(calories: 500, proteinGrams: 20, carbGrams: 40, fatGrams: 10)
        let consumed = Macros(calories: 800, proteinGrams: 60, carbGrams: 90, fatGrams: 30)
        let remaining = target - consumed
        #expect(remaining.calories == -300)
        #expect(remaining.proteinGrams == -40)
    }
}

@MainActor
struct HealthStoreTests {
    @Test func remainingIsNilUntilHealthIsRead() {
        let store = HealthStore()
        let target = Macros(calories: 2000, proteinGrams: 150, carbGrams: 200, fatGrams: 60)
        #expect(store.remaining(against: target) == nil)   // nothing read yet
    }

    @Test func statusReflectsAvailabilityWithoutPrompting() {
        // Constructing the store must not trigger an authorization prompt.
        let store = HealthStore()
        #expect(store.status == .notConnected || store.status == .unavailable)
    }
}
