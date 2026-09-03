import Foundation

nonisolated struct MenuItem: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let servingDescription: String
    let macros: Macros
    /// Items that are the same dish at different sizes share this key, so the
    /// station list can collapse them into one row with a size picker. A menu of
    /// 427 rows where 258 are Tall/Venti duplicates is not a menu, it's a
    /// scrolling exercise. Nil means the item stands alone.
    let sizeGroup: String?
    /// Short chip label — "M", "Venti", "5 oz". Nil when `sizeGroup` is nil.
    let sizeLabel: String?
    /// The size a customer gets if they say nothing. Exactly one member of a
    /// group carries true.
    let isDefaultSize: Bool
    /// References a source-derived recipe in `Restaurant.drinkRecipes`.
    /// Size remains a menu-item concern; milk, shots, pumps, and preparation
    /// choices belong to the recipe editor.
    let recipeId: String?
    /// Non-nil when this item arrives already built — see `ItemComponent`. The
    /// item's own `macros` stay the as-served board figure; components describe
    /// what each part contributes so it can be declined.
    let components: [ItemComponent]?
    /// True when any of this item's macros are best-supported estimates rather
    /// than exact published figures. The UI labels this briefly; `notes` keeps
    /// the source, method, assumptions, and confidence for auditability.
    let isEstimated: Bool
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
        sizeGroup: String? = nil,
        sizeLabel: String? = nil,
        isDefaultSize: Bool = false,
        recipeId: String? = nil,
        components: [ItemComponent]? = nil,
        isEstimated: Bool = false,
        allergens: [Allergen]? = nil,
        dietaryMarkers: [DietaryMarker]? = nil,
        notes: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.servingDescription = servingDescription
        self.macros = macros
        self.sizeGroup = sizeGroup
        self.sizeLabel = sizeLabel
        self.isDefaultSize = isDefaultSize
        self.recipeId = recipeId
        self.components = components
        self.isEstimated = isEstimated
        self.allergens = allergens
        self.dietaryMarkers = dietaryMarkers
        self.notes = notes
        self.iconName = iconName
    }
}

nonisolated extension MenuItem {
    private enum CodingKeys: String, CodingKey {
        case id, name, servingDescription, macros, sizeGroup, sizeLabel, isDefaultSize, recipeId
        case components, isEstimated, allergens, dietaryMarkers, notes, iconName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            servingDescription: try c.decode(String.self, forKey: .servingDescription),
            macros: try c.decode(Macros.self, forKey: .macros),
            sizeGroup: try c.decodeIfPresent(String.self, forKey: .sizeGroup),
            sizeLabel: try c.decodeIfPresent(String.self, forKey: .sizeLabel),
            isDefaultSize: try c.decodeIfPresent(Bool.self, forKey: .isDefaultSize) ?? false,
            recipeId: try c.decodeIfPresent(String.self, forKey: .recipeId),
            components: try c.decodeIfPresent([ItemComponent].self, forKey: .components),
            isEstimated: try c.decodeIfPresent(Bool.self, forKey: .isEstimated) ?? false,
            allergens: try c.decodeIfPresent([Allergen].self, forKey: .allergens),
            dietaryMarkers: try c.decodeIfPresent([DietaryMarker].self, forKey: .dietaryMarkers),
            notes: try c.decodeIfPresent(String.self, forKey: .notes),
            iconName: try c.decodeIfPresent(String.self, forKey: .iconName)
        )
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
