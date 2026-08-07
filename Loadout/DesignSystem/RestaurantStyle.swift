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
        "subway":        RestaurantStyle(hue: Color(red: 0.29, green: 0.66, blue: 1.00), icon: "restaurant.subway"),     // ocean

        // The second wave has no bespoke glyph yet, so each borrows the station
        // glyph that best describes what you build there. Hues stay deliberately
        // off-brand (PROJECT.md §12) — Chick-fil-A gets aqua, not red; Starbucks
        // clay, not green — and are spread apart so the identity tiles stay
        // distinguishable side by side in Recipes and History.
        "chick-fil-a":   RestaurantStyle(hue: Color(red: 0.25, green: 0.82, blue: 0.85), icon: "station.protein"),  // aqua
        "starbucks":     RestaurantStyle(hue: Color(red: 0.88, green: 0.56, blue: 0.38), icon: "station.drop"),     // clay
        "panera":        RestaurantStyle(hue: Color(red: 0.85, green: 0.45, blue: 0.80), icon: "station.cookie"),   // orchid
        "qdoba":         RestaurantStyle(hue: Color(red: 0.68, green: 0.90, blue: 0.35), icon: "station.wrap"),     // lime
        "moes":          RestaurantStyle(hue: Color(red: 1.00, green: 0.55, blue: 0.55), icon: "station.beans"),    // coral
        "jersey-mikes":  RestaurantStyle(hue: Color(red: 0.55, green: 0.65, blue: 0.85), icon: "station.bread"),    // steel
        "halal-guys":    RestaurantStyle(hue: Color(red: 1.00, green: 0.45, blue: 0.68), icon: "station.rice"),     // rose
        "mod-pizza":     RestaurantStyle(hue: Color(red: 0.95, green: 0.86, blue: 0.48), icon: "station.slice"),    // butter
        "raising-canes": RestaurantStyle(hue: Color(red: 0.80, green: 0.70, blue: 0.55), icon: "station.takeout")   // sand
    ]
}
