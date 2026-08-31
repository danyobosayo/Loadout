import XCTest

/// The "one person made this" surfaces. They're small, and precisely because
/// they're small they're the kind of thing that silently breaks — a sheet that
/// doesn't open, a button that points nowhere.
final class IndieSurfacesUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
        app.launchArguments += ["-loadout.debug.resetProfile", "YES"]
        app.launchArguments += ["-loadout.debug.resetLibrary", "YES"]
        app.launch()
        return app
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    /// All four tabs stay mounted so scroll positions survive tab hops, which
    /// means `exists` is true for Settings content while you're looking at the
    /// Build tab. Every check here is on `isHittable` — the only property that
    /// can tell the screens apart — otherwise these tests pass on the wrong one.
    @MainActor
    private func openSettings(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        app.buttons["Settings"].tap()
        // Not the masthead: SwiftUI merges its eyebrow and title into one
        // element labelled "Tune it, Settings", so an exact match on either half
        // silently never resolves. "Daily target" is a plain, Settings-only row.
        let masthead = app.staticTexts["Daily target"]
        XCTAssertTrue(waitUntilHittable(masthead), "Settings tab never came forward", file: file, line: line)

        let hello = app.staticTexts["Say hello"]
        var scrolls = 0
        while !hello.isHittable && scrolls < 12 { app.swipeUp(); scrolls += 1 }
        XCTAssertTrue(hello.isHittable, "Settings should carry a Say hello section", file: file, line: line)
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 8) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable { return true }
            // A real pause, not `waitForExistence` — that returns instantly once
            // the element exists, which turns this into a hot spin loop.
            Thread.sleep(forTimeInterval: 0.15)
        }
        return false
    }

    @MainActor
    func testSettingsOffersFeedbackAndARestaurantRequest() throws {
        let app = launchedApp()
        openSettings(app)
        attach(app, "01-say-hello")

        XCTAssertTrue(app.buttons["Request a restaurant"].isHittable)
        XCTAssertTrue(app.buttons["Send feedback"].isHittable)
        // No App Store listing exists yet, so nothing may offer to open one.
        XCTAssertFalse(app.buttons["Leave a review"].exists,
                       "A review link must stay hidden until there's an app to review")
    }

    @MainActor
    func testRequestingARestaurantNeedsANameBeforeItCanSend() throws {
        let app = launchedApp()
        openSettings(app)
        app.buttons["Request a restaurant"].tap()

        XCTAssertTrue(app.navigationBars["Request a restaurant"].waitForExistence(timeout: 5))
        let send = app.buttons["Send request"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        XCTAssertFalse(send.isEnabled, "Send should stay disabled until a restaurant is named")
        attach(app, "02-request-empty")

        app.textFields["e.g. Sweetgreen"].tap()
        app.typeText("Shake Shack")
        XCTAssertTrue(send.isEnabled, "Naming a restaurant should enable Send")
        attach(app, "03-request-filled")

        // Deliberately not tapping Send — it hands off to Mail, which would
        // leave the simulator in another app for every later test class.
        app.buttons["Cancel"].tap()
        XCTAssertTrue(waitUntilHittable(app.staticTexts["Say hello"]))
    }

    /// The thank-you note must not ambush someone who just opened the app.
    @MainActor
    func testNoThankYouNoteBeforeAnyMealIsLogged() throws {
        let app = launchedApp()
        XCTAssertFalse(app.staticTexts["Thanks for using Loadout"].waitForExistence(timeout: 3),
                       "The note is for people who've actually logged something")
    }
}
