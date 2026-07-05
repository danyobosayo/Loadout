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
            Text(value, format: format)
                .font(.numeral)
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText(value: value))
                .animation(Motion.snap, value: value)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(value.rounded())) \(kind.voiceOverUnit)")
    }

    private var format: FloatingPointFormatStyle<Double> {
        // Calories: integer. Grams: one decimal max — STYLE_GUIDE.md §7.
        kind == .calories
            ? .number.precision(.fractionLength(0))
            : .number.precision(.fractionLength(0...1))
    }
}
