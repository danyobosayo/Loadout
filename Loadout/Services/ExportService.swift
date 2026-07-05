import Foundation

/// Destination-agnostic export of a built meal / saved recipe.
/// MacroFactor keeps its dedicated path (`MacroFactorExporter` →
/// Shortcuts handoff); this service covers everything else:
///
/// - **Loadout recipe JSON** — an open, versioned schema for sharing a
///   recipe with another person or app, and re-importable by us later.
/// - **MyFitnessPal Quick Add text** — MFP has no public JSON-import
///   API, so the honest fast path is a formatted macro summary the
///   user pastes into Quick Add (calories / protein / carbs / fat in
///   MFP's field order), plus the `mfp://` scheme to jump straight
///   into the app.
nonisolated enum ExportService {
    // MARK: Loadout recipe JSON (schema v1)

    struct RecipePayload: Codable, Equatable, Sendable {
        struct Item: Codable, Equatable, Sendable {
            let name: String
            let serving: String
            let quantity: Double
            let macros: Macros
        }

        let schema: String
        let name: String
        let restaurantId: String
        let restaurantName: String
        let exportedAt: String
        let items: [Item]
        let totals: Macros
    }

    static let schemaIdentifier = "loadout.recipe.v1"

    static func recipePayload(
        name: String,
        restaurantId: String,
        lineItems: [LineItem]
    ) -> RecipePayload {
        let totals = lineItems.reduce(Macros.zero) { $0 + $1.macros * $1.quantity }
        return RecipePayload(
            schema: schemaIdentifier,
            name: name,
            restaurantId: restaurantId,
            restaurantName: displayName(forRestaurantId: restaurantId),
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: lineItems.map {
                RecipePayload.Item(
                    name: $0.displayName,
                    serving: $0.servingDescription,
                    quantity: $0.quantity,
                    macros: $0.macros * $0.quantity
                )
            },
            totals: totals
        )
    }

    static func recipeJSON(_ payload: RecipePayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    /// Writes the payload to a temp file for the share sheet. Filename
    /// is the recipe name, slugged, so the receiver sees
    /// "double-chicken-bowl.json", not "tmp83B2.json".
    static func writeShareFile(_ payload: RecipePayload) throws -> URL {
        let data = try recipeJSON(payload)
        let slug = payload.name
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
            .reduce(into: "") { result, ch in
                if ch == "-" && result.hasSuffix("-") { return }
                result.append(ch)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(slug.isEmpty ? "loadout-recipe" : slug)
            .appendingPathExtension("json")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: MyFitnessPal

    /// `mfp://` opens MyFitnessPal if installed (no public deep link
    /// into Quick Add exists — the summary text travels via clipboard).
    static let myFitnessPalURL = URL(string: "mfp://")!

    /// Quick Add-ordered summary: Calories, Protein, Carbs, Fat.
    static func quickAddText(name: String, totals: Macros) -> String {
        """
        \(name)
        Calories: \(Int(totals.calories.rounded()))
        Protein: \(grams(totals.proteinGrams))
        Carbs: \(grams(totals.carbGrams))
        Fat: \(grams(totals.fatGrams))
        """
    }

    /// One-line share/summary form: "780 kcal · P 62g · C 71g · F 24g".
    static func summaryLine(_ totals: Macros) -> String {
        "\(Int(totals.calories.rounded())) kcal · P \(grams(totals.proteinGrams)) · C \(grams(totals.carbGrams)) · F \(grams(totals.fatGrams))"
    }

    // MARK: Display names

    /// "panda-express" → "Panda Express". Known ids get their exact
    /// casing; unknown ids fall back to title-cased kebab words.
    static func displayName(forRestaurantId id: String) -> String {
        if let known = knownNames[id] { return known }
        return id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }

    private static let knownNames: [String: String] = [
        "chipotle": "Chipotle",
        "cava": "CAVA",
        "panda-express": "Panda Express",
        "sweetgreen": "Sweetgreen",
        "subway": "Subway"
    ]

    private static func grams(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? "\(Int(rounded))g"
            : "\(rounded)g"
    }
}
