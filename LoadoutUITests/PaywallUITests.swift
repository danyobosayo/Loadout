import XCTest

/// A free user (no StoreKit entitlement) hits the paywall at every Pro entry
/// point. Purchase prices need the scheme's StoreKit config, so this verifies
/// the gating + paywall UI, not the transaction.
final class PaywallUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
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
}
