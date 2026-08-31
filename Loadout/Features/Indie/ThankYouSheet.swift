import StoreKit
import SwiftUI

/// A short note from the person who made this, shown once, on the visit after
/// someone logs their first meal.
///
/// Deliberately not a growth surface. There is one action and it is dismissal;
/// the review ask sits below it and is phrased so that "no" is a normal answer.
/// A modal that appears once and asks for nothing you have to give is the only
/// kind worth putting in front of someone.
struct ThankYouSheet: View {
    let onDismiss: () -> Void

    @Environment(AppreciationStore.self) private var appreciation
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Thanks for using Loadout")
                    .font(.displayTitle)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("""
                You logged your first meal — which means this thing actually works \
                for someone other than me.

                Loadout is a passion project. I built it because I got tired of \
                guessing at macros standing in line, and every menu in it was \
                checked by hand against what the restaurant publishes. Knowing \
                people are out there using it genuinely makes my week.

                Thank you. Seriously.
                """)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.sm) {
                if appreciation.canRequestReview {
                    Button("Leave a review") { leaveReview() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Maybe later") { dismiss() }
                        .buttonStyle(GhostButtonStyle())
                } else {
                    Button("Close") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Backdrop())
        .onAppear { appreciation.markThankYouShown() }
    }

    private func leaveReview() {
        Haptics.success()
        appreciation.markReviewRequested()
        // Before the App Store listing exists there is nothing to open, so fall
        // back to the system prompt — which may decline to appear, and that is
        // fine. Nothing here tells the user a review sheet is guaranteed.
        if let url = IndieLinks.writeReviewURL {
            openURL(url)
        } else {
            requestReview()
        }
        dismiss()
    }

    private func dismiss() {
        Haptics.tap()
        onDismiss()
    }
}
