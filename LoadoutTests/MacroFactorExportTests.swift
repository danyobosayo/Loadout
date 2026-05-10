import Foundation
import Testing
@testable import Loadout

struct MacroFactorExportTests {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    private static let decoder = JSONDecoder()

    // MARK: Serving codable round-trip

    @Test func servingOneEncodesAsStringLiteral() throws {
        let data = try Self.encoder.encode(MFExport.Serving.one)
        #expect(String(data: data, encoding: .utf8) == #""one""#)
        let decoded = try Self.decoder.decode(MFExport.Serving.self, from: data)
        #expect(decoded == .one)
    }

    @Test func servingPer100GramsRoundTrips() throws {
        let data = try Self.encoder.encode(MFExport.Serving.per100Grams)
        #expect(String(data: data, encoding: .utf8) == #""per100Grams""#)
        #expect(try Self.decoder.decode(MFExport.Serving.self, from: data) == .per100Grams)
    }

    @Test func servingMeasuredRoundTrips() throws {
        let original = MFExport.Serving.measured(amount: 4, unit: .ounces)
        let data = try Self.encoder.encode(original)
        #expect(String(data: data, encoding: .utf8) == #"{"amount":4,"unit":"ounces"}"#)
        #expect(try Self.decoder.decode(MFExport.Serving.self, from: data) == original)
    }

    @Test func servingCustomRoundTrips() throws {
        let original = MFExport.Serving.custom(amount: 1, label: "tortilla", weight: 0)
        let data = try Self.encoder.encode(original)
        // Custom is decoded BEFORE measured because its `label` + `weight`
        // keys disambiguate from the measured shape — so an entry whose
        // `unit` happens to look label-ish still parses correctly.
        #expect(try Self.decoder.decode(MFExport.Serving.self, from: data) == original)
    }

    @Test func unknownUnitDecodesAsGramsForwardCompatibility() throws {
        let json = #"{"amount":2,"unit":"furlongs"}"#.data(using: .utf8)!
        let decoded = try Self.decoder.decode(MFExport.Serving.self, from: json)
        #expect(decoded == .measured(amount: 2, unit: .grams))
    }

    @Test func unknownStringServingFailsLoudly() {
        let json = #""nope""#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try Self.decoder.decode(MFExport.Serving.self, from: json)
        }
    }

    // MARK: ServingParser

    @Test func parsesOuncesWithUnitScaling() {
        let s = ServingParser.parse("4 oz", quantity: 2)
        #expect(s == .measured(amount: 8, unit: .ounces))
    }

    @Test func parsesFluidOunces() {
        #expect(ServingParser.parse("2 fl oz") == .measured(amount: 2, unit: .fluidOuncesUS))
    }

    @Test func stripsParentheticalSuffix() {
        #expect(ServingParser.parse("4 oz (regular)") == .measured(amount: 4, unit: .ounces))
        #expect(ServingParser.parse("6 oz (large)") == .measured(amount: 6, unit: .ounces))
    }

    @Test func unknownUnitBecomesCustomLabel() {
        // "1 tortilla" → custom amount=1 label="tortilla". Weight is 0
        // because we don't know how much a tortilla weighs in grams.
        let s = ServingParser.parse("1 tortilla")
        #expect(s == .custom(amount: 1, label: "tortilla", weight: 0))
    }

    @Test func customLabelScalesWithQuantity() {
        let s = ServingParser.parse("1 tortilla", quantity: 3)
        #expect(s == .custom(amount: 3, label: "tortilla", weight: 0))
    }

    @Test func descriptionWithoutLeadingNumberFallsBackToCustom() {
        let s = ServingParser.parse("each", quantity: 2)
        #expect(s == .custom(amount: 2, label: "each", weight: 0))
    }

    @Test func acceptsCommonUnitAliases() {
        #expect(ServingParser.parse("100 grams") == .measured(amount: 100, unit: .grams))
        #expect(ServingParser.parse("1 lb") == .measured(amount: 1, unit: .pounds))
        #expect(ServingParser.parse("2 cups") == .measured(amount: 2, unit: .cupsUS))
    }

    // MARK: Food round-trip

    @Test func foodRoundTripsThroughOurOwnDecoder() throws {
        let food = MFExport.Food(
            source: "loadout.app",
            icon: "chicken",
            name: "Chipotle Bowl",
            nutrients: [
                "energy": 700,
                "protein": 52,
                "carbs": 80,
                "fat": 22.5
            ],
            serving: .one,
            llmPrompt: nil,
            barcode: nil,
            brand: nil,
            beverage: nil,
            notes: nil,
            recipe: [
                MFExport.Food(
                    source: "loadout.app",
                    icon: "chicken",
                    name: "Chicken",
                    nutrients: ["energy": 360, "protein": 64, "carbs": 0, "fat": 14],
                    serving: .measured(amount: 8, unit: .ounces),
                    llmPrompt: nil, barcode: nil, brand: nil, beverage: nil,
                    notes: nil, recipe: nil
                )
            ]
        )
        let data = try Self.encoder.encode(food)
        let restored = try Self.decoder.decode(MFExport.Food.self, from: data)
        #expect(restored == food)
    }

    // MARK: Exporter — meal mapping

    private func makeMeal(
        lineItems: [LineItem],
        name: String? = nil
    ) -> BuiltMeal {
        BuiltMeal(
            id: UUID(),
            restaurantId: "chipotle",
            name: name,
            lineItems: lineItems,
            createdAt: Date(timeIntervalSinceReferenceDate: 0)
        )
    }

    private func line(
        _ name: String,
        macros: Macros,
        quantity: Double = 1,
        serving: String = "4 oz",
        icon: String? = nil
    ) -> LineItem {
        LineItem(
            id: UUID(),
            menuItemId: "chipotle.\(name.lowercased())",
            displayName: name,
            servingDescription: serving,
            macros: macros,
            quantity: quantity,
            iconName: icon
        )
    }

    @Test func parentTotalsEqualSumOfChildNutrients() {
        let exporter = MacroFactorExporter()
        let chicken = line("Chicken", macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7), quantity: 2, icon: "chicken")
        let rice = line("White Rice", macros: Macros(calories: 210, proteinGrams: 4, carbGrams: 40, fatGrams: 4), serving: "4 oz", icon: "riceWhiteBowl")
        let meal = makeMeal(lineItems: [chicken, rice])

        let food = exporter.food(for: meal, restaurantName: "Chipotle")

        // Wrap RHS in `Decimal(_ Int:)` explicitly. Comparing `Decimal?` to
        // a multi-term integer expression (e.g., `180 * 2 + 210`) goes
        // through `ExpressibleByIntegerLiteral` whose result, despite
        // pretty-printing identically, isn't bit-equal to one produced by
        // `Decimal(_ Double:)` — and `Decimal == Decimal` here is
        // bit-comparing on the iOS simulator's Foundation.
        #expect(food.nutrients["energy"] == Decimal(180 * 2 + 210))
        #expect(food.nutrients["protein"] == Decimal(32 * 2 + 4))
        #expect(food.nutrients["carbs"] == Decimal(0 + 40))
        #expect(food.nutrients["fat"] == Decimal(7 * 2 + 4))
        #expect(food.recipe?.count == 2)
    }

    @Test func childNutrientsMultiplyByQuantity() {
        let exporter = MacroFactorExporter()
        let chicken = line("Chicken", macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7), quantity: 2)
        let meal = makeMeal(lineItems: [chicken])

        let child = exporter.food(for: meal, restaurantName: "Chipotle").recipe![0]

        #expect(child.nutrients["energy"] == 360)
        #expect(child.nutrients["protein"] == 64)
        #expect(child.serving == .measured(amount: 8, unit: .ounces))
    }

    @Test func childIconCarriesItemTokenWithFoodDefaultFallback() {
        let exporter = MacroFactorExporter()
        let withIcon = line("Chicken", macros: .zero, icon: "chicken")
        let withoutIcon = line("Mystery", macros: .zero, icon: nil)
        let meal = makeMeal(lineItems: [withIcon, withoutIcon])

        let recipe = exporter.food(for: meal, restaurantName: "Chipotle").recipe!
        #expect(recipe[0].icon == "chicken")
        #expect(recipe[1].icon == MFExport.defaultIcon)
    }

    @Test func parentNameDefaultsToRestaurantPlusMeal() {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)])
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        #expect(food.name == "Chipotle Meal")
    }

    @Test func parentNameUsesUserGivenMealNameWhenSet() {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)], name: "Cane's Bowl")
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        #expect(food.name == "Cane's Bowl")
    }

    @Test func emptyMealOmitsRecipeArray() {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [])
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        #expect(food.recipe == nil)
        #expect(food.nutrients["energy"] == 0)
    }

    @Test func sourceIsLoadoutAppByDefault() {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)])
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        #expect(food.source == "loadout.app")
        #expect(food.recipe?.allSatisfy { $0.source == "loadout.app" } == true)
    }

    @Test func unicodeNameRoundTripsThroughJSON() throws {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)], name: "Cane's “Box” • ñ")
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        let data = try exporter.encode(food)
        let restored = try Self.decoder.decode(MFExport.Food.self, from: data)
        #expect(restored.name == "Cane's “Box” • ñ")
    }

    // MARK: Shortcuts URL

    @Test func shortcutsURLUsesRunShortcutSchemeWithExpectedQueryItems() throws {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)])
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        let url = try #require(try exporter.shortcutsURL(for: food))

        #expect(url.scheme == "shortcuts")
        #expect(url.host() == "run-shortcut")
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["name"] == MacroFactorExporter.defaultShortcutName)
        #expect(items["input"] == "text")
        // The text param must be valid JSON for our Food shape.
        let text = try #require(items["text"])
        let restored = try Self.decoder.decode(MFExport.Food.self, from: Data(text.utf8))
        #expect(restored.source == "loadout.app")
    }

    @Test func shortcutsURLPercentEncodesSpacesInShortcutName() throws {
        let exporter = MacroFactorExporter()
        let meal = makeMeal(lineItems: [line("X", macros: .zero)])
        let food = exporter.food(for: meal, restaurantName: "Chipotle")
        let url = try #require(try exporter.shortcutsURL(for: food))
        // "Log by JSON" needs %20 escaping in the query string. This makes
        // sure URLComponents — not raw concatenation — built the URL.
        #expect(url.absoluteString.contains("name=Log%20by%20JSON"))
    }
}
