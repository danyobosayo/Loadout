import Foundation

/// A restaurant-published recipe editor attached to a menu item.
///
/// Starbucks exposes these choices and their size-specific defaults through its
/// ordering API, but continues to show standard-recipe nutrition after a change.
/// Loadout starts from that exact total and applies documented modifier estimates.
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
    /// Applies only the estimated contribution that changed from the official
    /// standard recipe. This keeps an untouched drink exactly equal to Starbucks'
    /// published total instead of rebuilding it from approximate ingredients.
    func estimatedMacros(
        for item: MenuItem,
        configuration: ItemConfiguration
    ) -> Macros {
        guard configuration.hasRecipeChanges else { return item.macros }
        let defaults = defaults(for: item.sizeLabel)
        var total = item.macros

        for group in groups {
            switch group.kind {
            case .quantity:
                for choice in group.choices {
                    guard let estimate = quantityEstimate(for: choice) else { continue }
                    let standard = defaults.quantities[choice.id] ?? 0
                    let customized = quantity(
                        for: choice, sizeLabel: item.sizeLabel, configuration: configuration
                    )
                    total = total + estimate * Double(customized - standard)
                }
            case .single:
                guard configuration.recipeSelectionChanges.contains(group.id) else { continue }
                let standard = defaults.selections[group.id]
                let customized = configuration.recipeSelections[group.id]
                total = total
                    - singleEstimate(for: standard, in: group, item: item)
                    + singleEstimate(for: customized, in: group, item: item)
            }
        }

        return Macros(
            calories: max(0, total.calories),
            proteinGrams: max(0, total.proteinGrams),
            carbGrams: max(0, total.carbGrams),
            fatGrams: max(0, total.fatGrams)
        )
    }

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

    // MARK: Modifier nutrition estimates

    private func quantityEstimate(for choice: RecipeChoice) -> Macros? {
        let name = choice.name.lowercased()
        if name.contains("espresso shot") {
            // Starbucks publishes Doppio espresso as 10 cal, 1 P, 2 C, 0 F.
            return Macros(calories: 5, proteinGrams: 0.5, carbGrams: 1, fatGrams: 0)
        }
        if name.contains("sugar-free") || name.contains("splenda") || name.contains("stevia") {
            return .zero
        }
        if name == "honey" {
            return Macros(calories: 60, proteinGrams: 0, carbGrams: 17, fatGrams: 0)
        }
        if name == "sugar" || name.contains("sugar in the raw") {
            return Macros(calories: 20, proteinGrams: 0, carbGrams: 5, fatGrams: 0)
        }
        if name.contains("brown sugar syrup") {
            return Macros(calories: 10, proteinGrams: 0, carbGrams: 3, fatGrams: 0)
        }
        if name.contains("syrup") {
            return Macros(calories: 20, proteinGrams: 0, carbGrams: 5, fatGrams: 0)
        }
        if name.contains("white chocolate mocha") {
            return Macros(calories: 30, proteinGrams: 0, carbGrams: 7, fatGrams: 0.5)
        }
        if name.contains("dark caramel") {
            return Macros(calories: 45, proteinGrams: 0, carbGrams: 8, fatGrams: 1.5)
        }
        if name.contains("mocha sauce") {
            return Macros(calories: 25, proteinGrams: 1, carbGrams: 7, fatGrams: 0.5)
        }
        if name.contains("sauce") {
            return Macros(calories: 30, proteinGrams: 0, carbGrams: 7, fatGrams: 0.5)
        }
        return nil
    }

    private func singleEstimate(
        for choiceId: String?, in group: RecipeOptionGroup, item: MenuItem
    ) -> Macros {
        guard let choiceId,
              let choice = group.choices.first(where: { $0.id == choiceId })
        else { return .zero }
        let groupName = group.name.lowercased()
        if groupName == "milk options" {
            return milkEstimate(for: choice.name) * estimatedMilkOunces(for: item)
        }

        let intensity = portionIntensity(for: choice.name)
        guard intensity > 0 else { return .zero }
        if groupName == "whipped cream" {
            let iced = item.recipeId?.hasSuffix(".iced") == true
            let portion: Macros
            if iced {
                portion = item.sizeLabel?.lowercased() == "tall"
                    ? Macros(calories: 80, proteinGrams: 0.5, carbGrams: 2, fatGrams: 8)
                    : Macros(calories: 110, proteinGrams: 1, carbGrams: 3, fatGrams: 11)
            } else {
                portion = switch item.sizeLabel?.lowercased() {
                case "kids", "short":
                    Macros(calories: 50, proteinGrams: 0, carbGrams: 1, fatGrams: 5)
                case "tall":
                    Macros(calories: 60, proteinGrams: 0, carbGrams: 1, fatGrams: 6)
                default:
                    Macros(calories: 70, proteinGrams: 0, carbGrams: 2, fatGrams: 7)
                }
            }
            return portion * intensity
        }
        if groupName.contains("protein cold foam") {
            let protein: Double
            if choice.name.localizedCaseInsensitiveContains("strawberry") {
                protein = 13
            } else if choice.name.localizedCaseInsensitiveContains("vanilla") {
                protein = 17
            } else {
                protein = 15
            }
            return Macros(calories: 255, proteinGrams: protein, carbGrams: 13, fatGrams: 16)
                * intensity
        }
        if groupName == "cold foam" {
            let vanilla = choice.name.localizedCaseInsensitiveContains("vanilla sweet cream")
            return (vanilla
                ? Macros(calories: 110, proteinGrams: 1, carbGrams: 9, fatGrams: 7)
                : Macros(calories: 195, proteinGrams: 2, carbGrams: 16, fatGrams: 14))
                * intensity
        }
        if groupName == "nondairy cold foam" {
            return Macros(calories: 110, proteinGrams: 2, carbGrams: 9, fatGrams: 7)
                * intensity
        }
        if groupName == "drizzle" {
            let mocha = choice.name.localizedCaseInsensitiveContains("mocha")
            return (mocha
                ? Macros(calories: 5, proteinGrams: 0, carbGrams: 1, fatGrams: 0)
                : Macros(calories: 15, proteinGrams: 0, carbGrams: 4, fatGrams: 0))
                * intensity
        }
        if groupName == "topping options" {
            let richer = choice.name.localizedCaseInsensitiveContains("crunch")
                || choice.name.localizedCaseInsensitiveContains("crumble")
            return (richer
                ? Macros(calories: 30, proteinGrams: 0, carbGrams: 5, fatGrams: 1)
                : Macros(calories: 10, proteinGrams: 0, carbGrams: 2, fatGrams: 0))
                * intensity
        }
        return .zero
    }

    private func portionIntensity(for name: String) -> Double {
        let value = name.lowercased()
        if value.hasPrefix("no ") || value.hasSuffix(" no") { return 0 }
        if value.hasPrefix("light ") || value.hasSuffix(" light") { return 0.5 }
        if value.hasPrefix("extra ") || value.hasSuffix(" extra") { return 1.5 }
        return 1
    }

    /// Per-fluid-ounce profiles. Dairy values follow standard USDA-style milk
    /// composition; Starbucks-specific plant milks use published/menu analogues.
    private func milkEstimate(for name: String) -> Macros {
        let value = name.lowercased()
        let perCup: Macros
        if value.contains("protein-boosted") {
            perCup = Macros(calories: 150, proteinGrams: 17, carbGrams: 11, fatGrams: 4.5)
        } else if value.contains("nondairy vanilla sweet cream") {
            perCup = Macros(calories: 320, proteinGrams: 2, carbGrams: 40, fatGrams: 16)
        } else if value.contains("vanilla sweet cream") {
            perCup = Macros(calories: 400, proteinGrams: 4, carbGrams: 40, fatGrams: 24)
        } else if value.contains("nonfat") {
            perCup = Macros(calories: 83, proteinGrams: 8.3, carbGrams: 12.2, fatGrams: 0.2)
        } else if value.contains("whole") {
            perCup = Macros(calories: 149, proteinGrams: 7.7, carbGrams: 11.7, fatGrams: 7.9)
        } else if value.contains("breve") {
            perCup = Macros(calories: 315, proteinGrams: 7.6, carbGrams: 10.4, fatGrams: 28)
        } else if value.contains("heavy cream") {
            perCup = Macros(calories: 821, proteinGrams: 6.6, carbGrams: 6.8, fatGrams: 88)
        } else if value.contains("soy") {
            perCup = Macros(calories: 130, proteinGrams: 8, carbGrams: 16, fatGrams: 4)
        } else if value.contains("coconut") {
            perCup = Macros(calories: 80, proteinGrams: 1, carbGrams: 10, fatGrams: 5)
        } else if value.contains("almond") {
            perCup = Macros(calories: 60, proteinGrams: 2, carbGrams: 6, fatGrams: 4)
        } else if value.contains("oat") {
            perCup = Macros(calories: 140, proteinGrams: 3, carbGrams: 16, fatGrams: 7)
        } else {
            perCup = Macros(calories: 122, proteinGrams: 8, carbGrams: 12, fatGrams: 4.8)
        }
        return perCup * (1.0 / 8.0)
    }

    private func estimatedMilkOunces(for item: MenuItem) -> Double {
        let cupOunces = item.servingDescription
            .split(whereSeparator: { !$0.isNumber && $0 != "." })
            .compactMap { Double($0) }
            .first ?? 16
        let name = item.name.lowercased()
        if name.contains("frappuccino") { return cupOunces * 0.25 }
        if name.contains("shaken espresso") { return item.sizeLabel == "Venti" ? 3 : 2 }
        if name.contains("caffè misto") || name.contains("caffe misto") {
            return cupOunces * 0.5
        }
        if name.contains("cold brew") || name.contains("brewed coffee")
            || name.contains("americano") || name.contains("espresso")
            || name.contains("iced coffee") {
            return 2
        }
        if name.contains("iced") || item.recipeId?.hasSuffix(".iced") == true {
            return cupOunces * 0.5
        }
        return cupOunces * 0.75
    }
}
