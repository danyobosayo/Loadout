import SwiftUI

/// Primary CTA — a solid volt capsule with void ink. No gradient, no
/// glow; emphasis comes from being the only saturated fill in the
/// region (STYLE_GUIDE.md §1.2). Press compresses on `Motion.tap`.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundStyle(Color.void)
            .padding(.vertical, 14)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.volt, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.tap, value: configuration.isPressed)
    }
}

/// Secondary action — hairline capsule, no fill.
struct GhostButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundStyle(.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background {
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.06 : 0.02))
                    .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.tap, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryAction: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}
