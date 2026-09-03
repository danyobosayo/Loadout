import XCTest

/// The landing screen has to answer "what are you having?" for every restaurant.
///
/// It used to be driven by a hand-written presets file, which was arbitrary:
/// Jersey Mike's had 12 subs and looked right, Chick-fil-A had 3 salads while its
/// sandwiches hid behind "Build your own", and Raising Cane's had no file at all —
/// so its landing offered nothing but "Fit my macros" and "Build your own".
final class HeadlineMenuUITests: XCTestCase {
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

    @MainActor
    private func buttonIndex(in app: XCUIApplication, labelPrefix: String) -> Int? {
        app.buttons.allElementsBoundByIndex.firstIndex { $0.label.hasPrefix(labelPrefix) }
    }

    /// Assembly and sandwich shops should ask what the person is building
    /// before offering named recipes. This is deliberately shared behavior:
    /// each new build-to-order restaurant gets it by supplying formats rather
    /// than relying on another hand-sorted list.
    @MainActor
    func testBuildToOrderRestaurantsLeadWithBuildOptions() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()

        app.tapRestaurant("CAVA,")
        let grainBowl = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Grain Bowl")
        ).firstMatch
        let spicyLamb = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Spicy Lamb + Avocado")
        ).firstMatch
        XCTAssertTrue(grainBowl.waitForExistence(timeout: 15))
        XCTAssertTrue(spicyLamb.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "Grain Bowl")),
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "Spicy Lamb + Avocado"))
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tapRestaurant("Subway,")
        let sandwichFormat = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "6-inch Sandwich")
        ).firstMatch
        let steakPhilly = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Steak Philly")
        ).firstMatch
        XCTAssertTrue(sandwichFormat.waitForExistence(timeout: 15))
        XCTAssertTrue(steakPhilly.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "6-inch Sandwich")),
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "Steak Philly"))
        )
        attach(app, "00-build-options-first")
    }

    /// Cane's has no presets file, and used to land on an empty-feeling screen.
    @MainActor
    func testCanesListsItsCombosOnTheLandingScreen() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Raising Cane's,")

        let box = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Box Combo")).firstMatch
        XCTAssertTrue(box.waitForExistence(timeout: 15),
                      "the landing screen should list Cane's combos, not just Build your own")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Caniac Combo")).firstMatch.exists)
        XCTAssertLessThan(
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "Box Combo")),
            try XCTUnwrap(buttonIndex(in: app, labelPrefix: "Browse the full menu")),
            "a top-down restaurant should still lead with its actual combos"
        )
        attach(app, "01-canes-landing")

        // …and picking one goes straight to "how do you want it?".
        box.tap()
        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 12),
                      "a headline item should open its configurator directly")
        attach(app, "02-canes-configurator")
    }

    /// Chick-fil-A's sandwiches were reachable only via "Build your own" while
    /// three salads sat on the landing screen.
    @MainActor
    func testChickFilAListsSandwichesNotJustSalads() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Chick-fil-A,")

        let sandwich = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Chick-fil-A Chicken Sandwich")
        ).firstMatch
        XCTAssertTrue(sandwich.waitForExistence(timeout: 15),
                      "the landing screen should list the sandwiches")
        var scrolls = 0
        while !sandwich.isHittable && scrolls < 10 { app.swipeUp(); scrolls += 1 }
        attach(app, "03-cfa-landing")
        sandwich.tap()
        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 12))
    }

    /// Assembly restaurants are unchanged: nothing is picked off a list, so the
    /// landing still asks which format you're building.
    @MainActor
    func testAssemblyRestaurantsStillOfferFormats() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Chipotle,")

        XCTAssertTrue(app.staticTexts["Build your own"].waitForExistence(timeout: 15),
                      "Chipotle assembles, so it keeps the format picker")
        XCTAssertTrue(app.staticTexts["Burrito"].exists)
        XCTAssertFalse(app.staticTexts["Browse the full menu"].exists,
                       "the browse wording is only for restaurants that list a menu above it")
    }
}
