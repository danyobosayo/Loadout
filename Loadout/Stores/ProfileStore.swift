import Foundation
import Observation

/// The user's macro goal (target + the body profile it came from), persisted
/// to UserDefaults as JSON. Mirrors `SettingsStore`'s pattern, but holds a
/// user-domain object the premium targeting layer grows around — kept out of
/// app-mechanics prefs. Inject at the app root via `.environment(_:)`.
@MainActor
@Observable
final class ProfileStore {
    private let defaults: UserDefaults

    /// The saved daily macro goal, or nil when the user hasn't set one.
    var goal: MacroGoal? {
        didSet { persist() }
    }

    /// The one accessor Phases 2–4 (HealthKit remaining, Budget Mode, the
    /// solver) read.
    var target: Macros? { goal?.target }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Assigning in init doesn't fire `didSet`, so this doesn't re-persist.
        // A decode failure silently resets to nil — a lost goal is re-enterable;
        // a crash loop is not.
        if let data = defaults.data(forKey: Keys.macroGoal) {
            self.goal = try? JSONDecoder().decode(MacroGoal.self, from: data)
        } else {
            self.goal = nil
        }
    }

    private func persist() {
        if let goal, let data = try? JSONEncoder().encode(goal) {
            defaults.set(data, forKey: Keys.macroGoal)
        } else {
            defaults.removeObject(forKey: Keys.macroGoal)
        }
    }

    private enum Keys {
        static let macroGoal = "loadout.profile.macroGoal"
    }
}
