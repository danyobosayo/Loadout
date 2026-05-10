import SwiftUI

struct QuantityStepper: View {
    @Binding var value: Double
    var step: Double = 1
    var range: ClosedRange<Double> = 0...10

    var body: some View {
        HStack(spacing: Spacing.sm) {
            stepButton(systemImage: "minus", disabled: value <= range.lowerBound) {
                value = max(range.lowerBound, value - step)
            }

            Text(value, format: .number.precision(.fractionLength(0...1)))
                .font(.macroNumeric)
                .foregroundStyle(.appPrimaryText)
                .frame(minWidth: 36)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.2), value: value)

            stepButton(systemImage: "plus", disabled: value >= range.upperBound) {
                value = min(range.upperBound, value + step)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quantity")
        .accessibilityValue(Text(value, format: .number.precision(.fractionLength(0...1))))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }

    private func stepButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .disabled(disabled)
    }
}
