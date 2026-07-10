import Foundation
import Testing
@testable import Loadout

@MainActor
struct ProfileStoreTests {
    private func isolatedDefaults() -> (defaults: UserDefaults, suite: String) {
        let suite = "test.profile.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (defaults, suite)
    }

    private func sampleGoal() -> MacroGoal {
        MacroGoal(
            target: Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60),
            source: .manual,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func roundTripsThroughUserDefaults() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ProfileStore(defaults: defaults)
        #expect(store.goal == nil)
        store.goal = sampleGoal()

        // A fresh store on the same defaults reads it back.
        let reopened = ProfileStore(defaults: defaults)
        #expect(reopened.goal == sampleGoal())
        #expect(reopened.target == sampleGoal().target)
    }

    @Test func corruptDataResetsToNilWithoutCrashing() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("not json".utf8), forKey: "loadout.profile.macroGoal")

        let store = ProfileStore(defaults: defaults)
        #expect(store.goal == nil)
        #expect(store.target == nil)
    }

    @Test func clearingGoalRemovesIt() {
        let (defaults, suite) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ProfileStore(defaults: defaults)
        store.goal = sampleGoal()
        store.goal = nil
        #expect(ProfileStore(defaults: defaults).goal == nil)
    }
}
