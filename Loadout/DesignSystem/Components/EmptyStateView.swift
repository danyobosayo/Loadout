import SwiftUI

/// Designed empty state — STYLE_GUIDE.md §7. Icon in a glowing hue
/// circle, a title, and exactly one actionable line of copy. Replaces
/// system `ContentUnavailableView` on every styled screen.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var tint: Color = .volt

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(tint)
            }
            .entrance(0)

            Text(title)
                .font(.displayTitle)
                .kerning(-0.5)
                .foregroundStyle(.textPrimary)
                .entrance(1)

            Text(message)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .entrance(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
