import Foundation
import Observation

/// User-configurable preferences. Backed by UserDefaults so changes
/// survive launches without needing SwiftData. Inject at the app root
/// via `.environment(_:)` so all views read the same instance.
@MainActor
@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    /// Name of the Loadout → MacroFactor Shortcut the user installs. Must
    /// match that shortcut's title exactly (see `MacroFactorIntegration`);
    /// users who rename it update this to match.
    var shortcutName: String {
        didSet { defaults.set(shortcutName, forKey: Keys.shortcutName) }
    }

    /// First-run flag. Onboarding sets this to true on dismiss; once
    /// true, the onboarding screen never shows again. Persisting via
    /// UserDefaults means a delete-and-reinstall replays onboarding,
    /// which is the expected support path.
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    /// How "Fit my macros" builds. Lives here rather than on the goal itself:
    /// it's a standing preference about *how you like to eat*, not part of the
    /// target, and it rarely changes once set.
    var autoBuild: AutoBuildPreferences {
        didSet { persistAutoBuild() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcutName = defaults.string(forKey: Keys.shortcutName)
            ?? MacroFactorExporter.defaultShortcutName
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        // A decode failure falls back to the default rather than crashing —
        // losing a preference is recoverable in two taps.
        if let data = defaults.data(forKey: Keys.autoBuild) {
            self.autoBuild = (try? JSONDecoder().decode(AutoBuildPreferences.self, from: data)) ?? .default
        } else {
            self.autoBuild = .default
        }
    }

    private func persistAutoBuild() {
        if let data = try? JSONEncoder().encode(autoBuild) {
            defaults.set(data, forKey: Keys.autoBuild)
        }
    }

    private enum Keys {
        static let shortcutName = "loadout.settings.shortcutName"
        static let hasCompletedOnboarding = "loadout.settings.hasCompletedOnboarding"
        static let autoBuild = "loadout.settings.autoBuild"
    }
}
