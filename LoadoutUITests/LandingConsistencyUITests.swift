import XCTest

/// Every restaurant's landing screen must answer "what are you having?" with
/// something you'd actually order — never with nothing but "Build your own".
///
/// Two shapes are legitimate. A restaurant that sells finished things lists them
/// directly (Cane's combos, Chick-fil-A sandwiches). A restaurant with a big
/// menu names the kind first (Panera's "Sandwich or Salad" prompts straight onto
/// its 31 sandwiches). What is NOT legitimate is the items being reachable only
/// through the build-your-own escape hatch, which is how Cane's and Chick-fil-A
/// used to be.
final class LandingConsistencyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES",
                                "-loadout.debug.resetProfile", "YES",
                                "-loadout.debug.resetLibrary", "YES"]
        app.launch()
        return app
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    /// Panera's sandwiches are one labelled tap away, not behind Build your own.
    @MainActor
    func testPaneraNamesTheKindThenListsTheDishes() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Panera Bread,")

        let kind = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sandwich or Salad")).firstMatch
        XCTAssertTrue(kind.waitForExistence(timeout: 15),
                      "Panera should name the kind of dish on its landing screen")
        attach(app, "01-panera-landing")
        kind.tap()

        let sandwich = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Chicken Bacon Rancher")
        ).firstMatch
        XCTAssertTrue(sandwich.waitForExistence(timeout: 12),
                      "picking the kind should list the actual sandwiches")
        attach(app, "02-panera-dishes")
    }

    /// The guard that matters: no restaurant may offer *only* build-your-own.
    @MainActor
    func testNoRestaurantOffersOnlyBuildYourOwn() throws {
        let app = launchedApp()
        for name in ["Raising Cane's,", "Chick-fil-A,", "Panera Bread,", "Qdoba Mexican Eats,"] {
            app.buttons["Build"].tap()
            app.tapRestaurant(name)

            // Something orderable has to be on screen besides the escape hatch.
            let hasHeadline = app.buttons.matching(
                NSPredicate(format: "label CONTAINS %@", "KCAL")
            ).firstMatch.waitForExistence(timeout: 12)
            let hasFormat = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", "Sandwich")
            ).firstMatch.exists
                || app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", "Signature")
                ).firstMatch.exists
                || app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", "Burrito")
                ).firstMatch.exists

            XCTAssertTrue(hasHeadline || hasFormat,
                          "\(name) landing offers nothing to order but Build your own")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
