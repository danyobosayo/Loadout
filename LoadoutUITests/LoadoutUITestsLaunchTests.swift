//
//  LoadoutUITestsLaunchTests.swift
//  LoadoutUITests
//
//  Created by Daniel Sungsu Kim on 2026/5/9.
//

import XCTest

final class LoadoutUITestsLaunchTests: XCTestCase {

    /// Off deliberately. The Xcode template defaults this to `true`, which
    /// re-runs `testLaunch` in landscape — and leaves the *shared* simulator
    /// rotated for every test class that runs after this one alphabetically.
    /// Loadout is a portrait iPhone app (PROJECT.md §2), so the landscape pass
    /// verified nothing and silently broke the layout-dependent suites.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Belt and braces: never hand the next class a rotated device.
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
