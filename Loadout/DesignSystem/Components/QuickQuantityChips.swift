import SwiftUI

/// One-tap absolute-set quantity selector for the meal tray. Replaces
/// the +/- stepper for the common path: 0.5 / 1 / 1.5 / 2 servings.
/// Beyond-preset values (3+) are still reachable by re-tapping the menu
/// row (which adds +1 in the builder); the bound `value` displays
/// outside the chips when current ≠ any preset.
///
/// Tapping the currently-selected chip a second time leaves it set —
/// chips are absolute, not toggle. For "remove from meal", swipe the
/// row (handled at the parent List level).
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
        .accessibilityLabel("Quantity")
    }

    private func chip(_ preset: Double) -> some View {
        let isSelected = abs(value - preset) < 0.001
        return Button {
            value = preset
        } label: {
            Text(preset, format: .number.precision(.fractionLength(0...1)))
                .font(.appCaption.weight(.semibold))
                .frame(minWidth: 28, minHeight: 28)
                .padding(.horizontal, Spacing.xs)
                .background(
                    isSelected ? Color.appAccent : Color.appSecondaryText.opacity(0.12),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .appPrimaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set to \(preset, format: .number.precision(.fractionLength(0...1)))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
