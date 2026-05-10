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
