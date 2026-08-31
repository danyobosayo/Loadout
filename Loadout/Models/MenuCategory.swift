import Foundation

nonisolated struct MenuCategory: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let selectionRule: SelectionRule
    let items: [MenuItem]
    // Used as the icon for any item in this category that doesn't supply
    // its own `iconName`. Same vocabulary as `MenuItem.iconName`.
    let iconName: String?
    /// True when this station holds whole dishes rather than build components —
    /// Qdoba's signature bowls, Panera's sandwiches. A person can still add one
    /// to anything by hand, but auto-build must not stack a complete bowl on
    /// top of its own rice and protein, which is two meals in one tray.
    let isCompleteMeal: Bool
    /// A pantry station: its items exist so `ItemComponent`s can resolve to real
    /// curated macros, but it is never shown and never solved against. Cane's
    /// combo-portion fries live here — they are a real part of a Box Combo, but
    /// you cannot walk up and order one.
    let isHidden: Bool
    /// A station that holds whole orderable things — Cane's combos, Chick-fil-A's
    /// sandwiches — as opposed to sides, sauces and drinks. These are what the
    /// landing screen lists when it asks "what are you having?".
    ///
    /// Needed because that list used to come from a hand-written presets file,
    /// which was arbitrary: Jersey Mike's had 12 subs and looked right, while
    /// Chick-fil-A had 3 salads and Cane's had no file at all — so Cane's landed
    /// on a screen offering nothing but "Build your own".
    let isHeadline: Bool

    init(
        id: String,
        name: String,
        selectionRule: SelectionRule,
        items: [MenuItem],
        iconName: String? = nil,
        isCompleteMeal: Bool = false,
        isHidden: Bool = false,
        isHeadline: Bool = false
    ) {
        self.id = id
        self.name = name
        self.selectionRule = selectionRule
        self.items = items
        self.iconName = iconName
        self.isCompleteMeal = isCompleteMeal
        self.isHidden = isHidden
        self.isHeadline = isHeadline
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, selectionRule, items, iconName, isCompleteMeal, isHidden, isHeadline
    }

    // Absent in most menu files, so decode leniently rather than requiring the
    // flag on every station.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        selectionRule = try c.decode(SelectionRule.self, forKey: .selectionRule)
        items = try c.decode([MenuItem].self, forKey: .items)
        iconName = try c.decodeIfPresent(String.self, forKey: .iconName)
        isCompleteMeal = try c.decodeIfPresent(Bool.self, forKey: .isCompleteMeal) ?? false
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        isHeadline = try c.decodeIfPresent(Bool.self, forKey: .isHeadline) ?? false
    }
}

nonisolated enum SelectionRule: Hashable, Sendable {
    case selectOne
    case selectMany
    case selectUpTo(Int)
}

nonisolated extension SelectionRule: Codable {
    private enum CodingKeys: String, CodingKey { case kind, max }
    private enum Kind: String, Codable { case selectOne, selectMany, selectUpTo }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .selectOne: self = .selectOne
        case .selectMany: self = .selectMany
        case .selectUpTo: self = .selectUpTo(try container.decode(Int.self, forKey: .max))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .selectOne: try container.encode(Kind.selectOne, forKey: .kind)
        case .selectMany: try container.encode(Kind.selectMany, forKey: .kind)
        case .selectUpTo(let max):
            try container.encode(Kind.selectUpTo, forKey: .kind)
            try container.encode(max, forKey: .max)
        }
    }
}
