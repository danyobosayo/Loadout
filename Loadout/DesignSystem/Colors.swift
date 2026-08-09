import SwiftUI

// OBSIDIAN palette — see STYLE_GUIDE.md §1. Loadout is dark-only by
// design (enforced at RootView with .preferredColorScheme(.dark)), so
// tokens are literal values, not adaptive assets. Feature views must
// never use a literal Color — tokens only.
nonisolated extension Color {
    // MARK: Canvas
    // Warm-neutral, not blue-grey. A blue-leaning dark is what every editor and
    // half the App Store ships by default; a degree of warmth reads as chosen.
    static let void            = Color(red: 0.047, green: 0.043, blue: 0.039) // #0C0B0A
    static let surface         = Color(red: 0.078, green: 0.075, blue: 0.071) // #141312
    static let surfaceElevated = Color(red: 0.110, green: 0.106, blue: 0.098) // #1C1B19
    static let hairline        = Color.white.opacity(0.08)

    // MARK: Text
    static let textPrimary   = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7
    static let textSecondary = Color(red: 0.612, green: 0.612, blue: 0.659) // #9C9CA8
    static let textTertiary  = Color(red: 0.471, green: 0.471, blue: 0.522) // #787885 — WCAG AA on void

    // MARK: Signature
    static let volt = Color(red: 0.784, green: 1.0, blue: 0.302) // #C8FF4D

    // MARK: Macro semantics
    //
    // Deliberately NOT four hues. A red/blue/yellow macro row is the exact
    // mechanism by which every tracker in this category reads as generic — five
    // saturated colours on one viewport and the app has no signature left.
    // Macros are already distinguishable by fixed order, a trailing letter and
    // position (`540 · 34P 22C 41F`), so colour is freed up to do hierarchy
    // instead of identity: one descending ladder on the same neutral.
    //
    // The rungs stop well above the spec's 30% floor because these tint the P/C/F
    // labels as well as the bars, and an illegible label is a worse trade than a
    // flatter ladder (PROJECT.md §9: AA contrast, no colour-only signalling —
    // and nothing here signals by colour alone).
    static let kcal    = Color.volt
    static let protein = Color.white.opacity(0.92)
    static let carbs   = Color.white.opacity(0.66)
    static let fat     = Color.white.opacity(0.46)

    // MARK: Feedback
    /// Over-target, and values we could not verify. Deliberately amber and never
    /// red: going over your macros is information, not a failure, and a red bowl
    /// is an uninstall. Red stays reserved for genuinely destructive actions.
    static let overTarget = Color(red: 1.0, green: 0.690, blue: 0.125) // #FFB020
    static let destructiveRed = Color(red: 1.0, green: 0.365, blue: 0.365) // #FF5D5D
}


nonisolated extension ShapeStyle where Self == Color {
    static var void: Color { .void }
    static var surface: Color { .surface }
    static var surfaceElevated: Color { .surfaceElevated }
    static var hairline: Color { .hairline }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var volt: Color { .volt }
    static var kcal: Color { .kcal }
    static var protein: Color { .protein }
    static var carbs: Color { .carbs }
    static var fat: Color { .fat }
    static var overTarget: Color { .overTarget }
    static var destructiveRed: Color { .destructiveRed }
}
