import XCTest

/// The macro-target setup flow — manual entry from Settings, and (Batch D) the
/// onboarding step-2 path.
final class GoalSetupUITests: XCTestCase {
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
    func testOnboardingGoalStepCanBeSkipped() throws {
        let app = XCUIApplication()
        // Force the flag OFF (arg domain outranks the simulator's persisted
        // value), so onboarding shows deterministically on every run.
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "NO"]
        app.launch()

        // Step 1 — the pitch.
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 8), "Onboarding pitch should show")
        attach(app, "05-onboarding-pitch")
        app.buttons["Continue"].tap()

        // Step 2 — the goal setup.
        XCTAssertTrue(app.staticTexts["Set your macros"].waitForExistence(timeout: 5), "Continue should reveal goal setup")
        attach(app, "06-onboarding-goal")

        // Skipping still completes onboarding → restaurant list.
        app.buttons["Skip for now"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "CAVA,")).firstMatch.waitForExistence(timeout: 8),
                      "Skipping should complete onboarding and land on the restaurant list")
    }

    @MainActor
    func testSetTargetManuallyFromSettings() throws {
        let app = launchedApp()
        app.buttons["Settings"].tap()

        let open = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Set your daily target")).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 8), "Settings should offer to set a daily target")
        open.tap()

        // Calculate mode is the default.
        XCTAssertTrue(app.staticTexts["Set your macros"].waitForExistence(timeout: 5))
        attach(app, "01-goal-calculate")

        // Switch to manual entry.
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "I have my numbers")).firstMatch.tap()

        let cal = app.textFields["goalField.Calories"]
        XCTAssertTrue(cal.waitForExistence(timeout: 5))
        cal.tap(); cal.typeText("2200")
        app.textFields["goalField.Protein"].tap(); app.textFields["goalField.Protein"].typeText("180")
        app.textFields["goalField.Carbs"].tap(); app.textFields["goalField.Carbs"].typeText("200")
        app.textFields["goalField.Fat"].tap(); app.textFields["goalField.Fat"].typeText("60")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }   // dismiss keyboard
        attach(app, "02-goal-manual-filled")

        app.buttons["Save target"].tap()

        // Back in Settings, the card reflects the saved manual target.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Manual")).firstMatch.waitForExistence(timeout: 5),
                      "Settings card should show the saved manual target")
        attach(app, "03-settings-with-target")
    }

    @MainActor
    func testCalculateTargetFromSettings() throws {
        let app = launchedApp()
        app.buttons["Settings"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Set your daily target")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Set your macros"].waitForExistence(timeout: 5))

        func fill(_ id: String, _ text: String) {
            let f = app.textFields[id]
            XCTAssertTrue(f.waitForExistence(timeout: 5), "missing field \(id)")
            f.tap(); f.typeText(text)
        }
        // Default: unspecified / moderate / lose → goal weight + timeframe show.
        fill("goalField.age", "30")
        fill("goalField.heightFt", "5")
        fill("goalField.heightIn", "10")
        fill("goalField.weight", "180")
        fill("goalField.goalWeight", "165")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }

        app.buttons["Calculate my target"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Maintenance")).firstMatch.waitForExistence(timeout: 5),
                      "The calculated review should show a maintenance estimate")
        attach(app, "04-goal-calculated")

        app.buttons["Save target"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Calculated")).firstMatch.waitForExistence(timeout: 5),
                      "A generated target should read 'Calculated' in Settings")
    }
}
