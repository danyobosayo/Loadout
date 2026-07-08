import Foundation

/// Converts a `BuiltMeal` into MacroFactor's `Log by JSON` payload and hands
/// it off to a user-installed Shortcut via
/// `shortcuts://run-shortcut?name=…&input=text&text=…`. "Log by JSON" is a
/// MacroFactor *action*, not an installable shortcut, so the user installs a
/// wrapper Shortcut (see `MacroFactorIntegration`) that pipes our JSON into
/// that action.
nonisolated struct MacroFactorExporter: Sendable {
    /// Default name of the Shortcut the user installs. Overridable in
    /// Settings for users who rename it. See `MacroFactorIntegration`.
    static let defaultShortcutName = MacroFactorIntegration.defaultShortcutName

    let source: String
    let shortcutName: String

    init(
        source: String = MFExport.sourceIdentifier,
        shortcutName: String = MacroFactorExporter.defaultShortcutName
    ) {
        self.source = source
        self.shortcutName = shortcutName
    }

    /// Builds the MacroFactor recipe payload. Children carry their own
    /// per-item nutrients (already multiplied by quantity) and serving;
    /// parent carries the sum, so MacroFactor renders the breakdown plus
    /// the right total without recomputing.
    func food(for meal: BuiltMeal, restaurantName: String) -> MFExport.Food {
        let parentName = meal.name ?? "\(restaurantName) Meal"
        let children = meal.lineItems.map { lineItem in
            MFExport.Food(
                source: source,
                icon: lineItem.iconName ?? MFExport.defaultIcon,
                name: lineItem.displayName,
                nutrients: nutrientDict(for: lineItem.macros * lineItem.quantity),
                serving: ServingParser.parse(lineItem.servingDescription, quantity: lineItem.quantity),
                llmPrompt: nil,
                barcode: nil,
                brand: nil,
                beverage: nil,
                notes: nil,
                recipe: nil
            )
        }
        return MFExport.Food(
            source: source,
            icon: MFExport.defaultIcon,
            name: parentName,
            nutrients: nutrientDict(for: meal.totalMacros),
            serving: .one,
            llmPrompt: nil,
            barcode: nil,
            brand: nil,
            beverage: nil,
            notes: nil,
            recipe: children.isEmpty ? nil : children
        )
    }

    func encode(_ food: MFExport.Food) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(food)
    }

    /// Builds the Shortcuts URL. Returns nil only if `URLComponents` fails
    /// to compose — in practice it doesn't, since percent-encoding is
    /// handled per query item.
    func shortcutsURL(for food: MFExport.Food) throws -> URL? {
        let json = try encode(food)
        guard let jsonString = String(data: json, encoding: .utf8) else { return nil }
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: shortcutName),
            URLQueryItem(name: "input", value: "text"),
            URLQueryItem(name: "text", value: jsonString)
        ]
        return components.url
    }

    private func nutrientDict(for macros: Macros) -> [String: Decimal] {
        [
            MFExport.NutrientKey.energy: ServingParser.decimal(macros.calories),
            MFExport.NutrientKey.protein: ServingParser.decimal(macros.proteinGrams),
            MFExport.NutrientKey.carbs: ServingParser.decimal(macros.carbGrams),
            MFExport.NutrientKey.fat: ServingParser.decimal(macros.fatGrams)
        ]
    }
}
