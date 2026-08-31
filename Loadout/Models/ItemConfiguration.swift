import Foundation

/// One part of an item that arrives already built.
///
/// Loadout began as a bottom-up assembler — start empty, add station by station —
/// which is how Chipotle and CAVA work and how almost nobody else does. A
/// Chick-fil-A sandwich arrives as a buttered bun, a filet and two pickles; a
/// Cane's Box Combo arrives with fries, toast, slaw, sauce and a drink. You
/// subtract from those, you don't assemble them.
///
/// **The published total is as-served and authoritative.** A Chicken Sandwich
/// stays 420 cal. Each component carries what *it* contributes, so removing one
/// is a subtraction and the default total can never drift from the menu board.
nonisolated struct ItemComponent: Codable, Hashable, Sendable, Identifiable {
    /// Points at a real `MenuItem` so the macros come from curated data, never
    /// from a number typed into a component list.
    let menuItemId: String
    var quantity: Double
    /// Included unless the user takes it off.
    let isDefault: Bool
    /// False when the part can't be declined (the filet), or when its macro
    /// contribution couldn't be sourced. In the second case removing it would
    /// mean subtracting an invented number, so we don't offer it — and, per the
    /// product call, we don't show it either.
    let isRemovable: Bool

    var id: String { menuItemId }

    init(menuItemId: String, quantity: Double = 1, isDefault: Bool = true, isRemovable: Bool = true) {
        self.menuItemId = menuItemId
        self.quantity = quantity
        self.isDefault = isDefault
        self.isRemovable = isRemovable
    }
}

/// How a restaurant is ordered. Drives which builder a restaurant presents, so
/// the app mirrors the counter instead of forcing one interaction everywhere.
nonisolated enum OrderingModel: String, Codable, Hashable, Sendable {
    /// Start empty, walk the stations. Chipotle, CAVA, Sweetgreen, Qdoba, Moe's.
    case assembly
    /// Pick a built item, then add and remove. Chick-fil-A, Raising Cane's, MOD.
    case configuration
    /// A default recipe you dial — milk, pump count, whip. Starbucks.
    case recipe
    /// Take a signature and adjust, or build from scratch. Subway, Jersey Mike's.
    case hybrid
}

/// A user's edit of a configured item: which defaults they took off, and what
/// they added on. Held separately from the `MenuItem` so menu data stays
/// immutable and a saved recipe can replay an exact order.
nonisolated struct ItemConfiguration: Codable, Hashable, Sendable {
    /// `menuItemId`s of default components the user declined.
    var removed: Set<String>
    /// Extra components, including a second helping of something already default
    /// (two Chick-fil-A sauces, extra Cane's sauce).
    var added: [ItemComponent]

    static let unchanged = ItemConfiguration(removed: [], added: [])

    var isUnchanged: Bool { removed.isEmpty && added.isEmpty }

    init(removed: Set<String> = [], added: [ItemComponent] = []) {
        self.removed = removed
        self.added = added
    }
}

nonisolated extension MenuItem {
    /// True when this item arrives built and can be configured.
    var isConfigurable: Bool { !(components ?? []).isEmpty }

    /// Components shown in the configure sheet: defaults the user can decline,
    /// plus anything addable. Unremovable defaults are deliberately absent —
    /// showing a greyed row on every sandwich costs more than it explains.
    var configurableComponents: [ItemComponent] {
        (components ?? []).filter { $0.isRemovable }
    }

    /// What arrives on the item and can be taken off — pre-lit in the sheet.
    var removableDefaults: [ItemComponent] {
        (components ?? []).filter { $0.isDefault && $0.isRemovable }
    }

    /// Curated extras this item accepts — dim in the sheet until tapped on.
    var availableExtras: [ItemComponent] {
        (components ?? []).filter { !$0.isDefault }
    }

    /// Macros after applying a configuration.
    ///
    /// Starts from the as-served total — the board figure — then subtracts what
    /// was declined and adds what was chosen. Resolution goes through the menu
    /// so a component's macros are always the curated ones.
    func macros(with configuration: ItemConfiguration, in restaurant: Restaurant) -> Macros {
        var total = macros
        for component in components ?? [] where configuration.removed.contains(component.menuItemId) {
            // Belt and braces: only a default that is actually removable may be
            // subtracted. A stale configuration naming an unremovable part, or an
            // extra that was never included, must not drive the total down.
            guard component.isDefault, component.isRemovable,
                  let resolved = restaurant.resolve(menuItemId: component.menuItemId)?.item
            else { continue }
            total = total - resolved.macros * component.quantity
        }
        for component in configuration.added {
            guard let resolved = restaurant.resolve(menuItemId: component.menuItemId)?.item else { continue }
            total = total + resolved.macros * component.quantity
        }
        // A configuration should never drive a total negative; if it does, the
        // component data is wrong and a clamped zero is less misleading than a
        // negative calorie count on screen.
        return Macros(
            calories: max(0, total.calories),
            proteinGrams: max(0, total.proteinGrams),
            carbGrams: max(0, total.carbGrams),
            fatGrams: max(0, total.fatGrams)
        )
    }

    /// "No pickles · extra Chick-fil-A Sauce" — what the tray shows under the
    /// item name so an order reads back the way it was placed.
    func configurationSummary(_ configuration: ItemConfiguration, in restaurant: Restaurant) -> String? {
        guard !configuration.isUnchanged else { return nil }
        var parts: [String] = []
        for component in components ?? [] where configuration.removed.contains(component.menuItemId) {
            if component.isDefault,
               let name = restaurant.resolve(menuItemId: component.menuItemId)?.item.name {
                parts.append("no \(name.lowercased())")
            }
        }
        for component in configuration.added {
            if let name = restaurant.resolve(menuItemId: component.menuItemId)?.item.name {
                let prefix = component.quantity > 1 ? "\(Int(component.quantity))× " : "extra "
                parts.append("\(prefix)\(name.lowercased())")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
