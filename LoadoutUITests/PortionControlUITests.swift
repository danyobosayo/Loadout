import XCTest

/// Verifies the tap-to-cycle station model: tap → full, tap again → ×2, and
/// tapping a second base item auto-splits to ½ + ½.
final class PortionControlUITests: XCTestCase {
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
    func testTapCycleAndHalfAndHalf() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chipotle,")).firstMatch.tap()
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15))
        byo.tap()

        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch

        // Jump to Protein and double it: tap once (full = 180), again (×2 = 360).
        app.buttons["Protein station"].tap()
        let chicken = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chicken,")).firstMatch
        XCTAssertTrue(chicken.waitForExistence(timeout: 8))
        chicken.tap()
        chicken.tap()
        attach(app, "01-protein-doubled")
        XCTAssertTrue(tray.waitForExistence(timeout: 5) && tray.label.contains("360"),
                      "A second tap should double the protein (2×180=360) — tray: \(tray.label)")

        // Jump to Rice and split it: white, then brown → ½ + ½ (210 total).
        app.buttons["Rice station"].tap()
        let white = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cilantro-Lime White Rice")).firstMatch
        let brown = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cilantro-Lime Brown Rice")).firstMatch
        XCTAssertTrue(white.waitForExistence(timeout: 8))
        white.tap()
        brown.tap()
        attach(app, "02-rice-half-and-half")
        // 360 protein + ½·210 + ½·210 = 570.
        XCTAssertTrue(tray.label.contains("570"),
                      "Second rice should split both to ½ (total 570) — tray: \(tray.label)")
    }

    @MainActor
    func testCavaGreensAndGrainsBaseIsHalfAndHalf() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "CAVA,")).firstMatch.tap()
        let greensGrains = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Greens + Grains")).firstMatch
        XCTAssertTrue(greensGrains.waitForExistence(timeout: 15), "CAVA should offer Greens + Grains")
        greensGrains.tap()

        // Grain-half prompt is expanded — pick a grain (lands at ½).
        let brownRice = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Brown Rice")).firstMatch
        XCTAssertTrue(brownRice.waitForExistence(timeout: 10))
        brownRice.tap()

        // No auto-advance: open the greens-half prompt and pick a greens (½).
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pick your greens half")).firstMatch.tap()
        let arugula = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Arugula")).firstMatch
        XCTAssertTrue(arugula.waitForExistence(timeout: 5))
        arugula.tap()
        attach(app, "03-greens-and-grains")

        // Two half bases = 2 line items, each ½.
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5) && tray.label.contains("2 item"),
                      "Greens + Grains should hold two ½ bases — tray: \(tray.label)")
    }

    @MainActor
    func testPandaBiggerPlateCountsEntrees() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Panda Express,")).firstMatch.tap()
        let bigger = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Bigger Plate")).firstMatch
        XCTAssertTrue(bigger.waitForExistence(timeout: 15), "Panda should offer a Bigger Plate")
        bigger.tap()

        // Entrées is a capped counter (up to 3): 2 orange chicken + 1 mushroom.
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Choose 3 entrées")).firstMatch.tap()
        let orange = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Orange Chicken,")).firstMatch
        XCTAssertTrue(orange.waitForExistence(timeout: 8))
        orange.tap()
        orange.tap()   // 2 portions orange chicken
        let mushroom = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mushroom Chicken,")).firstMatch
        XCTAssertTrue(mushroom.waitForExistence(timeout: 5))
        mushroom.tap() // + 1 → total 3
        attach(app, "04-panda-2-orange-1-mushroom")
        // 2×orange (1020) + 1×mushroom (220) = 1240.
        let pandaTray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(pandaTray.waitForExistence(timeout: 5) && pandaTray.label.contains("1240"),
                      "Two orange chicken + one mushroom should total 1240 — tray: \(pandaTray.label)")

        // Open the tray so the 4-digit ring total is on screen (must fit on
        // one line, not wrap).
        pandaTray.tap()
        XCTAssertTrue(app.staticTexts["Your tray"].waitForExistence(timeout: 5))
        attach(app, "06-tray-ring-4digit")
    }

    @MainActor
    func testSelectedStationRowHighlights() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "CAVA,")).firstMatch.tap()
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15))
        byo.tap()

        // A base at a full single portion (qty 1) shows no badge — the whole
        // row must still read as selected (accent border + tint, not just the dot).
        let base = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Saffron Basmati Rice")).firstMatch
        var scrolls = 0
        while !(base.exists && base.isHittable) && scrolls < 6 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(base.waitForExistence(timeout: 5))
        base.tap()
        attach(app, "07-selected-base-highlight")
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5) && tray.label.contains("1 item"),
                      "Tapping a base once should select it — tray: \(tray.label)")
    }

    @MainActor
    func testToppingsCountUncapped() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chipotle,")).firstMatch.tap()
        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 15))
        byo.tap()

        // Scroll down to a Toppings item.
        let cheese = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cheese,")).firstMatch
        var scrolls = 0
        while !(cheese.exists && cheese.isHittable) && scrolls < 10 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(cheese.waitForExistence(timeout: 3), "Toppings should be reachable")
        cheese.tap()
        cheese.tap()
        cheese.tap()   // 3 — uncapped (the old cycle wrapped back to 0 at this point)
        attach(app, "05-toppings-count")
        // 3 × 110-cal cheese = 330; proves the counter is uncapped, not a
        // full→×2→off cycle. (The inline − is unit-tested + shown in the
        // Panda screenshot.)
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5) && tray.label.contains("330"),
                      "Cheese should count up uncapped (3×110=330) — tray: \(tray.label)")
    }
}
