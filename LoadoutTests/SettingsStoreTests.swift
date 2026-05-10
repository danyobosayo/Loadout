import Foundation
import Testing
@testable import Loadout

@MainActor
struct SettingsStoreTests {
    /// Each test gets its own UserDefaults suite so they can't observe
    /// each other (or the user's real preferences).
    private static func makeDefaults() -> UserDefaults {
        let suiteName = "loadout.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func defaultShortcutNameMatchesExporterDefault() {
        let store = SettingsStore(defaults: Self.makeDefaults())
        #expect(store.shortcutName == MacroFactorExporter.defaultShortcutName)
    }

    @Test func writesShortcutNameToBackingDefaults() {
        let defaults = Self.makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.shortcutName = "My Custom Shortcut"

        let stored = defaults.string(forKey: "loadout.settings.shortcutName")
        #expect(stored == "My Custom Shortcut")
    }

    @Test func reHydratesShortcutNameFromDefaults() {
        let defaults = Self.makeDefaults()
        defaults.set("Hydrated Shortcut", forKey: "loadout.settings.shortcutName")

        let store = SettingsStore(defaults: defaults)
        #expect(store.shortcutName == "Hydrated Shortcut")
    }

    @Test func onboardingDefaultsToIncomplete() {
        let store = SettingsStore(defaults: Self.makeDefaults())
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test func writesOnboardingFlagToBackingDefaults() {
        let defaults = Self.makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.hasCompletedOnboarding = true

        #expect(defaults.bool(forKey: "loadout.settings.hasCompletedOnboarding") == true)
    }

    @Test func reHydratesOnboardingFlagFromDefaults() {
        let defaults = Self.makeDefaults()
        defaults.set(true, forKey: "loadout.settings.hasCompletedOnboarding")

        let store = SettingsStore(defaults: defaults)
        #expect(store.hasCompletedOnboarding == true)
    }
}
