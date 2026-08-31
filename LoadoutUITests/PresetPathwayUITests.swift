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

    /// A preset lands in the BUILDER, not in the tray.
    ///
    /// It used to open the tray sheet directly, which read as "done, log it"
    /// while every other route lands somewhere you adjust first. Screen 2 answers
    /// "how do you want it?" for everything now — the meal arrives already built,
    /// with the tray bar carrying the total and the tray one tap away.
    @MainActor
    func testPresetLandsInTheBuilderAlreadyBuilt() throws {
        let app = launchedApp()
        openSweetgreen(app)

        // The published-meals section, with macros on the card before you tap.
        XCTAssertTrue(app.staticTexts["On the menu"].waitForExistence(timeout: 10),
                      "Sweetgreen should offer its published meals")
        let harvest = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harvest Bowl,")).firstMatch
        XCTAssertTrue(harvest.waitForExistence(timeout: 5), "Harvest Bowl preset should be listed")
        attach(app, "01-preset-cards")
        harvest.tap()

        // The builder, with the meal already in it — no tray sheet in the way.
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 8),
                      "A preset should land in the builder with its tray bar")
        XCTAssertFalse(app.staticTexts["Your tray"].exists,
                       "the tray sheet should not open over the builder")
        XCTAssertFalse(tray.label.contains("Empty"), "the preset's items should already be loaded")
        attach(app, "02-preset-in-builder")

        // …and the tray is still one tap away when you're ready to log.
        tray.tap()
        XCTAssertTrue(app.staticTexts["Your tray"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Roasted Chicken")).firstMatch.exists,
                      "The tray should hold the preset's line items")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Log")).firstMatch.exists,
                      "The preset should be loggable without further edits")
        attach(app, "02b-preset-tray")
    }

    @MainActor
    func testPresetStaysEditableAfterLanding() throws {
        let app = launchedApp()
        openSweetgreen(app)

        let kale = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Kale Caesar,")).firstMatch
        XCTAssertTrue(kale.waitForExistence(timeout: 10))
        kale.tap()

        // No dismissal step any more: you land in the stations, meal loaded.
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 8),
                      "A preset should land in the stations with the meal still loaded")
        XCTAssertFalse(tray.label.contains("Empty"))
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

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 8),
                      "A preset should land in the builder with its tray bar")
        XCTAssertFalse(tray.label.contains("Empty"), "the sub's items should already be loaded")
        tray.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Turkey")).firstMatch.waitForExistence(timeout: 8),
                      "The tray should hold the sub's line items")
        attach(app, "05-jersey-mikes-in-tray")
    }

    /// Panda's Balanced Protein Plates are current named macro-focused meals,
    /// so they should lead into the same editable tray as other presets.
    @MainActor
    func testPandaShowsBalancedProteinPresets() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Panda Express,")

        XCTAssertTrue(app.staticTexts["On the menu"].waitForExistence(timeout: 10),
                      "Panda's Balanced Protein Plates should appear as named meals")
        let plate = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Double Protein Plate,")
        ).firstMatch
        XCTAssertTrue(plate.waitForExistence(timeout: 5))
        XCTAssertTrue(plate.label.contains("875"), "The card should show Panda's published total")
        plate.tap()

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 8) && tray.label.contains("875"),
                      "The published plate should open as an editable 875-calorie tray")
    }
}
