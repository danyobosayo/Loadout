import SwiftUI
import UIKit

// OBSIDIAN type scale — STYLE_GUIDE.md §2.
// Words: SF Pro. Food numbers: SF Rounded, monospaced digits, always.
/// The app's type scale honours the system text size, but stops at xxLarge.
///
/// Every size here was chosen against dense numeric rows — four macros, an icon
/// and a chevron on one line — and those rows cannot survive the accessibility
/// sizes without stacking vertically, which would turn one combo into most of a
/// screen. So the scale follows the setting through the range people actually
/// use to make text a notch bigger, and clamps above it.
///
/// The clamp is applied *inside* the metric rather than by `.dynamicTypeSize()`
/// at the root: that modifier bounds the SwiftUI environment, but `UIFontMetrics`
/// reads UIKit's trait collection, and relying on the two staying in step is how
/// a cap silently stops working. `scaledValue(for:compatibleWith:)` takes the
/// trait collection explicitly, so the ceiling is not a matter of trust.
private let maximumContentSize: UIContentSizeCategory = .extraExtraLarge

@MainActor
private func obsidianScaled(_ size: CGFloat, _ style: UIFont.TextStyle) -> CGFloat {
    let category = min(UITraitCollection.current.preferredContentSizeCategory, maximumContentSize)
    return UIFontMetrics(forTextStyle: style).scaledValue(
        for: size,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: category)
    )
}

// @MainActor rather than nonisolated: the scale reads UIKit's trait
// collection, and these fonts are only ever resolved during view body
// evaluation, which is already on the main actor.
@MainActor extension Font {
    // MARK: Words
    static var displayXL: Font    { .system(size: obsidianScaled(34, .largeTitle), weight: .heavy) }
    static var displayTitle: Font { .system(size: obsidianScaled(26, .title1), weight: .bold) }
    static var appHeadline: Font  { .system(size: obsidianScaled(17, .headline), weight: .semibold) }
    static var appBody: Font      { .system(size: obsidianScaled(16, .body), weight: .regular) }
    static var appCaption: Font   { .system(size: obsidianScaled(12, .caption1), weight: .medium) }
    static var microLabel: Font   { .system(size: obsidianScaled(11, .caption2), weight: .semibold) }

    // MARK: Numerals (rounded + monospacedDigit so values tick in place
    // through .contentTransition(.numericText()) without lateral shift)
    static var numeralHero: Font  { .system(size: obsidianScaled(44, .largeTitle), design: .rounded).weight(.bold).monospacedDigit() }
    static var numeralLarge: Font { .system(size: obsidianScaled(24, .title2), design: .rounded).weight(.semibold).monospacedDigit() }
    static var numeral: Font      { .system(size: obsidianScaled(17, .headline), design: .rounded).weight(.semibold).monospacedDigit() }
    /// Four macros across a card that also carries an icon and a chevron do not
    /// fit at 17 pt, and a wrapped number is worse than a small one — "817"
    /// breaking to "81 / 7" reads as a different meal. Deliberately below the
    /// 16 pt body floor: dense numeric rows are scanned, not read.
    static var numeralCompact: Font { .system(size: obsidianScaled(14, .footnote), design: .rounded).weight(.semibold).monospacedDigit() }
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
