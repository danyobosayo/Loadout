import XCTest

/// Dietary restrictions set in Settings must show up where you're actually
/// choosing food — the station rows — not only inside auto-build.
final class DietaryUITests: XCTestCase {
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
    private func enableVegetarian(_ app: XCUIApplication) {
        app.buttons["Settings"].tap()
        let toggle = app.switches["dietaryRestriction.vegetarian"]
        var scrolls = 0
        while !toggle.exists && scrolls < 12 { app.swipeUp(); scrolls += 1 }
        XCTAssertTrue(toggle.waitForExistence(timeout: 8), "Settings should offer a vegetarian toggle")
        if (toggle.value as? String) != "1" { toggle.tap() }
        attach(app, "01-dietary-settings")
    }

    @MainActor
    func testRestrictionMarksConflictingItemsInTheMenu() throws {
        let app = launchedApp()
        enableVegetarian(app)

        app.buttons["Build"].tap()
        app.tapRestaurant("Chipotle,")
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15))
        byo.tap()

        app.buttons["Protein station"].tap()
        // Chicken is meat, so a vegetarian sees it marked — and can still tap it.
        let chicken = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chicken,")).firstMatch
        XCTAssertTrue(chicken.waitForExistence(timeout: 8))
        XCTAssertTrue(chicken.label.contains("fit your diet settings"),
                      "Chicken should be marked for a vegetarian — got: \(chicken.label)")
        attach(app, "02-marked-in-menu")

        // Sofritas is vegan, so it carries no marking.
        let sofritas = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sofritas,")).firstMatch
        if sofritas.exists {
            XCTAssertFalse(sofritas.label.contains("fit your diet settings"),
                           "Sofritas should be fine for a vegetarian — got: \(sofritas.label)")
        }
    }

    /// The marking is advisory. Only the person ordering knows how strict their
    /// rule is today, so a conflicting item stays tappable.
    @MainActor
    func testAConflictingItemIsStillSelectable() throws {
        let app = launchedApp()
        enableVegetarian(app)

        app.buttons["Build"].tap()
        app.tapRestaurant("Chipotle,")
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15))
        byo.tap()

        app.buttons["Protein station"].tap()
        let chicken = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chicken,")).firstMatch
        XCTAssertTrue(chicken.waitForExistence(timeout: 8))
        chicken.tap()

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5) && tray.label.contains("1 item"),
                      "A marked item must still be selectable — tray: \(tray.label)")
    }
}
