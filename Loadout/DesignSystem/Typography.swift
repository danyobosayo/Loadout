import SwiftUI

// OBSIDIAN type scale — STYLE_GUIDE.md §2.
// Words: SF Pro. Food numbers: SF Rounded, monospaced digits, always.
nonisolated extension Font {
    // MARK: Words
    static let displayXL    = Font.system(size: 40, weight: .heavy)
    static let displayTitle = Font.system(size: 28, weight: .bold)
    static let appHeadline  = Font.system(size: 17, weight: .semibold)
    static let appBody      = Font.system(size: 16, weight: .regular)
    static let appCaption   = Font.system(size: 12, weight: .medium)
    static let microLabel   = Font.system(size: 11, weight: .semibold)

    // MARK: Numerals (rounded + monospacedDigit so values tick in place
    // through .contentTransition(.numericText()) without lateral shift)
    static let numeralHero  = Font.system(size: 44, design: .rounded).weight(.bold).monospacedDigit()
    static let numeralLarge = Font.system(size: 24, design: .rounded).weight(.semibold).monospacedDigit()
    static let numeral      = Font.system(size: 17, design: .rounded).weight(.semibold).monospacedDigit()
}

extension View {
    /// `microLabel` treatment: the only uppercase style in the app.
    func microLabelStyle(_ color: Color = .textSecondary) -> some View {
        self.font(.microLabel)
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Masthead treatment for screen titles.
    func displayXLStyle() -> some View {
        self.font(.displayXL)
            .kerning(-1.0)
            .foregroundStyle(.textPrimary)
    }
}
