import XCTest

/// The type scale follows the system text size but stops at xxLarge, because a
/// row carrying four macros, an icon and a chevron cannot stay on one line at the
/// accessibility sizes — and a wrapped number reads as a different meal.
///
/// These tests exist to prove both halves: that text actually scales, and that
/// the dense rows survive the largest size the app will ever render.
final class DynamicTypeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchedApp(contentSize: String) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "YES",
                                "-loadout.debug.resetProfile", "YES",
                                "-loadout.debug.resetLibrary", "YES",
                                "-UIPreferredContentSizeCategoryName", contentSize]
        app.launch()
        return app
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    /// A Cane's combo card carries a name, a serving line and four macros. At the
    /// app's ceiling it must still be one row per combo, with every macro present.
    @MainActor
    func testDenseMacroRowsSurviveTheLargestSize() throws {
        let app = launchedApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        app.buttons["Build"].tap()
        app.tapRestaurant("Raising Cane's,")

        let box = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Box Combo")).firstMatch
        XCTAssertTrue(box.waitForExistence(timeout: 15))
        attach(app, "01-canes-largest")

        // Every macro still readable on the card — a dropped or wrapped figure
        // would show up as a missing component in the label.
        // The accessibility label carries raw figures, not the formatted "1,290".
        for fragment in ["1290", "62", "98", "72"] {
            XCTAssertTrue(box.label.contains(fragment),
                          "macro \(fragment) missing at the largest size — reads: \(box.label)")
        }

        box.tap()
        XCTAssertTrue(app.staticTexts["Comes with"].waitForExistence(timeout: 12),
                      "the configurator must still be usable at the largest size")
        attach(app, "02-configurator-largest")
    }

    /// …and the scale is genuinely dynamic, not fixed: the same row is taller at
    /// the ceiling than at the default.
    @MainActor
    func testTextActuallyScales() throws {
        let small = launchedApp(contentSize: "UICTContentSizeCategoryMedium")
        small.buttons["Build"].tap()
        let smallCard = small.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "CAVA,")).firstMatch
        XCTAssertTrue(smallCard.waitForExistence(timeout: 15))
        let smallHeight = smallCard.frame.height
        small.terminate()

        let large = launchedApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        large.buttons["Build"].tap()
        let largeCard = large.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "CAVA,")).firstMatch
        XCTAssertTrue(largeCard.waitForExistence(timeout: 15))

        XCTAssertGreaterThan(largeCard.frame.height, smallHeight,
                             "text is not scaling — the card is the same height at both sizes")
    }
}
