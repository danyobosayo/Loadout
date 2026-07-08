import XCTest

/// End-to-end smoke test for the order-format / guided-entry flow:
/// restaurant → format picker → guided MenuView with the vessel seeded.
/// Skips onboarding via the argument domain so it lands on the Build tab.
final class OrderFormatFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        // NSArgumentDomain overrides UserDefaults → onboarding is skipped.
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES"]
        app.launch()
        return app
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testChipotleBurritoGuidedFlow() throws {
        let app = launchedApp()

        // Build tab lists restaurants — open Chipotle.
        let chipotle = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chipotle,")).firstMatch
        XCTAssertTrue(chipotle.waitForExistence(timeout: 15), "Chipotle card should appear on the Build tab")
        chipotle.tap()

        // Format picker: format cards + the build-your-own escape hatch.
        XCTAssertTrue(app.staticTexts["Build your own"].waitForExistence(timeout: 10),
                      "Format picker should offer Build your own")
        XCTAssertTrue(app.staticTexts["Burrito"].exists, "Format picker should list Burrito")
        XCTAssertTrue(app.staticTexts["Tacos"].exists, "Format picker should list Tacos")
        attach(app, "01-format-picker")

        // Pick Burrito (BEGINSWITH 'Burrito.' excludes 'Burrito Bowl').
        let burrito = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Burrito.")).firstMatch
        XCTAssertTrue(burrito.waitForExistence(timeout: 5))
        burrito.tap()

        // Guided MenuView: the defining picks are prompted, add-ons below.
        XCTAssertTrue(app.staticTexts["Choose your protein"].waitForExistence(timeout: 10),
                      "Burrito should guide the protein pick")
        XCTAssertTrue(app.staticTexts["Choose your rice"].exists, "Burrito should guide the rice pick")
        XCTAssertTrue(app.staticTexts["Choose your beans"].exists, "Burrito should guide the beans pick")
        attach(app, "02-guided-burrito")

        // Rice is expanded on entry. Tap white (full), then brown — a second
        // pick auto-splits both to ½. Nothing auto-advances now, so the rice
        // prompt stays open the whole time.
        let whiteRice = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cilantro-Lime White Rice")).firstMatch
        XCTAssertTrue(whiteRice.waitForExistence(timeout: 5), "Rice options should be expanded on entry")
        whiteRice.tap()
        let brownRice = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cilantro-Lime Brown Rice")).firstMatch
        XCTAssertTrue(brownRice.waitForExistence(timeout: 5))
        brownRice.tap()
        // tortilla + white ½ + brown ½ = 3 line items.
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch.label.contains("3 item"),
                      "Tapping a second rice should split both to ½ (3 line items in the tray)")
        attach(app, "02b-rice-half-and-half")

        // The flour tortilla auto-seeded, so the tray already holds 1 item.
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5), "Tray bar should be present")
        XCTAssertFalse(tray.label.contains("Empty"), "Burrito should have seeded the tortilla into the tray")
        tray.tap()
        XCTAssertTrue(app.staticTexts["Flour Tortilla (burrito)"].waitForExistence(timeout: 10),
                      "The seeded flour tortilla should be in the tray")
        // Protein was never picked, so the tray softly nudges for it.
        XCTAssertTrue(app.staticTexts["Still to add: Protein"].waitForExistence(timeout: 5),
                      "Tray should nudge for the unpicked required protein")
        attach(app, "03-tray-seeded-tortilla")
    }

    @MainActor
    func testFootlongScalesPortions() throws {
        let app = launchedApp()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Subway,")).firstMatch.tap()
        let footlong = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Footlong.")).firstMatch
        XCTAssertTrue(footlong.waitForExistence(timeout: 15), "Subway should offer a Footlong format")
        footlong.tap()

        // Guided pick scales ×2: the bread prompt is expanded on entry, and
        // the 210-kcal 6-inch loaf logs at 420 for a Footlong.
        let bread = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Artisan Italian Bread")).firstMatch
        XCTAssertTrue(bread.waitForExistence(timeout: 10), "Footlong should guide the bread pick")
        bread.tap()
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        XCTAssertTrue(tray.label.contains("420"),
                      "Footlong bread should log at twice the 6-inch calories — got: \(tray.label)")

        // Add-on stations scale too: jump to Veggies via the rail and add one.
        app.buttons["Veggies station"].tap()
        let lettuce = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Lettuce")).firstMatch
        XCTAssertTrue(lettuce.waitForExistence(timeout: 5), "Veggies station should be reachable via the rail")
        lettuce.tap()
        attach(app, "04-footlong-x2")

        tray.tap()
        XCTAssertTrue(app.staticTexts["Lettuce"].waitForExistence(timeout: 10),
                      "The added veggie should appear in the tray")
        attach(app, "04b-footlong-tray")
    }

    @MainActor
    func testBuildYourOwnBypassesGuidance() throws {
        let app = launchedApp()

        let chipotle = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chipotle,")).firstMatch
        XCTAssertTrue(chipotle.waitForExistence(timeout: 15))
        chipotle.tap()

        let byo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Build your own")).firstMatch
        XCTAssertTrue(byo.waitForExistence(timeout: 10))
        byo.tap()

        // Full flat station list, no guided prompts, tray starts empty.
        XCTAssertTrue(app.staticTexts["Protein · choose 1"].waitForExistence(timeout: 10)
                      || app.staticTexts["Protein"].waitForExistence(timeout: 2),
                      "Build-your-own should show the raw station list")
        XCTAssertFalse(app.staticTexts["Choose your protein"].exists,
                       "Build-your-own must not show guided prompts")
        let tray = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meal tray")).firstMatch
        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        XCTAssertTrue(tray.label.contains("Empty"), "Build-your-own tray should start empty")
    }
}
