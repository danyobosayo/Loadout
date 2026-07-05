import SwiftUI

/// First launch — the pitch, the Shortcut install link, and out.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let macroFactorShortcutsURL = URL(
        string: "https://github.com/MacroFactor/apple-shortcuts"
    )!

    var body: some View {
        ZStack {
            Backdrop(tint: .volt)

            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    Text("L")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.void)
                        .frame(width: 84, height: 84)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .fill(Color.volt)
                        }
                        .accessibilityHidden(true)
                        .entrance(0)

                    Text("Know your macros\nbefore you order.")
                        .font(.displayTitle)
                        .kerning(-0.5)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                        .entrance(1)
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    bullet(
                        index: 2,
                        icon: "fork.knife",
                        title: "Build at the counter.",
                        body: "Pick what's going on your tray. Live macros tick as you assemble."
                    )
                    bullet(
                        index: 3,
                        icon: "bolt.fill",
                        title: "One tap to MacroFactor.",
                        body: "Loadout hands the meal to the \u{201C}Log by JSON\u{201D} Shortcut. Install once, log forever."
                    )
                    bullet(
                        index: 4,
                        icon: "lock.fill",
                        title: "Stays on your phone.",
                        body: "No accounts, no analytics. Recipes and history live on this device only."
                    )
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button {
                        openURL(Self.macroFactorShortcutsURL)
                    } label: {
                        Label("Install MacroFactor Shortcut", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.primaryAction)

                    Button("Continue") {
                        dismiss()
                    }
                    .buttonStyle(.ghost)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
                .entrance(5)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bullet(index: Int, icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.volt)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.volt.opacity(0.1)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Text(body)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .entrance(index)
    }
}
