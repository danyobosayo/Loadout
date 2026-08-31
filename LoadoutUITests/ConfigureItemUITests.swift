import XCTest

/// The top-down ordering path: pick a combo that already exists, then take
/// things off it. This is how Raising Cane's, Chick-fil-A and most drive-thrus
/// are actually ordered — unlike Chipotle's build-from-nothing line — and the
/// number a person needs to trust is the published one on the menu board.
final class ConfigureItemUITests: XCTestCase {
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
    private func openBoxCombo(_ app: XCUIApplication) {
        app.buttons["Build"].tap()
        app.tapRestaurant("Raising Cane's,")

        let combo = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Box Combo,")
        ).firstMatch
        if !combo.waitForExistence(timeout: 15) {
            attach(app, "diagnostic-canes-screen")
            XCTFail("Box Combo never appeared. On screen: "
                    + app.buttons.allElementsBoundByIndex.prefix(25).map(\.label).joined(separator: " | "))
        }
        var scrolls = 0
        while !combo.isHittable && scrolls < 8 { app.swipeUp(); scrolls += 1 }
        combo.tap()
    }

    /// Tapping a built item must open it for configuration rather than dropping
    /// it straight into the tray, and it must open showing the board figure.
    @MainActor
    func testTappingAComboOpensItAtThePublishedTotal() throws {
        let app = launchedApp()
        openBoxCombo(app)

        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 10),
                      "A combo should open a configure sheet, not add silently")
        attach(app, "01-configure-sheet")

        XCTAssertTrue(app.staticTexts["1,290"].exists || app.staticTexts["1290"].exists,
                      "An untouched Box Combo must read its published 1290 cal")
        // Nothing has changed yet, so there is nothing to report against standard.
        XCTAssertFalse(app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "vs standard")).firstMatch.exists)
    }

    /// The headline modification: drop the slaw. The total must fall by exactly
    /// the slaw's published 100 cal — not be recomputed from parts.
    @MainActor
    func testRemovingASideSubtractsItFromTheBoardFigure() throws {
        let app = launchedApp()
        openBoxCombo(app)
        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 10))

        let slaw = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Coleslaw, included")
        ).firstMatch
        XCTAssertTrue(slaw.waitForExistence(timeout: 5), "Coleslaw should be listed as removable")
        slaw.tap()

        XCTAssertTrue(app.staticTexts["1,190"].waitForExistence(timeout: 5),
                      "1290 minus a 100-cal coleslaw is 1190")
        XCTAssertTrue(app.staticTexts["−100 vs standard"].exists,
                      "The sheet should say what the change cost")
        attach(app, "02-slaw-removed")

        // The tray carries the configured total and reads the order back.
        app.buttons["Add to meal"].tap()
        XCTAssertTrue(app.staticTexts["1,190"].waitForExistence(timeout: 5),
                      "The tray total should be the configured figure")
        // Committing must land back on the menu, not on a fresh configurator.
        XCTAssertFalse(app.staticTexts["Comes with"].exists,
                       "adding should return to the menu, not re-open the item")
        attach(app, "03-tray")
    }

    /// The fingers are what makes it a Box Combo, so they are neither offered
    /// nor removable — the product call was to hide them, not grey them out.
    @MainActor
    func testTheDefiningComponentIsNeverOffered() throws {
        let app = launchedApp()
        openBoxCombo(app)
        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 10))

        XCTAssertFalse(
            app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Chicken Finger, included")
            ).firstMatch.exists,
            "Unremovable defaults must be hidden, not shown as a dead row"
        )
    }
}
