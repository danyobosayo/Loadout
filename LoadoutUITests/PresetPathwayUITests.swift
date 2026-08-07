import XCTest

/// The two "already a complete meal" pathways on the restaurant screen: the
/// restaurant's published presets, and the user's own saved recipes. Both land
/// in the tray — log as-is, or dismiss the tray and edit.
final class PresetPathwayUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        // Layout-dependent assertions: the simulator is shared, so never
        // inherit another class's rotation.
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
        // No inherited target — Budget Mode text in the tray would otherwise
        // shift what these assertions match against.
        app.launchArguments += ["-loadout.debug.resetProfile", "YES"]
        // Start with no saved recipes: a recipe left by an earlier test
        // class shows up in "Your recipes" on the restaurant screen and
        // pushes the cards these tests tap below the fold.
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
    private func openSweetgreen(_ app: XCUIApplication) {
        app.buttons["Build"].tap()
        app.tapRestaurant("Sweetgreen,")
    }

    @MainActor
    func testPresetLandsInTheTrayReadyToLog() throws {
        let app = launchedApp()
        openSweetgreen(app)

        // The published-meals section, with macros on the card before you tap.
        XCTAssertTrue(app.staticTexts["On the menu"].waitForExistence(timeout: 10),
                      "Sweetgreen should offer its published meals")
        let harvest = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harvest Bowl,")).firstMatch
        XCTAssertTrue(harvest.waitForExistence(timeout: 5), "Harvest Bowl preset should be listed")
        attach(app, "01-preset-cards")
        harvest.tap()

        // Straight into the tray, fully populated and loggable.
        XCTAssertTrue(app.staticTexts["Your tray"].waitForExistence(timeout: 8),
                      "A preset should open the tray directly")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Roasted Chicken")).firstMatch.exists,
                      "The tray should hold the preset's line items")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Log")).firstMatch.exists,
                      "The preset should be loggable without further edits")
        attach(app, "02-preset-in-tray")
    }

    @MainActor
    func testPresetStaysEditableAfterLanding() throws {
        let app = launchedApp()
        openSweetgreen(app)

        let kale = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Kale Caesar,")).firstMatch
        XCTAssertTrue(kale.waitForExistence(timeout: 10))
        kale.tap()
        XCTAssertTrue(app.staticTexts["Your tray"].waitForExistence(timeout: 8))

        // Dismissing the tray drops into the stations — the "modify it" path.
        app.swipeDown(velocity: .fast)
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 8),
                      "Dismissing the tray should land in the stations with the meal still loaded")
        attach(app, "03-preset-editable")
    }

    /// The same pathway at one of the newer restaurants, whose menu, formats and
    /// presets were all sourced in one pass — this is the end-to-end proof that
    /// a freshly added restaurant is fully wired, not just schema-valid.
    @MainActor
    func testPresetsWorkAtANewlyAddedRestaurant() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Jersey Mike's Subs,")

        XCTAssertTrue(app.staticTexts["On the menu"].waitForExistence(timeout: 10),
                      "Jersey Mike's should offer its published subs")
        let sub = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "#7 Turkey and Provolone,")).firstMatch
        XCTAssertTrue(sub.waitForExistence(timeout: 5), "The #7 should be listed")
        attach(app, "04-jersey-mikes-presets")
        sub.tap()

        XCTAssertTrue(app.staticTexts["Your tray"].waitForExistence(timeout: 8),
                      "A preset should open the tray directly")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Turkey")).firstMatch.exists,
                      "The tray should hold the sub's line items")
        attach(app, "05-jersey-mikes-in-tray")
    }

    /// A restaurant that publishes no named meals shows no section — the file
    /// is absent for Panda by design.
    @MainActor
    func testRestaurantWithoutPresetsShowsNoSection() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Panda Express,")

        XCTAssertTrue(app.staticTexts["Build to order"].waitForExistence(timeout: 10),
                      "Panda should still offer its formats")
        XCTAssertFalse(app.staticTexts["On the menu"].exists,
                       "Panda publishes no named meals, so the section should be absent")
    }
}
