import SwiftUI

/// Per-category (station) presentation: a custom template glyph from
/// the asset catalog (Assets.xcassets/station.*) and an accent color
/// for functional cues on item rows. Keyed by `MenuCategory.id`, in
/// code rather than JSON, because station styling is a design-system
/// concern, not menu data. Add new ids here when a new restaurant
/// introduces them — the fallback keeps unknown stations legible.
nonisolated struct CategoryStyle: Sendable, Equatable {
    let icon: String
    let accent: Color

    static let `default` = CategoryStyle(icon: "station.plate", accent: .textSecondary)
}

nonisolated extension MenuCategory {
    var style: CategoryStyle {
        Self.styles[id] ?? .default
    }

    private static let styles: [String: CategoryStyle] = [
        // Chipotle
        "tortilla":   CategoryStyle(icon: "station.wrap", accent: .fat),
        "rice":       CategoryStyle(icon: "station.rice", accent: .carbs),
        "beans":      CategoryStyle(icon: "station.beans", accent: Color(red: 0.78, green: 0.47, blue: 0.44)),
        "protein":    CategoryStyle(icon: "station.protein", accent: .protein),
        "veggies":    CategoryStyle(icon: "station.veg", accent: Color(red: 0.55, green: 0.85, blue: 0.55)),
        "salsa":      CategoryStyle(icon: "station.pepper", accent: .destructiveRed),
        "toppings":   CategoryStyle(icon: "station.salad", accent: Color(red: 0.55, green: 0.85, blue: 0.55)),
        "dressing":   CategoryStyle(icon: "station.bottle", accent: .volt),
        "chips":      CategoryStyle(icon: "station.chips", accent: .fat),
        // CAVA
        "bases":      CategoryStyle(icon: "station.grains", accent: .carbs),
        "dips":       CategoryStyle(icon: "station.dip", accent: .fat),
        "mains":      CategoryStyle(icon: "station.protein", accent: .protein),
        "dressings":  CategoryStyle(icon: "station.bottle", accent: .volt),
        "sides":      CategoryStyle(icon: "station.cookie", accent: .fat),
        // Panda Express
        "entrees":    CategoryStyle(icon: "station.takeout", accent: .protein),
        "appetizers": CategoryStyle(icon: "station.roll", accent: .fat),
        "sauces":     CategoryStyle(icon: "station.drop", accent: .volt),
        // Sweetgreen
        "ingredients": CategoryStyle(icon: "station.slice", accent: Color(red: 0.55, green: 0.85, blue: 0.55)),
        "premiums":    CategoryStyle(icon: "station.sparkle", accent: .fat),
        "proteins":    CategoryStyle(icon: "station.protein", accent: .protein),
        // Subway
        "breads":     CategoryStyle(icon: "station.bread", accent: .carbs),
        "cheeses":    CategoryStyle(icon: "station.cheese", accent: .fat),
        "extras":     CategoryStyle(icon: "station.cookie", accent: .fat),
        // Chick-fil-A
        "breakfast":  CategoryStyle(icon: "station.bread", accent: .carbs),
        // Starbucks — drinks are the menu here, so they get their own stations.
        "hot-coffee":  CategoryStyle(icon: "station.drop", accent: Color(red: 0.72, green: 0.52, blue: 0.38)),
        "cold-coffee": CategoryStyle(icon: "station.drop", accent: .carbs),
        "tea":         CategoryStyle(icon: "station.drop", accent: Color(red: 0.55, green: 0.85, blue: 0.55)),
        "refreshers":  CategoryStyle(icon: "station.sparkle", accent: .protein),
        "frappuccino": CategoryStyle(icon: "station.sparkle", accent: .fat),
        "food":        CategoryStyle(icon: "station.roll", accent: .carbs),
        // MOD Pizza — `crusts` and `meats` rather than bases/proteins so they
        // don't inherit the split-base tap model: you never order half a crust,
        // and pepperoni *and* sausage on one pizza has to be legal.
        "crusts":     CategoryStyle(icon: "station.wrap", accent: .carbs),
        "meats":      CategoryStyle(icon: "station.protein", accent: .protein)
    ]
}
