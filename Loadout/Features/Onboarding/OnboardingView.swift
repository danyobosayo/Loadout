import SwiftUI

/// First-launch screen explaining the MacroFactor Shortcut handoff.
/// Per PROJECT.md §13 #4: one screen, install link, skip button. Tap
/// "Install Shortcut" opens the MacroFactor apple-shortcuts repo
/// without dismissing — the user comes back to tap "Continue" once
/// they've installed it. Either Continue or Skip dismisses and marks
/// onboarding complete; we don't track the choice (just whether the
/// screen ran), since the export flow itself surfaces the install link
/// via Settings if it ends up being needed later.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let macroFactorShortcutsURL = URL(
        string: "https://github.com/MacroFactor/apple-shortcuts"
    )!

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text("🍽️")
                    .font(.system(size: 72))
                    .accessibilityHidden(true)
                Text("Build a meal,\nlog it in seconds.")
                    .font(.appLargeTitle)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                bullet(
                    title: "Build at the counter.",
                    body: "Pick what's on your tray. Loadout shows live macros as you go — no more guessing before you order."
                )
                bullet(
                    title: "One tap to MacroFactor.",
                    body: "Loadout hands the meal to MacroFactor's “Log by JSON” Shortcut. Install it once and every meal lands in your log."
                )
                bullet(
                    title: "Stays on your phone.",
                    body: "No accounts. No analytics. Favorites and history live on this device only."
                )
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    openURL(Self.macroFactorShortcutsURL)
                } label: {
                    Label("Install MacroFactor Shortcut", systemImage: "arrow.up.right.square")
                        .font(.appHeadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Continue") {
                    dismiss()
                }
                .font(.appBody)
                .padding(.vertical, Spacing.xs)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    private func bullet(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.appHeadline)
            Text(body)
                .font(.appBody)
                .foregroundStyle(.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
