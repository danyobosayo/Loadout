import SwiftUI

/// The calorie gauge — a solid volt arc with rounded caps and
/// ticking numerals at center. With no `target` it
/// renders as a pure gauge: the arc length maps 0…2000 kcal onto
/// 0…100% purely for visual proportion (the number is the data; the
/// arc is the drama). Sweep animates on `Motion.glide` per §4.
struct MacroRing: View {
    let calories: Double
    var target: Double? = nil
    var size: CGFloat = 132
    var lineWidth: CGFloat = 11

    private var progress: Double {
        let denominator = target ?? 2000
        guard denominator > 0 else { return 0 }
        return min(calories / denominator, 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: lineWidth))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.volt, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Motion.glide, value: progress)

            VStack(spacing: 0) {
                Text(calories, format: .number.precision(.fractionLength(0)))
                    .font(size >= 120 ? .numeralHero : .numeralLarge)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText(value: calories))
                    .animation(Motion.snap, value: calories)
                Text("kcal")
                    .microLabelStyle(.kcal)
            }
            // Keep the numerals inside the arc so a 4-digit total (1,170)
            // shrinks to one line instead of wrapping.
            .frame(maxWidth: size - lineWidth * 2 - Spacing.sm)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(calories.rounded())) calories")
    }
}

#Preview {
    ZStack {
        Color.void.ignoresSafeArea()
        MacroRing(calories: 780)
    }
}
