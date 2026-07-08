import Foundation
import Testing
@testable import Loadout

struct MacroFactorCallbackURLTests {
    @Test func callbackURLHasXCallbackShapeAndCallbacks() throws {
        let exporter = MacroFactorExporter(shortcutName: "My Shortcut")
        let food = MFExport.Food(
            source: "loadout.app", icon: "foodDefault", name: "Test",
            nutrients: ["energy": 1], serving: .one,
            llmPrompt: nil, barcode: nil, brand: nil, beverage: nil, notes: nil, recipe: nil)

        let url = try #require(try exporter.callbackURL(
            for: food,
            success: URL(string: "loadout://logged")!,
            error: URL(string: "loadout://failed")!,
            cancel: URL(string: "loadout://cancelled")!))

        #expect(url.scheme == "shortcuts")
        #expect(url.host() == "x-callback-url")
        #expect(url.path() == "/run-shortcut")

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["name"] == "My Shortcut")
        #expect(items["input"] == "text")
        #expect(items["x-success"] == "loadout://logged")
        #expect(items["x-error"] == "loadout://failed")
        #expect(items["x-cancel"] == "loadout://cancelled")
        // The text payload is still valid JSON for our Food shape.
        let restored = try JSONDecoder().decode(MFExport.Food.self, from: Data((items["text"] ?? "").utf8))
        #expect(restored.name == "Test")
    }
}

@MainActor
struct MacroFactorExportCoordinatorTests {
    private func meal() -> BuiltMeal {
        BuiltMeal(id: UUID(), restaurantId: "chipotle", name: nil, lineItems: [],
                  createdAt: Date(timeIntervalSince1970: 0))
    }

    @Test func successReturnsMealAndSetsLogged() {
        let export = MacroFactorExport()
        let m = meal()
        export.begin(meal: m)
        let resolved = export.resolve(MacroFactorExport.successURL)
        #expect(resolved?.id == m.id)          // meal handed back for history
        #expect(export.lastOutcome == .logged)
        #expect(export.pending == nil)
    }

    @Test func errorReturnsNilAndSetsFailed() {
        let export = MacroFactorExport()
        export.begin(meal: meal())
        let resolved = export.resolve(MacroFactorExport.errorURL)
        #expect(resolved == nil)               // nothing logged
        #expect(export.lastOutcome == .failed)
        #expect(export.pending == nil)
    }

    @Test func cancelIsSilent() {
        let export = MacroFactorExport()
        export.begin(meal: meal())
        let resolved = export.resolve(MacroFactorExport.cancelURL)
        #expect(resolved == nil)
        #expect(export.lastOutcome == nil)     // no banner on a user cancel
        #expect(export.pending == nil)
    }

    @Test func foreignSchemeIsIgnored() {
        let export = MacroFactorExport()
        export.begin(meal: meal())
        let resolved = export.resolve(URL(string: "https://example.com/logged")!)
        #expect(resolved == nil)
        #expect(export.pending != nil)         // pending untouched
    }
}
