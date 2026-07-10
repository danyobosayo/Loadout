import Foundation
import Observation

/// Coordinates the MacroFactor hand-off across the Shortcuts round-trip.
///
/// Logging opens `shortcuts://x-callback-url/...`, which backgrounds the app.
/// When the shortcut finishes, Shortcuts opens one of our `loadout://` URLs
/// and the app foregrounds — the app root resolves it here. The pending meal
/// is held until then so it's recorded to history only on a *real* success.
@MainActor
@Observable
final class MacroFactorExport {
    enum Outcome: Equatable { case logged, failed }

    /// The meal awaiting a callback, or nil when idle.
    private(set) var pending: BuiltMeal?
    /// The latest terminal result, for a transient banner. Cleared once shown.
    var lastOutcome: Outcome?

    private static func url(_ host: String) -> URL {
        URL(string: "\(MacroFactorIntegration.callbackScheme)://\(host)")!
    }
    static let successURL = url("logged")
    static let errorURL = url("failed")
    static let cancelURL = url("cancelled")

    /// Called just before opening the shortcut, holding the meal for the
    /// callback to confirm.
    func begin(meal: BuiltMeal) {
        pending = meal
    }

    /// The hand-off never launched (e.g. `openURL` was rejected because
    /// Shortcuts is unavailable). Drop the held meal so a later stray
    /// callback can't record it; the caller surfaces its own feedback.
    func clearPending() {
        pending = nil
    }

    /// Resolve an incoming `loadout://` callback. Returns the meal to record
    /// to history on success; nil otherwise. Sets `lastOutcome` for the
    /// banner (except on cancel, which is silent).
    @discardableResult
    func resolve(_ url: URL) -> BuiltMeal? {
        guard url.scheme == MacroFactorIntegration.callbackScheme else { return nil }
        let meal = pending
        pending = nil
        switch url.host {
        case Self.successURL.host:
            lastOutcome = .logged
            return meal
        case Self.errorURL.host:
            lastOutcome = .failed
            return nil
        default:                       // cancelled / unknown — no banner
            return nil
        }
    }
}
