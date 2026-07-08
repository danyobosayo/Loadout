import Foundation

/// Central configuration for the MacroFactor Shortcuts hand-off.
///
/// IMPORTANT: MacroFactor's "Log by JSON" is a Shortcuts *action*, not an
/// installable shortcut. There is no shortcut named "Log by JSON" for a user
/// to install (the MacroFactor/apple-shortcuts repo only ships water-logging
/// examples). The integration therefore requires the user to install a
/// Shortcut that (a) takes text input and (b) passes it to the "Log by JSON"
/// action. We ship exactly that shortcut; the constants below point at it.
nonisolated enum MacroFactorIntegration {
    /// The Loadout-provided Shortcut's title. `shortcuts://run-shortcut?name=`
    /// matches a shortcut by its title, so this must equal the shortcut's
    /// name in the user's library exactly.
    static let defaultShortcutName = "Loadout to MacroFactor"

    /// One-tap iCloud install link for that Shortcut.
    ///
    /// TODO: replace with the real iCloud share link. Build the Shortcut on
    /// device (Shortcuts → new shortcut → "Receive Text" input → add the
    /// MacroFactor "Log by JSON" action → name it exactly
    /// `defaultShortcutName`), then Share → Copy iCloud Link and paste it here.
    static let installShortcutURL = URL(string: "https://www.icloud.com/shortcuts/REPLACE-WITH-REAL-ID")!

    /// URL scheme reserved for the x-callback-url success/error round-trip
    /// (so we can report a real "logged / failed" instead of only "sent").
    /// TODO(callback): register this scheme in Info.plist and wire the
    /// callbacks before switching the live invocation to x-callback-url.
    static let callbackScheme = "loadout"
}
