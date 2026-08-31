import Foundation
import Testing
@testable import Loadout

/// The thank-you note has exactly one job and one failure mode: appearing at the
/// wrong moment. Logging a meal and being immediately interrupted by a modal
/// asking for a review is the thing this must never do.
@MainActor
struct AppreciationTests {
    private func store() -> (AppreciationStore, UserDefaults) {
        let suite = UserDefaults(suiteName: "loadout.tests.\(UUID().uuidString)")!
        return (AppreciationStore(defaults: suite), suite)
    }

    @Test func saysNothingBeforeAnyMealIsLogged() {
        let (appreciation, _) = store()
        appreciation.markActive()
        #expect(!appreciation.shouldShowThankYou)
    }

    /// The whole point: the note must not fire in the session that earned it.
    @Test func doesNotInterruptTheSessionThatLoggedTheFirstMeal() {
        let (appreciation, _) = store()
        appreciation.markActive(at: Date())
        appreciation.recordMealLogged(at: Date().addingTimeInterval(30))
        #expect(!appreciation.shouldShowThankYou)
    }

    @Test func appearsOnTheNextVisit() {
        let (appreciation, _) = store()
        let launch = Date()
        appreciation.markActive(at: launch)
        appreciation.recordMealLogged(at: launch.addingTimeInterval(30))
        #expect(!appreciation.shouldShowThankYou)

        // Come back later.
        appreciation.markActive(at: launch.addingTimeInterval(3600))
        #expect(appreciation.shouldShowThankYou)
    }

    @Test func appearsOnceAndNeverAgain() {
        let (appreciation, defaults) = store()
        let launch = Date()
        appreciation.markActive(at: launch)
        appreciation.recordMealLogged(at: launch)
        appreciation.markActive(at: launch.addingTimeInterval(3600))
        #expect(appreciation.shouldShowThankYou)

        appreciation.markThankYouShown()
        #expect(!appreciation.shouldShowThankYou)

        // …including across launches.
        let relaunched = AppreciationStore(defaults: defaults)
        relaunched.markActive(at: launch.addingTimeInterval(7200))
        #expect(!relaunched.shouldShowThankYou)
    }

    /// Only the first log counts — the note is about the moment the app first
    /// worked for someone, not the most recent meal.
    @Test func onlyTheFirstMealIsRecorded() {
        let (appreciation, _) = store()
        let first = Date()
        appreciation.recordMealLogged(at: first)
        appreciation.recordMealLogged(at: first.addingTimeInterval(9999))
        #expect(appreciation.firstMealLoggedAt == first)
    }

    @Test func theFirstMealSurvivesRelaunch() {
        let (appreciation, defaults) = store()
        let logged = Date(timeIntervalSince1970: 1_700_000_000)
        appreciation.recordMealLogged(at: logged)

        let relaunched = AppreciationStore(defaults: defaults)
        #expect(relaunched.firstMealLoggedAt == logged)
    }

    // MARK: Review prompt

    /// Apple grants three prompts a year and silently drops the rest, so asking
    /// again soon spends a scarce thing on someone who already said no. The
    /// cooldown is deliberately long — four months, not a week.
    @Test func doesNotAskForAReviewAgainSoon() {
        let (appreciation, _) = store()
        #expect(appreciation.canRequestReview)

        appreciation.markReviewRequested(at: Date())
        #expect(!appreciation.canRequestReview)
    }

    @Test func asksAgainOnlyAfterTheCooldown() {
        let (appreciation, _) = store()
        appreciation.markReviewRequested(at: Date().addingTimeInterval(-200 * 24 * 60 * 60))
        #expect(appreciation.canRequestReview)
    }

    // MARK: Links

    /// Nothing may point at an App Store listing that doesn't exist yet.
    @Test func noAppStoreLinkUntilThereIsAnApp() {
        #expect(IndieLinks.isPublished == (IndieLinks.appStoreId != nil))
        if !IndieLinks.isPublished {
            #expect(IndieLinks.writeReviewURL == nil)
        }
    }

    /// "Raising Cane's" has an apostrophe, which is exactly what breaks a
    /// hand-built mailto string.
    @Test func aRestaurantRequestSurvivesPunctuation() throws {
        let url = try #require(IndieLinks.restaurantRequest("Raising Cane's", note: "Box combo & fries"))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "mailto")
        #expect(components.path == IndieLinks.feedbackEmail)

        let subject = components.queryItems?.first { $0.name == "subject" }?.value
        let body = components.queryItems?.first { $0.name == "body" }?.value
        #expect(subject == "Restaurant request: Raising Cane's")
        #expect(body?.contains("Raising Cane's") == true)
        #expect(body?.contains("Box combo & fries") == true)
    }

    @Test func anEmptyNoteIsLeftOutRatherThanSentAsBlankLines() throws {
        let url = try #require(IndieLinks.restaurantRequest("Sweetgreen", note: "   "))
        let body = try #require(
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "body" }?.value
        )
        #expect(!body.contains("\n\n\n"))
        #expect(body.hasPrefix("I'd love to see Sweetgreen in Loadout."))
    }
}
