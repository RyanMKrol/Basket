import XCTest

final class CheckOffFlowTests: BasketUITestCase {
    /// Tapping the check circle sparks, then the row glides into the faded
    /// "Got it" section once its ~0.55s commit delay elapses.
    func testCheckingItemOffMovesToGotSection() {
        launchApp()

        XCTAssertTrue(app.buttons["itemRow.Milk"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["4 to get"].waitForExistence(timeout: 3))
        attachScreenshot("01-before-check")

        app.buttons["itemRow.check.Milk"].tap()
        // Checked look (spark burst) applies immediately, before the section move.
        XCTAssertEqual(app.buttons["itemRow.check.Milk"].label, "Got it")
        attachScreenshot("02-checking-spark")

        XCTAssertTrue(app.staticTexts["3 to get"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Got it"].waitForExistence(timeout: 3))
        attachScreenshot("03-in-got-it-section")
    }

    /// Tapping a checked item in the "Got it" section restores it to the
    /// to-get list.
    func testRestoringItemFromGotSection() {
        launchApp()

        app.buttons["itemRow.check.Milk"].tap()
        XCTAssertTrue(app.staticTexts["Got it"].waitForExistence(timeout: 3))
        attachScreenshot("01-checked")

        app.buttons["itemRow.check.Milk"].tap()
        attachScreenshot("02-restored")

        XCTAssertTrue(app.staticTexts["4 to get"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["itemRow.check.Milk"].label, "Not got yet")
    }

    /// Checking off every item plays the full-screen "All done!" celebration.
    func testClearingWholeListShowsCelebration() {
        launchApp()

        for name in ["Milk", "Sourdough bread", "Eggs", "Tomatoes"] {
            app.buttons["itemRow.check.\(name)"].tap()
        }
        attachScreenshot("01-all-checked")

        XCTAssertTrue(app.staticTexts["celebration.title"].waitForExistence(timeout: 5))
        attachScreenshot("02-celebration")
    }

    /// "Clear all" empties the whole "Got it" section immediately, rather
    /// than waiting for its 1-hour TTL.
    func testClearAllEmptiesGotItSection() {
        launchApp()

        app.buttons["itemRow.check.Milk"].tap()
        XCTAssertTrue(app.staticTexts["Got it"].waitForExistence(timeout: 3))
        attachScreenshot("01-one-checked")

        app.buttons["gotSection.clearAll"].tap()
        attachScreenshot("02-cleared")

        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.staticTexts["Got it"]
        )
        wait(for: [gone], timeout: 3)
        XCTAssertFalse(app.buttons["itemRow.check.Milk"].exists)
    }
}
