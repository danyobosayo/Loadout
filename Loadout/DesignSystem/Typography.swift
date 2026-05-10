import SwiftUI

extension Font {
    static let appLargeTitle = Font.system(.largeTitle, weight: .bold)
    static let appTitle = Font.system(.title2, weight: .semibold)
    static let appHeadline = Font.system(.headline)
    static let appBody = Font.system(.body)
    static let appCaption = Font.system(.caption, weight: .medium)

    // SF Rounded for macro numerals — same family Apple uses for the
    // Activity rings on Apple Watch. Rounded numerals read at-a-glance,
    // which is the entire job of the totals on every screen.
    // monospacedDigit so the figure doesn't shift sideways as it ticks
    // through `.contentTransition(.numericText())`.
    static let macroNumeric = Font.system(.title3, design: .rounded)
        .weight(.semibold)
        .monospacedDigit()

    static let macroDisplay = Font.system(.largeTitle, design: .rounded)
        .weight(.bold)
        .monospacedDigit()

    static let macroLabel = Font.system(.caption, design: .rounded)
        .weight(.medium)
}
