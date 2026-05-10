import Foundation
import Observation

/// User-configurable preferences. Backed by UserDefaults so changes
/// survive launches without needing SwiftData. Inject at the app root
/// via `.environment(_:)` so all views read the same instance.
@MainActor
@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    /// Name of the user's installed MacroFactor "Log by JSON" Shortcut.
    /// Default matches MacroFactor's official Shortcut today; users on
    /// custom installs can rename here to match.
    var shortcutName: String {
        didSet { defaults.set(shortcutName, forKey: Keys.shortcutName) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcutName = defaults.string(forKey: Keys.shortcutName)
            ?? MacroFactorExporter.defaultShortcutName
    }

    private enum Keys {
        static let shortcutName = "loadout.settings.shortcutName"
    }
}
