import Foundation

/// A restaurant-published recipe editor attached to a menu item.
///
/// Starbucks exposes these choices through its ordering API, but continues to
/// show the standard-recipe nutrition after they change. Loadout therefore
/// records the order accurately while keeping the published standard macros.
nonisolated struct DrinkRecipe: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let groups: [RecipeOptionGroup]
    let defaultsBySize: [String: RecipeDefaults]

    func defaults(for sizeLabel: String?) -> RecipeDefaults {
        guard let sizeLabel else { return defaultsBySize["default"] ?? .empty }
        return defaultsBySize[sizeLabel] ?? defaultsBySize["default"] ?? .empty
    }
}

nonisolated struct RecipeOptionGroup: Codable, Hashable, Sendable, Identifiable {
    enum Kind: String, Codable, Hashable, Sendable {
        case single
        case quantity
    }

    let id: String
    let name: String
    let kind: Kind
    let choices: [RecipeChoice]
    /// A single-choice group may be cleared when the official editor offers a
    /// "No …" state (foam, whip, and similar preparation choices).
    let allowsNone: Bool

    init(
        id: String, name: String, kind: Kind,
        choices: [RecipeChoice], allowsNone: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.choices = choices
        self.allowsNone = allowsNone
    }
}

nonisolated struct RecipeChoice: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let maximumQuantity: Int?
}

nonisolated struct RecipeDefaults: Codable, Hashable, Sendable {
    let selections: [String: String]
    let quantities: [String: Int]

    static let empty = RecipeDefaults(selections: [:], quantities: [:])
}

nonisolated extension DrinkRecipe {
    func selection(
        for group: RecipeOptionGroup,
        sizeLabel: String?, configuration: ItemConfiguration
    ) -> String? {
        if configuration.recipeSelectionChanges.contains(group.id) {
            return configuration.recipeSelections[group.id]
        }
        return defaults(for: sizeLabel).selections[group.id]
    }

    func quantity(
        for choice: RecipeChoice,
        sizeLabel: String?, configuration: ItemConfiguration
    ) -> Int {
        configuration.recipeQuantities[choice.id]
            ?? defaults(for: sizeLabel).quantities[choice.id]
            ?? 0
    }

    func summary(
        for configuration: ItemConfiguration,
        sizeLabel: String?
    ) -> [String] {
        let defaults = defaults(for: sizeLabel)
        var parts: [String] = []

        for group in groups where configuration.recipeSelectionChanges.contains(group.id) {
            let selected = configuration.recipeSelections[group.id]
            guard selected != defaults.selections[group.id] else { continue }
            if let selected,
               let name = group.choices.first(where: { $0.id == selected })?.name {
                parts.append(name.lowercased())
            } else {
                parts.append("no \(group.name.lowercased())")
            }
        }

        for group in groups where group.kind == .quantity {
            for choice in group.choices {
                guard let quantity = configuration.recipeQuantities[choice.id] else { continue }
                let standard = defaults.quantities[choice.id] ?? 0
                guard quantity != standard else { continue }
                if quantity == 0 {
                    parts.append("no \(choice.name.lowercased())")
                } else {
                    let label = quantity == 1 ? choice.name : pluralized(choice.name)
                    parts.append("\(quantity) \(label.lowercased())")
                }
            }
        }
        return parts
    }

    private func pluralized(_ value: String) -> String {
        value.lowercased().hasSuffix("shot") ? "\(value)s" : value
    }
}
