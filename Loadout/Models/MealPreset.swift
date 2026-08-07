import Foundation

/// A meal the restaurant actually publishes and sells as a named thing —
/// CAVA's signature bowls, Sweetgreen's Harvest Bowl, Subway's Italian B.M.T.
///
/// Where an `OrderFormat` is a *scaffold* (a vessel plus guided picks the user
/// still has to make), a preset is *complete*: every line item is specified, so
/// its macros are known before the tap. Tapping seeds the tray directly — log
/// it as-is, or dismiss the tray and edit it like any other meal.
///
/// **Published combos only.** A preset asserts "this is a real thing you can
/// order," so `sourceNote` records where the composition came from. We don't
/// invent combos — the personal slot on the restaurant screen is filled by the
/// user's own saved recipes instead.
nonisolated struct MealPreset: Codable, Hashable, Sendable, Identifiable {
    let id: String                 // "cava.presets.harissa-avocado-bowl"
    let name: String               // "Harissa Avocado Bowl"
    let blurb: String              // one-line card subtitle
    /// Every line, in serve order. Reuses `SeedItem` so preset data and format
    /// `autoAdd` data speak one vocabulary.
    let items: [SeedItem]
    /// Where the composition was read from, so the "real published combo"
    /// claim stays auditable the way `dataSource` does for menu macros.
    let sourceNote: String?

    private enum CodingKeys: String, CodingKey { case id, name, blurb, items, sourceNote }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        blurb = try c.decode(String.self, forKey: .blurb)
        items = try c.decodeIfPresent([SeedItem].self, forKey: .items) ?? []
        sourceNote = try c.decodeIfPresent(String.self, forKey: .sourceNote)
    }

    init(id: String, name: String, blurb: String, items: [SeedItem], sourceNote: String? = nil) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.items = items
        self.sourceNote = sourceNote
    }
}

/// Top-level shape of a bundled `{restaurantId}.presets.json` file.
nonisolated struct RestaurantPresets: Codable, Hashable, Sendable {
    let restaurantId: String
    let presets: [MealPreset]
}

nonisolated extension MealPreset {
    /// Resolve against the live menu → editable line items, the same snapshot
    /// shape a saved recipe carries. Unknown ids are dropped rather than
    /// faked, so a preset that outlives a menu change degrades to its
    /// still-valid lines instead of showing a phantom item; `isComplete`
    /// reports whether that happened so the card can hide itself.
    func lineItems(in restaurant: Restaurant) -> [LineItem] {
        items.compactMap { seed in
            guard let (item, category) = restaurant.resolve(menuItemId: seed.menuItemId) else { return nil }
            return LineItem(
                id: UUID(),
                menuItemId: item.id,
                displayName: item.name,
                servingDescription: item.servingDescription,
                macros: item.macros,
                quantity: seed.quantity,
                iconName: item.iconName ?? category.iconName
            )
        }
    }

    /// True when every line resolved. A partially-resolving preset would show
    /// macros that undercount what you'd actually be served — worse than not
    /// offering it — so the picker filters on this.
    func isComplete(in restaurant: Restaurant) -> Bool {
        !items.isEmpty && items.allSatisfy { restaurant.resolve(menuItemId: $0.menuItemId) != nil }
    }

    /// Totals as published — what the card shows before you commit.
    func macros(in restaurant: Restaurant) -> Macros {
        lineItems(in: restaurant).reduce(.zero) { $0 + $1.macros * $1.quantity }
    }
}
