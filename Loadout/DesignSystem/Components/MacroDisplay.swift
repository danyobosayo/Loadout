import SwiftUI

/// One macro readout: ticking numeral over a color-matched microLabel.
/// The numeral never teleports — STYLE_GUIDE.md §0 law 2.
struct MacroDisplay: View {
    enum Style {
        case hero    // top-of-tray totals
        case inline  // per-item readouts
    }

    enum Kind {
        case calories, protein, carbs, fat

        var label: String {
            switch self {
            case .calories: "kcal"
            case .protein: "protein"
            case .carbs: "carbs"
            case .fat: "fat"
            }
        }

        var shortLabel: String {
            switch self {
            case .calories: "kcal"
            case .protein: "P"
            case .carbs: "C"
            case .fat: "F"
            }
        }

        var color: Color {
            switch self {
            case .calories: .kcal
            case .protein: .protein
            case .carbs: .carbs
            case .fat: .fat
            }
        }

        var voiceOverUnit: String {
            switch self {
            case .calories: "calories"
            case .protein: "grams protein"
            case .carbs: "grams carbs"
            case .fat: "grams fat"
            }
        }

        var showsGramSuffix: Bool { self != .calories }
    }

    let kind: Kind
    let value: Double
    var style: Style = .hero

    var body: some View {
        switch style {
        case .hero: hero
        case .inline: inline
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value, format: format)
                    .font(.numeralLarge)
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText(value: value))
                    .animation(Motion.snap, value: value)
                    .numeralFitting()
                if kind.showsGramSuffix {
                    Text("g")
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                }
            }
            Text(kind.label)
                .microLabelStyle(kind.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(value.rounded())) \(kind.voiceOverUnit)")
    }

    private var inline: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(kind.shortLabel)
                .microLabelStyle(kind.color)
                .fixedSize()
            Text(value, format: format)
                .font(.numeralCompact)
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText(value: value))
                .animation(Motion.snap, value: value)
                .numeralFitting(0.6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(value.rounded())) \(kind.voiceOverUnit)")
    }

    private var format: FloatingPointFormatStyle<Double> {
        // Calories are always whole. Grams keep one decimal in the hero
        // readout, where a meal gets reviewed, but go whole inline: four
        // values across a card is a scanning context, and ".7" is both noise
        // and the extra glyph that pushed the row into wrapping.
        if kind == .calories || style == .inline {
            return .number.precision(.fractionLength(0))
        }
        return .number.precision(.fractionLength(0...1))
    }
}
