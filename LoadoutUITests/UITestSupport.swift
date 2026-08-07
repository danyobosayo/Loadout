import XCTest

extension XCUIApplication {
    /// Tap a restaurant card on the Build tab, scrolling it into view first.
    ///
    /// The list is alphabetical and now 14 long, so the back half (Starbucks,
    /// Subway, Sweetgreen, The Halal Guys) starts below the fold.
    /// `waitForExistence` is not enough on its own — a SwiftUI `ScrollView`
    /// reports off-screen cards as existing but not hittable, and tapping one
    /// in that state lands somewhere else on screen.
    ///
    /// Pass the display name with its trailing comma (`"Sweetgreen,"`), which is
    /// how the card's accessibility label begins before its station/item count.
    @MainActor
    func tapRestaurant(_ labelPrefix: String, file: StaticString = #filePath, line: UInt = #line) {
        let card = buttons.matching(NSPredicate(format: "label BEGINSWITH %@", labelPrefix)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 15),
                      "\(labelPrefix) never appeared on the Build tab", file: file, line: line)

        var scrolls = 0
        while !card.isHittable && scrolls < 12 {
            swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(card.isHittable,
                      "\(labelPrefix) never scrolled into reach", file: file, line: line)
        card.tap()
    }
}
