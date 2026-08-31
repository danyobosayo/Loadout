import XCTest

/// One row per dish, with a size picker — not one row per size.
///
/// Starbucks shipped 427 rows that were really about 100 drinks, two thirds of
/// the scrolling being Tall/Venti duplicates of something already on screen. The
/// `SizeGroup` model existed and was unit-tested for months while no view ever
/// called it, so these tests exist to prove the collapse reaches the screen.
final class SizePickerUITests: XCTestCase {
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
    private func openStarbucks(_ app: XCUIApplication) {
        app.buttons["Build"].tap()
        app.tapRestaurant("Starbucks,")
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        if byo.waitForExistence(timeout: 12) { byo.tap() }
    }

    /// Tap the latte row — which opens the size sheet, because it has sizes —
    /// and choose Venti.
    @MainActor
    private func pickVenti(_ app: XCUIApplication) {
        let venti = app.buttons["size.starbucks.hot-coffee.caffe-latte-venti"]
        XCTAssertTrue(venti.waitForExistence(timeout: 8), "the size sheet should list Venti")
        venti.tap()
    }

    @MainActor
    private func latteRow(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Caffè Latte,")).firstMatch
    }

    /// The row shows the drink once, at its default cup, with the other cups
    /// offered as chips rather than as their own rows.
    @MainActor
    func testADrinkIsOneRowWithACupPicker() throws {
        let app = launchedApp()
        openStarbucks(app)

        let latte = latteRow(app)
        XCTAssertTrue(latte.waitForExistence(timeout: 15), "Caffè Latte should be listed")
        var scrolls = 0
        while !latte.isHittable && scrolls < 10 { app.swipeUp(); scrolls += 1 }
        attach(app, "01-sizes-collapsed")

        // Grande is what you get by saying nothing, so it's the row's figure.
        XCTAssertTrue(latte.label.contains("Grande"),
                      "the row should open on the default cup — reads: \(latte.label)")
        // …and the other cups must not be rows of their own.
        XCTAssertFalse(
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Caffè Latte (Venti)")).firstMatch.exists,
            "a size must not also appear as its own row"
        )
        // Tapping it opens the size sheet rather than adding a Grande outright.
        latte.tap()
        XCTAssertTrue(app.buttons["size.starbucks.hot-coffee.caffe-latte-venti"].waitForExistence(timeout: 8),
                      "a multi-size drink should offer a size sheet")
        attach(app, "02-size-sheet")
        app.buttons["Cancel"].tap()
    }

    /// The guided path — which is how Starbucks is actually entered, since its
    /// formats put the drinks in prompts rather than in optional stations — was
    /// listing every cup as its own row while build-your-own collapsed correctly.
    @MainActor
    func testTheGuidedPathCollapsesSizesToo() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Starbucks,")

        let hot = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Hot Coffee")).firstMatch
        XCTAssertTrue(hot.waitForExistence(timeout: 15), "Starbucks should offer a Hot Coffee format")
        hot.tap()

        let latte = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Caffè Latte,")).firstMatch
        XCTAssertTrue(latte.waitForExistence(timeout: 12), "the guided prompt should list Caffè Latte")
        var scrolls = 0
        while !latte.isHittable && scrolls < 10 { app.swipeUp(); scrolls += 1 }
        attach(app, "04-guided-collapsed")

        XCTAssertFalse(
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Caffè Latte (Venti)")).firstMatch.exists,
            "a cup must not be its own row in the guided prompt either"
        )
        // The row shows the default cup, not four rows.
        XCTAssertTrue(latte.label.contains("Grande"), "the row should show the default cup")

        latte.tap()
        XCTAssertTrue(app.buttons["size.starbucks.hot-coffee.caffe-latte-venti"].waitForExistence(timeout: 8),
                      "tapping a multi-size drink should open the size sheet")
        attach(app, "05-guided-size-sheet")
    }

    /// Picking a cup changes the macros on the row — the whole point of the
    /// picker is that a Venti and a Short are different numbers.
    @MainActor
    func testPickingACupChangesTheMacros() throws {
        let app = launchedApp()
        openStarbucks(app)

        let latte = latteRow(app)
        XCTAssertTrue(latte.waitForExistence(timeout: 15))
        var scrolls = 0
        while !latte.isHittable && scrolls < 10 { app.swipeUp(); scrolls += 1 }
        let grandeLabel = latte.label
        latte.tap()
        pickVenti(app)

        let switched = latteRow(app)
        XCTAssertTrue(switched.waitForExistence(timeout: 5))
        XCTAssertNotEqual(switched.label, grandeLabel, "switching cup should change the row's macros")
        XCTAssertTrue(switched.label.contains("Venti"), "the row should now read as a Venti")
        attach(app, "02-venti-selected")
    }

    /// Switching size on something already in the tray moves the line rather
    /// than leaving both cups on the order.
    @MainActor
    func testSwitchingSizeMovesTheLineInsteadOfAddingASecond() throws {
        let app = launchedApp()
        openStarbucks(app)

        let latte = latteRow(app)
        XCTAssertTrue(latte.waitForExistence(timeout: 15))
        var scrolls = 0
        while !latte.isHittable && scrolls < 10 { app.swipeUp(); scrolls += 1 }
        latte.tap()
        app.buttons["size.starbucks.hot-coffee.caffe-latte"].tap()   // Grande

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        XCTAssertTrue(tray.label.contains("1 item"), "adding a latte should put one line in the tray")

        latteRow(app).tap()
        pickVenti(app)

        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        XCTAssertTrue(tray.label.contains("1 item"),
                      "changing cup should move the line, not add a second latte — tray reads \(tray.label)")
        attach(app, "03-tray-after-switch")
    }

    /// Smoothie King is size-first in both its calculator and order flow. One
    /// conceptual smoothie should expose 20/32/44 oz, then keep enhancers as a
    /// separate, sourced station rather than pretending removals are exact.
    @MainActor
    func testSmoothieKingUsesCupPickerAndSourcedEnhancers() throws {
        let app = launchedApp()
        app.buttons["Build"].tap()
        app.tapRestaurant("Smoothie King,")

        let getFit = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Get Fit")
        ).firstMatch
        XCTAssertTrue(getFit.waitForExistence(timeout: 15))
        getFit.tap()

        let smoothie = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Original High Protein Banana,")
        ).firstMatch
        XCTAssertTrue(smoothie.waitForExistence(timeout: 12))
        var scrolls = 0
        while !smoothie.isHittable && scrolls < 12 { app.swipeUp(); scrolls += 1 }
        XCTAssertTrue(smoothie.label.contains("20 fl oz") && smoothie.label.contains("330"),
                      "The row should start at the official 20 oz nutrition basis: \(smoothie.label)")
        smoothie.tap()

        let fortyFour = app.buttons[
            "size.smoothie-king.get-fit.original-high-protein-banana.44-oz"
        ]
        XCTAssertTrue(fortyFour.waitForExistence(timeout: 8))
        fortyFour.tap()

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 6) && tray.label.contains("660"),
                      "The selected 44 oz smoothie should contribute 660 calories: \(tray.label)")
        let enhancers = app.buttons["Enhancers station"]
        XCTAssertTrue(enhancers.exists,
                      "The guided flow should expose separately sourced enhancer servings")
        enhancers.tap()
        let whey = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Whey Protein,")
        ).firstMatch
        XCTAssertTrue(whey.waitForExistence(timeout: 6))
        whey.tap()
        let updatedTotal = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "688"),
            object: tray
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [updatedTotal], timeout: 8),
            .completed,
            "The published 27.8-calorie whey serving should update the rounded tray total: \(tray.label)"
        )
        attach(app, "06-smoothie-king-44oz")
    }
}
