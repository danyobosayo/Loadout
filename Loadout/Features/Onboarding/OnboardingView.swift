import SwiftUI

/// First launch — the pitch + Shortcut install (step 1), then optional daily
/// target setup (step 2), then out. One gate: `RootView`'s cover binding flips
/// `hasCompletedOnboarding` on dismiss, whichever step dismissed.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(ProfileStore.self) private var profile
    @State private var step: Step = .pitch

    private enum Step { case pitch, goal }

    var body: some View {
        ZStack {
            Backdrop(tint: .volt)

            if step == .pitch {
                pitch
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                GoalSetupView(
                    onSave: { goal in
                        profile.goal = goal
                        dismiss()
                    },
                    onSkip: { dismiss() }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .preferredColorScheme(.dark)
    }

    private var pitch: some View {
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
                        body: "Install the Loadout Shortcut once — it passes each meal straight into MacroFactor's log."
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
                        openURL(MacroFactorIntegration.installShortcutURL)
                    } label: {
                        Label("Install the Loadout Shortcut", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.primaryAction)

                    Button("Continue") {
                        withAnimation(Motion.glide) { step = .goal }
                    }
                    .buttonStyle(.ghost)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
                .entrance(5)
            }
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
