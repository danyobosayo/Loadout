import Foundation

/// One dish at several sizes, as the station list shows it: a single row with a
/// size picker, instead of one row per size.
///
/// Starbucks alone had 258 rows that were really 95 drinks — a menu where two
/// thirds of the scrolling is Tall/Venti duplicates isn't a menu. Collapsing
/// them is a *display* change: each size stays its own `MenuItem` with its own
/// macros and its own id, so a saved recipe still points at the exact size you
/// picked, and you can still put a medium and a large fry in one tray.
nonisolated struct SizeGroup: Identifiable, Hashable, Sendable {
    /// The `sizeGroup` key, or the item's own id when it stands alone.
    let id: String
    /// Name with the size stripped — "Waffle Potato Fries", not "… (large)".
    let displayName: String
    /// Ordered smallest-first for the chip row.
    let members: [MenuItem]
    /// What a customer gets if they say nothing.
    let defaultMember: MenuItem

    var hasChoices: Bool { members.count > 1 }

    func member(labelled label: String) -> MenuItem? {
        members.first { $0.sizeLabel == label }
    }
}

nonisolated extension MenuCategory {
    /// The category's items collapsed into size groups, preserving menu order.
    ///
    /// Grouping is driven by data (`MenuItem.sizeGroup`) rather than inferred
    /// from names: "Chicken Noodle Soup - Cup" and "- Bowl" are one dish, but
    /// "White Bread" and "White Bread (Mini)" are arguably two, and only a human
    /// looking at the menu board can tell. Curation decides; code obeys.
    func sizeGroups(from items: [MenuItem]? = nil) -> [SizeGroup] {
        let source = items ?? self.items
        var order: [String] = []
        var buckets: [String: [MenuItem]] = [:]

        for item in source {
            let key = item.sizeGroup ?? item.id
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(item)
        }

        return order.compactMap { key in
            guard let members = buckets[key], let first = members.first else { return nil }
            // A group of one is just an item; don't dress it as a picker.
            guard members.count > 1 else {
                return SizeGroup(id: key, displayName: first.name, members: members, defaultMember: first)
            }
            // Fall back to the first member if curation forgot to mark a default,
            // so a data slip degrades to "smallest wins" rather than an empty row.
            let fallback = members.first(where: \.isDefaultSize) ?? first
            return SizeGroup(
                id: key,
                displayName: SizeGroup.baseName(of: members),
                members: members.sorted { SizeGroup.rank($0.sizeLabel) < SizeGroup.rank($1.sizeLabel) },
                defaultMember: fallback
            )
        }
    }
}

nonisolated extension SizeGroup {
    /// Chips read smallest-first regardless of the order curation happened to
    /// write them in. A numeric label sorts by its number ("2 ct" before
    /// "10 ct", which a string sort gets backwards); a named tier sorts by a
    /// fixed ladder.
    static func rank(_ label: String?) -> Double {
        guard let label = label?.trimmingCharacters(in: .whitespaces).lowercased(), !label.isEmpty else {
            return .greatestFiniteMagnitude
        }
        let leadingNumber = label.prefix { $0.isNumber || $0 == "." }
        if let value = Double(leadingNumber) { return value }

        let ladder = [
            "short": 0, "xs": 0, "mini": 0, "kids": 0, "kid": 0, "kid's": 0,
            "kid\u{2019}s": 0, "s": 1, "small": 1,
            "tall": 1, "cup": 1, "half": 1, "m": 2, "medium": 2, "regular": 2,
            "grande": 2, "bowl": 2, "whole": 2, "l": 3, "large": 3, "venti": 3,
            "giant": 3, "bread bowl": 3, "xl": 4, "trenta": 4, "mega": 4, "jug": 5,
            // Espresso pours are sizes of the same drink, so they share the ladder.
            "solo": 1, "doppio": 2, "triple": 3, "quad": 4,
        ]
        if let rung = ladder[label] { return Double(rung) }
        // Unknown labels sort after the known ladder but keep a stable order.
        return 100
    }

    /// The longest common leading text across members, trimmed of the punctuation
    /// a size suffix leaves behind. "Waffle Potato Fries (small)" + "(large)" →
    /// "Waffle Potato Fries". Falls back to the first name when members share no
    /// prefix, which is a curation error rather than something to paper over.
    static func baseName(of members: [MenuItem]) -> String {
        guard let first = members.first else { return "" }
        var prefix = first.name
        for member in members.dropFirst() {
            prefix = String(zip(prefix, member.name).prefix { $0 == $1 }.map(\.0))
        }
        let trimmed = prefix.trimmingCharacters(in: CharacterSet(charactersIn: " -–—(,[/"))
        return trimmed.count >= 3 ? trimmed : first.name
    }
}
