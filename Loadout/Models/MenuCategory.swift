import Foundation

nonisolated struct MenuCategory: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let selectionRule: SelectionRule
    let items: [MenuItem]
    // Used as the icon for any item in this category that doesn't supply
    // its own `iconName`. Same vocabulary as `MenuItem.iconName`.
    let iconName: String?

    init(
        id: String,
        name: String,
        selectionRule: SelectionRule,
        items: [MenuItem],
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.selectionRule = selectionRule
        self.items = items
        self.iconName = iconName
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
