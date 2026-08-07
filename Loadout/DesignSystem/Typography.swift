import SwiftUI

// OBSIDIAN type scale — STYLE_GUIDE.md §2.
// Words: SF Pro. Food numbers: SF Rounded, monospaced digits, always.
nonisolated extension Font {
    // MARK: Words
    static let displayXL    = Font.system(size: 34, weight: .heavy)
    static let displayTitle = Font.system(size: 26, weight: .bold)
    static let appHeadline  = Font.system(size: 17, weight: .semibold)
    static let appBody      = Font.system(size: 16, weight: .regular)
    static let appCaption   = Font.system(size: 12, weight: .medium)
    static let microLabel   = Font.system(size: 11, weight: .semibold)

    // MARK: Numerals (rounded + monospacedDigit so values tick in place
    // through .contentTransition(.numericText()) without lateral shift)
    static let numeralHero  = Font.system(size: 44, design: .rounded).weight(.bold).monospacedDigit()
    static let numeralLarge = Font.system(size: 24, design: .rounded).weight(.semibold).monospacedDigit()
    static let numeral      = Font.system(size: 17, design: .rounded).weight(.semibold).monospacedDigit()
    /// Four macros across a card that also carries an icon and a chevron do not
    /// fit at 17 pt, and a wrapped number is worse than a small one — "817"
    /// breaking to "81 / 7" reads as a different meal. Deliberately below the
    /// 16 pt body floor: dense numeric rows are scanned, not read.
    static let numeralCompact = Font.system(size: 14, design: .rounded).weight(.semibold).monospacedDigit()
}

extension View {
    /// STYLE_GUIDE §2: numerals never wrap and never truncate. They shrink.
    /// Every food number in the app goes through this.
    func numeralFitting(_ minimumScale: CGFloat = 0.7) -> some View {
        self.lineLimit(1)
            .minimumScaleFactor(minimumScale)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    /// `microLabel` treatment: the only uppercase style in the app.
    func microLabelStyle(_ color: Color = .textSecondary) -> some View {
        self.font(.microLabel)
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Masthead treatment for screen titles. Shrinks rather than wrapping —
    /// "Moe's Southwest Grill" at full size would otherwise take three lines
    /// and push the whole menu below the fold.
    func displayXLStyle() -> some View {
        self.font(.displayXL)
            .kerning(-1.0)
            .foregroundStyle(.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
    }
}
