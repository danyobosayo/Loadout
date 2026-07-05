import Foundation

/// A counter-style order format (Burrito, Grain Bowl, Footlong) layered
/// over a restaurant's stations. A format never replaces the granular
/// builder — it *seeds* base/vessel items, *guides* the two-to-four
/// defining picks, and *curates* the remaining stations as add-ons. The
/// same `MealBuilderStore` runs underneath, so everything stays editable.
nonisolated struct OrderFormat: Codable, Hashable, Sendable, Identifiable {
    let id: String                     // "burrito", "grain-bowl", "footlong"
    let name: String                   // "Burrito", "Grain Bowl"
    let blurb: String                  // one-line card subtitle
    /// Scales every seeded + guided quantity. Subway Footlong = 2 over the
    /// 6-inch macro basis the menu is authored at; 1 for everything else.
    let portionMultiplier: Double
    let autoAdd: [SeedItem]            // vessels/bases seeded on entry ([] = bowl)
    let prompts: [FormatPrompt]        // the guided quick-picks, in order
    let optionalCategoryIds: [String]  // stations shown as add-ons afterward

    private enum CodingKeys: String, CodingKey {
        case id, name, blurb, portionMultiplier, autoAdd, prompts, optionalCategoryIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        blurb = try c.decode(String.self, forKey: .blurb)
        portionMultiplier = try c.decodeIfPresent(Double.self, forKey: .portionMultiplier) ?? 1
        autoAdd = try c.decodeIfPresent([SeedItem].self, forKey: .autoAdd) ?? []
        prompts = try c.decodeIfPresent([FormatPrompt].self, forKey: .prompts) ?? []
        optionalCategoryIds = try c.decodeIfPresent([String].self, forKey: .optionalCategoryIds) ?? []
    }

    init(
        id: String,
        name: String,
        blurb: String,
        portionMultiplier: Double = 1,
        autoAdd: [SeedItem] = [],
        prompts: [FormatPrompt] = [],
        optionalCategoryIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.portionMultiplier = portionMultiplier
        self.autoAdd = autoAdd
        self.prompts = prompts
        self.optionalCategoryIds = optionalCategoryIds
    }
}

/// One curated pre-seeded line — a vessel/base the format always adds
/// (flour tortilla, whole pita, supergreens). Not a user choice, so it
/// carries no selection rule; `MealBuilderStore.seedThroughRules` resolves
/// it against the live menu and routes it through the normal `add` path.
nonisolated struct SeedItem: Codable, Hashable, Sendable {
    let menuItemId: String
    let quantity: Double
}

/// One guided quick-pick above the station scroll. It resolves to an
/// existing `MenuCategory`, optionally narrows it to `subsetItemIds`
/// (e.g. CAVA grains-vs-greens, which share one `bases` category),
/// retitles the header with `promptCopy`, and enforces `choose` as the
/// pick's selection rule (overriding the category's own).
nonisolated struct FormatPrompt: Codable, Hashable, Sendable, Identifiable {
    let categoryId: String
    let promptCopy: String
    /// Decoded from the terse "one" / "many" / "upTo:N" form in the JSON.
    let choose: SelectionRule
    /// nil = the whole category; otherwise restrict + order by these ids.
    let subsetItemIds: [String]?
    let required: Bool
    /// Units seeded per pick. Chipotle tacos = 3 shells of one type.
    let quantityPerPick: Double

    // A format can prompt the SAME category twice (CAVA Greens+Grains:
    // a grain half and a greens half), so identity is category + copy.
    var id: String { "\(categoryId)|\(promptCopy)" }

    private enum CodingKeys: String, CodingKey {
        case categoryId, promptCopy, choose, subsetItemIds, required, quantityPerPick
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        categoryId = try c.decode(String.self, forKey: .categoryId)
        promptCopy = try c.decode(String.self, forKey: .promptCopy)
        choose = try SelectionRule(compact: c.decode(String.self, forKey: .choose))
        subsetItemIds = try c.decodeIfPresent([String].self, forKey: .subsetItemIds)
        required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        quantityPerPick = try c.decodeIfPresent(Double.self, forKey: .quantityPerPick) ?? 1
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(promptCopy, forKey: .promptCopy)
        try c.encode(choose.compactString, forKey: .choose)
        try c.encodeIfPresent(subsetItemIds, forKey: .subsetItemIds)
        try c.encode(required, forKey: .required)
        try c.encode(quantityPerPick, forKey: .quantityPerPick)
    }

    init(
        categoryId: String,
        promptCopy: String,
        choose: SelectionRule,
        subsetItemIds: [String]? = nil,
        required: Bool = false,
        quantityPerPick: Double = 1
    ) {
        self.categoryId = categoryId
        self.promptCopy = promptCopy
        self.choose = choose
        self.subsetItemIds = subsetItemIds
        self.required = required
        self.quantityPerPick = quantityPerPick
    }
}

/// Top-level shape of a bundled `{restaurantId}.formats.json` file.
nonisolated struct RestaurantFormats: Codable, Hashable, Sendable {
    let restaurantId: String
    let formats: [OrderFormat]
}

nonisolated extension FormatPrompt {
    /// The menu-item ids this prompt offers within `restaurant`: its subset,
    /// or the whole category when `subsetItemIds` is nil.
    func offeredItemIds(in restaurant: Restaurant) -> Set<String> {
        if let subsetItemIds { return Set(subsetItemIds) }
        guard let category = restaurant.category(id: categoryId) else { return [] }
        return Set(category.items.map(\.id))
    }

    /// A short noun for summaries and nudges: "Choose your protein" →
    /// "Protein", "Add a warm grain (optional)" → "Warm grain".
    var shortLabel: String {
        var text = promptCopy
        for prefix in ["Choose your ", "Pick your ", "Choose a ", "Choose ", "Add a ", "Add "] {
            if text.hasPrefix(prefix) {
                text = String(text.dropFirst(prefix.count))
                break
            }
        }
        if let optional = text.range(of: " (optional)") {
            text.removeSubrange(optional)
        }
        return text.isEmpty ? promptCopy : text.prefix(1).uppercased() + text.dropFirst()
    }
}

nonisolated extension OrderFormat {
    /// Required prompts with nothing chosen yet — drives the soft "still to
    /// add" nudge before logging. `selectedIds` is the meal's menu-item ids.
    func unmetRequiredPrompts(selecting selectedIds: Set<String>, in restaurant: Restaurant) -> [FormatPrompt] {
        prompts.filter { $0.required && $0.offeredItemIds(in: restaurant).isDisjoint(with: selectedIds) }
    }
}

nonisolated extension SelectionRule {
    /// The terse guided-prompt form used in `*.formats.json`:
    /// "one" → .selectOne, "many" → .selectMany, "upTo:N" → .selectUpTo(N).
    /// Reusing `SelectionRule` keeps one selection vocabulary across the
    /// menu data, the format data, and the store.
    init(compact: String) throws {
        switch compact {
        case "one": self = .selectOne
        case "many": self = .selectMany
        default:
            guard compact.hasPrefix("upTo:"),
                  let n = Int(compact.dropFirst("upTo:".count)), n >= 1 else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [],
                    debugDescription: "unrecognized choose value '\(compact)'"))
            }
            self = .selectUpTo(n)
        }
    }

    var compactString: String {
        switch self {
        case .selectOne: return "one"
        case .selectMany: return "many"
        case .selectUpTo(let n): return "upTo:\(n)"
        }
    }
}
