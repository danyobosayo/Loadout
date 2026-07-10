import XCTest

/// Budget Mode: with a daily target set, the builder shows how the meal fits.
final class BudgetModeUITests: XCTestCase {
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
    func testBudgetModeShowsFit() throws {
        let app = launchedApp()

        // 1. Set a daily target (2200 / 180 / 200 / 60), clearing any prefill.
        app.buttons["Settings"].tap()
        app.buttons["dailyTargetCard"].tap()
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

        // 2. Build a meal.
        app.buttons["Build"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chipotle,")).firstMatch.tap()
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15)); byo.tap()
        app.buttons["Protein station"].tap()
        let chicken = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chicken,")).firstMatch
        XCTAssertTrue(chicken.waitForExistence(timeout: 8)); chicken.tap()

        // 3. Tray bar shows the fit ("N kcal left").
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "kcal left")).firstMatch.waitForExistence(timeout: 5),
                      "Tray bar should show budget headroom")
        attach(app, "01-traybar-budget")

        // 4. Open the tray → the Budget Mode fit card.
        tray.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "kcal left")).firstMatch.waitForExistence(timeout: 5),
                      "Tray should show the Budget Mode fit")
        attach(app, "02-tray-budget-fit")

        // Expand the sheet so the full per-macro gauge card is visible.
        app.swipeUp()
        attach(app, "03-tray-budget-full")
    }
}
