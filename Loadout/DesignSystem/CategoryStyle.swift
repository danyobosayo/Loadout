import SwiftUI

/// Per-category presentation: an emoji on the section header and a small
/// accent color used as a leading dot on each item row. Emoji + dot pairs
/// reinforce category at a glance — replacing the per-item SF Symbol pass
/// from Phase 4a, which was visually weak (Apple's food-symbol coverage
/// is sparse, so most items collapsed to leaf.fill / drop.fill / fork.knife).
///
/// Map is keyed by `MenuCategory.id` and stays in code rather than JSON
/// because category ids are stable per restaurant and the alternative
/// (JSON-tagging every category) hides what should be a design-system
/// concern. Add new ids here when a new restaurant introduces them.
struct CategoryStyle: Sendable, Equatable {
    let emoji: String
    let accent: Color

    static let `default` = CategoryStyle(emoji: "🍴", accent: .gray)
}

extension MenuCategory {
    var style: CategoryStyle {
        Self.styles[id] ?? .default
    }

    private static let styles: [String: CategoryStyle] = [
        // Chipotle
        "tortilla":  CategoryStyle(emoji: "🌯", accent: .categoryWheat),
        "rice":      CategoryStyle(emoji: "🍚", accent: .categorySage),
        "beans":     CategoryStyle(emoji: "🫘", accent: .categoryBurgundy),
        "protein":   CategoryStyle(emoji: "🍗", accent: .categoryAmber),
        "veggies":   CategoryStyle(emoji: "🥬", accent: .categoryOlive),
        "salsa":     CategoryStyle(emoji: "🌶️", accent: .categoryPaprika),
        "toppings":  CategoryStyle(emoji: "🥗", accent: .categoryOlive),
        "dressing":  CategoryStyle(emoji: "🫗", accent: .appAccent),
        "chips":     CategoryStyle(emoji: "🥨", accent: .categoryWheat),
        // CAVA
        "bases":     CategoryStyle(emoji: "🌾", accent: .categorySage),
        "dips":      CategoryStyle(emoji: "🥣", accent: .categoryButter),
        "mains":     CategoryStyle(emoji: "🍗", accent: .categoryAmber),
        "dressings": CategoryStyle(emoji: "🫗", accent: .appAccent),
        "sides":     CategoryStyle(emoji: "🍪", accent: .categoryWheat)
    ]
}
