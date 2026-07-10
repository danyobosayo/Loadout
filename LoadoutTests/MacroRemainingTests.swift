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
    private func isolatedDefaults() -> (UserDefaults, String) {
        let suite = "test.health.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }

    @Test func remainingIsNilUntilHealthIsRead() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HealthStore(defaults: defaults)
        let target = Macros(calories: 2000, proteinGrams: 150, carbGrams: 200, fatGrams: 60)
        #expect(store.remaining(against: target) == nil)   // nothing read yet
    }

    @Test func freshStoreIsNotConnectedWithoutPrompting() {
        // No persisted flag → not connected, and constructing never prompts.
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HealthStore(defaults: defaults)
        #expect(store.status == .notConnected || store.status == .unavailable)
    }

    @Test func persistedFlagRestoresConnectedOnRelaunch() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "loadout.health.connectRequested")
        let store = HealthStore(defaults: defaults)
        // On a device with Health available this restores .connected so the
        // readout repopulates without a re-tap (unavailable on machines without HK).
        #expect(store.status == .connected || store.status == .unavailable)
    }
}
