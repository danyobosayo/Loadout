import Foundation

nonisolated struct MenuItem: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let servingDescription: String
    let macros: Macros
    let allergens: [Allergen]?
    /// Animal/derived content beyond the allergen list — what vegetarian, vegan
    /// and no-pork are derived from. `nil` means unflagged, NOT "contains
    /// nothing"; see `MenuItem.verdict(for:)`.
    let dietaryMarkers: [DietaryMarker]?
    let notes: String?
    // Token from the MacroFactor `Icon` vocabulary (e.g., "chicken",
    // "riceWhiteBowl", "salsa"). Used by `MenuItemIcon` to render the row
    // icon and reused as the `Icon` field in the MacroFactor export. Nil
    // falls back to the parent `MenuCategory.iconName`.
    let iconName: String?

    init(
        id: String,
        name: String,
        servingDescription: String,
        macros: Macros,
        allergens: [Allergen]? = nil,
        dietaryMarkers: [DietaryMarker]? = nil,
        notes: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.servingDescription = servingDescription
        self.macros = macros
        self.allergens = allergens
        self.dietaryMarkers = dietaryMarkers
        self.notes = notes
        self.iconName = iconName
    }
}

nonisolated enum Allergen: String, Codable, Hashable, Sendable, CaseIterable {
    case milk
    case egg
    case wheat
    case soy
    case peanut
    case treenut
    case fish
    case shellfish
    case sesame
}
