import SwiftUI

/// Hairline capsule ± stepper with a ticking numeral. Half-portion
/// steps — the chips handle the common absolute values, this handles
/// everything else.
struct QuantityStepper: View {
    @Binding var value: Double
    var step: Double = 0.5
    var range: ClosedRange<Double> = 0...10

    var body: some View {
        HStack(spacing: 2) {
            stepButton(systemImage: "minus", disabled: value <= range.lowerBound) {
                withAnimation(Motion.snap) {
                    value = max(range.lowerBound, value - step)
                }
            }

            Text(value, format: .number.precision(.fractionLength(0...2)))
                .font(.numeral)
                .foregroundStyle(.textPrimary)
                .frame(minWidth: 44)
                .contentTransition(.numericText(value: value))
                .animation(Motion.snap, value: value)

            stepButton(systemImage: "plus", disabled: value >= range.upperBound) {
                withAnimation(Motion.snap) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.03))
                .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quantity")
        .accessibilityValue(Text(value, format: .number.precision(.fractionLength(0...2))))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }

    private func stepButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(disabled ? Color.textTertiary : .textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(disabled ? 0.02 : 0.06)))
                .contentShape(Circle())
        }
        .buttonStyle(.pressable)
        .disabled(disabled)
    }
}
