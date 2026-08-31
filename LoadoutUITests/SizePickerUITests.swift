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
}
