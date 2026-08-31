import Foundation
import Observation

/// When — and whether — to say thank you, and when to ask for a review.
///
/// The rule the whole type exists to enforce: **never interrupt someone in the
/// middle of doing the thing.** The note appears on a *later* visit, once a
/// first meal has actually been logged, so it lands on someone who came back
/// rather than someone mid-order. It shows once, ever.
@MainActor
@Observable
final class AppreciationStore {
    private let defaults: UserDefaults

    /// When the first meal was logged. Nil until it happens — the note is
    /// pointless before someone has got value out of the app.
    private(set) var firstMealLoggedAt: Date?
    private(set) var hasShownThankYou: Bool
    private(set) var lastReviewRequestAt: Date?

    /// Set when the app becomes active. The note fires only when the first log
    /// predates the current activation, which is what "on re-entering the app"
    /// actually means — logging a meal must never pop a thank-you a second later.
    private var activatedAt = Date.distantFuture

    /// Apple allows three review prompts a year and silently swallows the rest.
    /// Spending one on someone who just installed the app wastes it, so we hold
    /// off until there is real usage behind the ask.
    private static let reviewCooldown: TimeInterval = 120 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        if defaults.bool(forKey: "loadout.debug.resetProfile") {
            for key in [Keys.firstMealLoggedAt, Keys.hasShownThankYou, Keys.lastReviewRequestAt] {
                defaults.removeObject(forKey: key)
            }
        }
        #endif
        let stamp = defaults.double(forKey: Keys.firstMealLoggedAt)
        self.firstMealLoggedAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
        self.hasShownThankYou = defaults.bool(forKey: Keys.hasShownThankYou)
        let review = defaults.double(forKey: Keys.lastReviewRequestAt)
        self.lastReviewRequestAt = review > 0 ? Date(timeIntervalSince1970: review) : nil
    }

    /// Call on every successful log. Only the first one is recorded.
    func recordMealLogged(at date: Date = Date()) {
        guard firstMealLoggedAt == nil else { return }
        firstMealLoggedAt = date
        defaults.set(date.timeIntervalSince1970, forKey: Keys.firstMealLoggedAt)
    }

    func markActive(at date: Date = Date()) {
        activatedAt = date
    }

    /// True when this activation should show the thank-you note.
    var shouldShowThankYou: Bool {
        guard !hasShownThankYou, let firstMealLoggedAt else { return false }
        return firstMealLoggedAt < activatedAt
    }

    func markThankYouShown() {
        hasShownThankYou = true
        defaults.set(true, forKey: Keys.hasShownThankYou)
    }

    /// Whether it's reasonable to put the system review prompt on screen. The
    /// prompt itself may still decide not to appear — that's Apple's call, and
    /// the reason no UI ever promises it will.
    var canRequestReview: Bool {
        guard let lastReviewRequestAt else { return true }
        return Date().timeIntervalSince(lastReviewRequestAt) > Self.reviewCooldown
    }

    func markReviewRequested(at date: Date = Date()) {
        lastReviewRequestAt = date
        defaults.set(date.timeIntervalSince1970, forKey: Keys.lastReviewRequestAt)
    }

    private enum Keys {
        static let firstMealLoggedAt = "loadout.appreciation.firstMealLoggedAt"
        static let hasShownThankYou = "loadout.appreciation.hasShownThankYou"
        static let lastReviewRequestAt = "loadout.appreciation.lastReviewRequestAt"
    }
}
