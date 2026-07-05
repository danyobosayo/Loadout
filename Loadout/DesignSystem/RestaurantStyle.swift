import SwiftUI

/// Per-restaurant identity — an abstract hue and a line glyph from
/// the asset catalog (same 24 pt / 1.7 pt family as the station
/// glyphs). Both are Loadout-owned: hues deliberately avoid each
/// brand's palette (PROJECT.md §9) and glyphs are abstract food
/// forms, not logos. Used on the identity tile of restaurant, recipe,
/// and history cards, plus the backdrop whisper and rail pill inside
/// that restaurant's menu.
nonisolated struct RestaurantStyle: Sendable, Equatable {
    let hue: Color
    let icon: String

    static let fallback = RestaurantStyle(
        hue: Color(red: 0.61, green: 0.61, blue: 0.66),
        icon: "station.plate"
    )
}

nonisolated extension Restaurant {
    var style: RestaurantStyle { Self.styles[id] ?? .fallback }

    /// Also resolvable from a bare id (History/Recipes rows render
    /// identity before the full Restaurant is loaded).
    static func style(forId id: String) -> RestaurantStyle {
        styles[id] ?? .fallback
    }

    private static let styles: [String: RestaurantStyle] = [
        "chipotle":      RestaurantStyle(hue: Color(red: 1.00, green: 0.42, blue: 0.29), icon: "restaurant.chipotle"),   // ember
        "cava":          RestaurantStyle(hue: Color(red: 0.62, green: 0.48, blue: 1.00), icon: "restaurant.cava"),       // iris
        "panda-express": RestaurantStyle(hue: Color(red: 0.29, green: 0.87, blue: 0.61), icon: "restaurant.panda"),      // jade
        "sweetgreen":    RestaurantStyle(hue: Color(red: 1.00, green: 0.72, blue: 0.29), icon: "restaurant.sweetgreen"), // citrine
        "subway":        RestaurantStyle(hue: Color(red: 0.29, green: 0.66, blue: 1.00), icon: "restaurant.subway")      // ocean
    ]
}
