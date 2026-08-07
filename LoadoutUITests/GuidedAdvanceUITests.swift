import XCTest

/// The guided accordion only closes a prompt once it can't take any more.
/// A "choose 2 entrées" plate waits for the second entrée; a base that can
/// still be doubled or split ½ + ½ never closes on its own.
final class GuidedAdvanceUITests: XCTestCase {
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

    @MainActor
    private func row(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    /// Panda's Plate prompts `upTo:2`. The prompt must stay open through the
    /// first entrée — closing there is the bug that made the list jump.
    @MainActor
    func testTwoEntreePromptWaitsForTheSecondPick() throws {
        let app = launchedApp()
        app.tapRestaurant("Panda Express,")

        let plate = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Plate.")).firstMatch
        XCTAssertTrue(plate.waitForExistence(timeout: 15), "Panda should offer a Plate format")
        plate.tap()

        // Open the entrée prompt.
        let prompt = app.staticTexts["Choose 2 entrées"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "Plate should guide two entrées")
        prompt.tap()

        let first = row(app, "Orange Chicken")
        XCTAssertTrue(first.waitForExistence(timeout: 5), "Entrée options should expand")
        first.tap()

        // Still open after one of two — the options remain on screen.
        XCTAssertTrue(row(app, "Black Pepper Chicken").waitForExistence(timeout: 3),
                      "The prompt must stay open until both entrées are picked")
        attach(app, "01-after-first-entree")

        row(app, "Black Pepper Chicken").tap()

        // Saturated → collapses to its summary, so the options go away.
        let summary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Orange Chicken", "Black Pepper Chicken")
        ).firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 5),
                      "A saturated prompt should collapse to its summary")
        attach(app, "02-after-second-entree")
    }

    /// A `selectOne` base can still be doubled or split, so it must not close
    /// on the first tap — that is what made portions unadjustable before.
    @MainActor
    func testSplittableBaseStaysOpenAfterOnePick() throws {
        let app = launchedApp()
        app.tapRestaurant("Chipotle,")

        let burrito = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Burrito.")).firstMatch
        XCTAssertTrue(burrito.waitForExistence(timeout: 15))
        burrito.tap()

        // Rice is expanded on entry and is a splittable choose-one.
        let white = row(app, "Cilantro-Lime White Rice")
        XCTAssertTrue(white.waitForExistence(timeout: 10), "Rice should be expanded on entry")
        white.tap()

        XCTAssertTrue(row(app, "Cilantro-Lime Brown Rice").waitForExistence(timeout: 3),
                      "A splittable base must stay open so it can be doubled or split")
        attach(app, "03-base-stays-open")
    }
}
