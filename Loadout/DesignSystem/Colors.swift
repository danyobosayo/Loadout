import SwiftUI

// OBSIDIAN palette — see STYLE_GUIDE.md §1. Loadout is dark-only by
// design (enforced at RootView with .preferredColorScheme(.dark)), so
// tokens are literal values, not adaptive assets. Feature views must
// never use a literal Color — tokens only.
nonisolated extension Color {
    // MARK: Canvas
    static let void            = Color(red: 0.043, green: 0.043, blue: 0.059) // #0B0B0F
    static let surface         = Color(red: 0.075, green: 0.075, blue: 0.094) // #131318
    static let surfaceElevated = Color(red: 0.106, green: 0.106, blue: 0.133) // #1B1B22
    static let hairline        = Color.white.opacity(0.08)

    // MARK: Text
    static let textPrimary   = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7
    static let textSecondary = Color(red: 0.612, green: 0.612, blue: 0.659) // #9C9CA8
    static let textTertiary  = Color(red: 0.471, green: 0.471, blue: 0.522) // #787885 — WCAG AA on void

    // MARK: Signature
    static let volt = Color(red: 0.784, green: 1.0, blue: 0.302) // #C8FF4D

    // MARK: Macro semantics (fixed — never re-themed)
    static let kcal    = Color.volt
    static let protein = Color(red: 1.0,   green: 0.478, blue: 0.420) // #FF7A6B
    static let carbs   = Color(red: 0.337, green: 0.784, blue: 0.961) // #56C8F5
    static let fat     = Color(red: 1.0,   green: 0.788, blue: 0.302) // #FFC94D

    // MARK: Feedback
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
    static var destructiveRed: Color { .destructiveRed }
}
