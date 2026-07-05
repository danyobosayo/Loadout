import SwiftUI

/// One-tap absolute-set portion presets: ½ · 1 · 1½ · 2. Chips are
/// absolute, not toggles; the stepper alongside covers off-preset
/// values (0.25 granularity). Selected chip fills volt with void text.
struct QuickQuantityChips: View {
    @Binding var value: Double
    var presets: [Double] = [0.5, 1, 1.5, 2]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(presets, id: \.self) { preset in
                chip(preset)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Portion presets")
    }

    private func chip(_ preset: Double) -> some View {
        let isSelected = abs(value - preset) < 0.001
        return Button {
            Haptics.tap()
            withAnimation(Motion.snap) { value = preset }
        } label: {
            Text(preset, format: .number.precision(.fractionLength(0...1)))
                .font(.numeral)
                .frame(minWidth: 30, minHeight: 30)
                .padding(.horizontal, Spacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.volt)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                            .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
                    }
                }
                .foregroundStyle(isSelected ? Color.void : .textPrimary)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Set portion to \(preset, format: .number.precision(.fractionLength(0...1)))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
