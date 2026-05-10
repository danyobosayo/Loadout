import SwiftUI

extension Color {
    // Sourced from Assets.xcassets/AccentColor — change the asset to retint
    // the entire app. Using a named asset (rather than a literal Color here)
    // means dark/light variants live in one place and SwiftUI's default
    // .tint picks it up automatically.
    static let appAccent = Color.accentColor

    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let appSurface = Color(uiColor: .secondarySystemGroupedBackground)

    static let appPrimaryText = Color(uiColor: .label)
    static let appSecondaryText = Color(uiColor: .secondaryLabel)

    static let appDestructive = Color.red

    // Per-category accents — small functional cues (~8pt dots on item
    // rows). Distinct from `appAccent` (interactive state) and from any
    // restaurant brand color, which PROJECT.md §9 still forbids. Tuned by
    // eye for legibility against `appSurface` in both schemes; if dark-
    // mode contrast needs nuance later, promote each to an asset entry.
    static let categorySage     = Color(red: 0.45, green: 0.62, blue: 0.40)
    static let categoryAmber    = Color(red: 0.85, green: 0.55, blue: 0.20)
    static let categoryOlive    = Color(red: 0.50, green: 0.65, blue: 0.30)
    static let categoryPaprika  = Color(red: 0.82, green: 0.32, blue: 0.22)
    static let categoryButter   = Color(red: 0.85, green: 0.70, blue: 0.30)
    static let categoryWheat    = Color(red: 0.72, green: 0.55, blue: 0.30)
    static let categoryBurgundy = Color(red: 0.62, green: 0.30, blue: 0.30)
}

// Lets call sites use the SwiftUI shorthand `.foregroundStyle(.appPrimaryText)`
// instead of the longer `Color.appPrimaryText`. `.foregroundStyle` resolves
// dot-syntax against `ShapeStyle`, not `Color`.
extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
    static var appBackground: Color { .appBackground }
    static var appSurface: Color { .appSurface }
    static var appPrimaryText: Color { .appPrimaryText }
    static var appSecondaryText: Color { .appSecondaryText }
    static var appDestructive: Color { .appDestructive }
}
