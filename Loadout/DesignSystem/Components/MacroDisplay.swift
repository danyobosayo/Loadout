import SwiftUI

struct MacroDisplay: View {
    enum Style {
        case hero    // top-of-screen totals
        case inline  // per-item readouts
    }

    enum Kind {
        case calories, protein, carbs, fat

        var label: String {
            switch self {
            case .calories: "kcal"
            case .protein: "P"
            case .carbs: "C"
            case .fat: "F"
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
    }

    let kind: Kind
    let value: Double
    var style: Style = .hero

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(style == .hero ? .macroDisplay : .macroNumeric)
                .foregroundStyle(.appPrimaryText)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.25), value: value)
            Text(kind.label)
                .font(.macroLabel)
                .foregroundStyle(.appSecondaryText)
                .textCase(.uppercase)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(value.rounded())) \(kind.voiceOverUnit)")
    }
}
