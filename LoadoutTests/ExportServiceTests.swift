import Foundation
import Testing
@testable import Loadout

struct ExportServiceTests {
    private func lineItem(
        name: String = "Chicken",
        macros: Macros = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
        quantity: Double = 1
    ) -> LineItem {
        LineItem(
            id: UUID(),
            menuItemId: "chipotle.protein.chicken",
            displayName: name,
            servingDescription: "4 oz",
            macros: macros,
            quantity: quantity
        )
    }

    @Test func payloadTotalsScaleByQuantity() {
        let payload = ExportService.recipePayload(
            name: "Double Chicken Bowl",
            restaurantId: "chipotle",
            lineItems: [lineItem(quantity: 2)]
        )
        #expect(payload.totals.calories == 360)
        #expect(payload.totals.proteinGrams == 64)
        #expect(payload.items.count == 1)
        // Item macros are pre-multiplied so receivers don't re-scale.
        #expect(payload.items[0].macros.calories == 360)
        #expect(payload.items[0].quantity == 2)
    }

    @Test func payloadCarriesSchemaAndRestaurantIdentity() {
        let payload = ExportService.recipePayload(
            name: "Plate", restaurantId: "panda-express", lineItems: [lineItem()]
        )
        #expect(payload.schema == "loadout.recipe.v1")
        #expect(payload.restaurantName == "Panda Express")
    }

    @Test func recipeJSONRoundTrips() throws {
        let payload = ExportService.recipePayload(
            name: "Bowl", restaurantId: "cava", lineItems: [lineItem(), lineItem(name: "Rice")]
        )
        let data = try ExportService.recipeJSON(payload)
        let decoded = try JSONDecoder().decode(ExportService.RecipePayload.self, from: data)
        #expect(decoded == payload)
    }

    @Test func displayNamesResolveKnownAndUnknownIds() {
        #expect(ExportService.displayName(forRestaurantId: "cava") == "CAVA")
        #expect(ExportService.displayName(forRestaurantId: "panda-express") == "Panda Express")
        #expect(ExportService.displayName(forRestaurantId: "five-guys") == "Five Guys")
    }

    @Test func quickAddTextUsesMFPFieldOrder() {
        let totals = Macros(calories: 780.4, proteinGrams: 62, carbGrams: 71.5, fatGrams: 24)
        let text = ExportService.quickAddText(name: "Chipotle Bowl", totals: totals)
        let lines = text.split(separator: "\n").map(String.init)
        #expect(lines[0] == "Chipotle Bowl")
        #expect(lines[1] == "Calories: 780")
        #expect(lines[2] == "Protein: 62g")
        #expect(lines[3] == "Carbs: 71.5g")
        #expect(lines[4] == "Fat: 24g")
    }

    @Test func summaryLineIsCompact() {
        let totals = Macros(calories: 780, proteinGrams: 62, carbGrams: 71, fatGrams: 24)
        #expect(ExportService.summaryLine(totals) == "780 kcal · P 62g · C 71g · F 24g")
    }

    @Test func shareFileNameIsSlugged() throws {
        let payload = ExportService.recipePayload(
            name: "Double Chicken — No Rice!", restaurantId: "chipotle", lineItems: [lineItem()]
        )
        let url = try ExportService.writeShareFile(payload)
        #expect(url.lastPathComponent == "double-chicken-no-rice.json")
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(ExportService.RecipePayload.self, from: data)
        #expect(decoded == payload)
        try? FileManager.default.removeItem(at: url)
    }
}
