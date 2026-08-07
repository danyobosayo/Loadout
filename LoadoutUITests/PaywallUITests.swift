import XCTest

/// A free user (no StoreKit entitlement) hits the paywall at every Pro entry
/// point. Purchase prices need the scheme's StoreKit config, so this verifies
/// the gating + paywall UI, not the transaction.
///
/// Pro currently ships unlocked for everyone, so these launch with
/// `-loadout.debug.forceGating YES` to re-arm the gates and keep the paywall
/// path covered until the App Store Connect products go live.
final class PaywallUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        // Layout-dependent assertions: the simulator is shared, so never
        // inherit another class's rotation.
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
        app.launchArguments += ["-loadout.debug.forceGating", "YES"]
        app.launchArguments += ["-loadout.debug.resetLibrary", "YES"]
        app.launch()
        return app
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    @MainActor
    func testFreeUserIsGatedByPaywall() throws {
        let app = launchedApp()
        app.buttons["Settings"].tap()

        // The Pro upsell shows for free users.
        let unlock = app.buttons["unlockPro"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 8), "Free users should see the Pro upsell")
        unlock.tap()

        // Paywall.
        XCTAssertTrue(app.staticTexts["Daily macro targets"].waitForExistence(timeout: 5), "Paywall should list Pro features")
        attach(app, "01-paywall")
        app.buttons["Close"].tap()

        // Apple Health is Pro → a free user's "Connect" hits the paywall, not the
        // system auth prompt.
        let connect = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Connect Apple Health")).firstMatch
        XCTAssertTrue(connect.waitForExistence(timeout: 5))
        connect.tap()
        XCTAssertTrue(app.staticTexts["Daily macro targets"].waitForExistence(timeout: 5),
                      "A free user tapping Connect Apple Health should hit the paywall")
    }

    /// The shipped default: no launch flags at all, so `unlockedForEveryone`
    /// applies. Every Pro surface is open and the upsell is gone. Flipping the
    /// switch back to gated should fail this test — that's the point.
    @MainActor
    func testProShipsUnlockedForEveryone() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
        // No inherited target — otherwise "Fit my macros" could already be on
        // screen and the assertion would pass without proving anything.
        app.launchArguments += ["-loadout.debug.resetProfile", "YES"]
        // No saved recipes either — "Your recipes" would push the preset and
        // format cards below the fold on the restaurant screen.
        app.launchArguments += ["-loadout.debug.resetLibrary", "YES"]
        app.launch()

        app.buttons["Settings"].tap()

        // No purchase to make → no upsell card.
        let target = app.buttons["dailyTargetCard"]
        XCTAssertTrue(target.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["unlockPro"].exists, "Pro ships unlocked — the upsell shouldn't show")

        // A Pro-only entry point is live without any entitlement: set a target,
        // then "Fit my macros" (gated on `isPro`) appears at the restaurant.
        target.tap()
        XCTAssertTrue(app.staticTexts["Set your macros"].waitForExistence(timeout: 5))
        let manualMode = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "I have my numbers")).firstMatch
        if manualMode.exists { manualMode.tap() }
        func setField(_ id: String, _ value: String) {
            let f = app.textFields[id]
            XCTAssertTrue(f.waitForExistence(timeout: 5), "missing \(id)")
            f.tap()
            f.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8))
            f.typeText(value)
        }
        setField("goalField.Calories", "2200")
        setField("goalField.Protein", "180")
        setField("goalField.Carbs", "200")
        setField("goalField.Fat", "60")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        app.buttons["Save target"].tap()

        app.buttons["Build"].tap()
        app.tapRestaurant("Chipotle,")
        let fit = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Fit my macros")).firstMatch
        XCTAssertTrue(fit.waitForExistence(timeout: 15), "Fit my macros should be available without a purchase")
        attach(app, "02-unlocked-fit-my-macros")
    }
}
