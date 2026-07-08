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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcutName = defaults.string(forKey: Keys.shortcutName)
            ?? MacroFactorExporter.defaultShortcutName
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    private enum Keys {
        static let shortcutName = "loadout.settings.shortcutName"
        static let hasCompletedOnboarding = "loadout.settings.hasCompletedOnboarding"
    }
}
