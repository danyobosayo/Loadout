import SwiftUI

/// The macro quartet — kcal, P, C, F in fixed semantic order.
struct MacroBar: View {
    let macros: Macros
    var style: MacroDisplay.Style = .hero

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: style == .hero ? Spacing.lg : Spacing.md) {
            MacroDisplay(kind: .calories, value: macros.calories, style: style)
            MacroDisplay(kind: .protein, value: macros.proteinGrams, style: style)
            MacroDisplay(kind: .carbs, value: macros.carbGrams, style: style)
            MacroDisplay(kind: .fat, value: macros.fatGrams, style: style)
        }
    }
}

/// Stacked capsule showing each macro's share of calories (4/4/9).
/// Re-proportions on `Motion.glide` as the meal changes.
struct MacroSegmentBar: View {
    let macros: Macros
    var height: CGFloat = 6

    private var energyFromMacros: Double {
        macros.proteinGrams * 4 + macros.carbGrams * 4 + macros.fatGrams * 9
    }

    private var shares: (p: Double, c: Double, f: Double) {
        let p = macros.proteinGrams * 4
        let c = macros.carbGrams * 4
        let f = macros.fatGrams * 9
        let total = max(p + c + f, 0.001)
        return (p / total, c / total, f / total)
    }

    var body: some View {
        GeometryReader { geo in
            if energyFromMacros < 0.5 {
                // No macros yet — a neutral hairline instead of the fat
                // capsule filling the remainder and reading as 100% fat.
                Capsule().fill(Color.hairline)
            } else {
                HStack(spacing: 2) {
                    Capsule().fill(Color.protein)
                        .frame(width: max(geo.size.width * shares.p - 2, 0))
                    Capsule().fill(Color.carbs)
                        .frame(width: max(geo.size.width * shares.c - 2, 0))
                    Capsule().fill(Color.fat)
                }
                .animation(Motion.glide, value: macros)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let s = shares
        return "Calorie split: \(Int(s.p * 100)) percent protein, \(Int(s.c * 100)) percent carbs, \(Int(s.f * 100)) percent fat"
    }
}

/// Compact single-line readout for dense rows: calories carry the
/// line; P/C/F trail as quiet color-keyed pairs. The full quartet
/// (`MacroBar`) lives in the tray, where decisions get reviewed.
struct MacroStrip: View {
    let macros: Macros

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm + Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(macros.calories, format: .number.precision(.fractionLength(0)))
                    .font(.numeral)
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText(value: macros.calories))
                    .animation(Motion.snap, value: macros.calories)
                Text("kcal")
                    .microLabelStyle(.kcal)
            }
            pair(macros.proteinGrams, "P", .protein)
            pair(macros.carbGrams, "C", .carbs)
            pair(macros.fatGrams, "F", .fat)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(Int(macros.calories.rounded())) calories, \(Int(macros.proteinGrams.rounded())) protein, \(Int(macros.carbGrams.rounded())) carbs, \(Int(macros.fatGrams.rounded())) fat"
        )
    }

    private func pair(_ value: Double, _ letter: String, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value, format: .number.precision(.fractionLength(0...1)))
                .font(.system(size: 13, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(.textSecondary)
                .contentTransition(.numericText(value: value))
                .animation(Motion.snap, value: value)
            Text(letter)
                .microLabelStyle(color)
        }
    }
}
