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
}
