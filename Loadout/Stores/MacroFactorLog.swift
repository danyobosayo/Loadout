import SwiftUI

/// The one place the MacroFactor hand-off is composed: build the x-callback
/// URL, hold the meal for the round-trip, and open Shortcuts — reporting
/// whether iOS accepted the open so callers can react (dismiss, or warn).
///
/// Shared by the tray's "Log to MacroFactor" and the one-tap "Log again" on
/// History/Recipes, so re-logging a stored meal fires the callback directly
/// from its snapshot with no menu load.
@MainActor
enum MacroFactorLog {
    /// Returns false if the callback URL couldn't be built (no open attempted).
    /// Otherwise opens Shortcuts and calls `onOpen(accepted)` — on a rejected
    /// open the pending meal is dropped so a later stray callback can't record it.
    @discardableResult
    static func handOff(
        meal: BuiltMeal,
        restaurantName: String,
        shortcutName: String,
        coordinator: MacroFactorExport,
        open: OpenURLAction,
        onOpen: @escaping (_ accepted: Bool) -> Void
    ) -> Bool {
        let exporter = MacroFactorExporter(shortcutName: shortcutName)
        let food = exporter.food(for: meal, restaurantName: restaurantName)
        guard let url = try? exporter.callbackURL(
            for: food,
            success: MacroFactorExport.successURL,
            error: MacroFactorExport.errorURL,
            cancel: MacroFactorExport.cancelURL
        ) else { return false }

        coordinator.begin(meal: meal)
        open(url) { accepted in
            if !accepted { coordinator.clearPending() }
            onOpen(accepted)
        }
        return true
    }
}
