import XCTest

final class CheckOffFlowTests: BasketUITestCase {
    /// Tapping the check circle sparks, then the row glides into the faded
    /// "Got it" section once its ~0.55s commit delay elapses.
    ///
    /// Runs with `realTiming` — the one flow that exercises the production
    /// animations and the full commit delay, so the real choreography stays
    /// covered while every other test runs deterministic-and-fast.
    func testCheckingItemOffMovesToGotSection() {
        launchApp(realTiming: true)

        XCTAssertTrue(app.buttons["itemRow.Milk"].waitForExistence(timeout: 5))
        waitForToGetCount(4)
        attachScreenshot("01-before-check")

        app.buttons["itemRow.check.Milk"].tap()
        // Checked look (spark burst) applies immediately, before the section move.
        waitForLabel(app.buttons["itemRow.check.Milk"], equals: "Got it")
        attachScreenshot("02-checking-spark")

        waitForToGetCount(3)
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("03-in-got-it-section")
    }

    /// Tapping a checked item in the "Got it" section restores it to the
    /// to-get list.
    func testRestoringItemFromGotSection() {
        launchApp()

        app.buttons["itemRow.check.Milk"].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-checked")

        app.buttons["itemRow.check.Milk"].tap()
        attachScreenshot("02-restored")

        waitForToGetCount(4)
        waitForLabel(app.buttons["itemRow.check.Milk"], equals: "Not got yet")
    }

    /// Checking off every item plays the full-screen "All done!" celebration.
    ///
    /// In production the celebration auto-dismisses after ~1.6s, which made
    /// this assert flaky: on a slow/contended runner the overlay could render
    /// correctly (it's in the failure screenshot) yet appear and vanish in the
    /// gap before XCUITest's first accessibility poll even landed, so every
    /// `waitForExistence` snapshot missed it. `TestHooks.celebrationDuration`
    /// now suppresses that auto-dismiss under UI testing, so the overlay stays
    /// put and this observes a stable state instead of racing a timer.
    func testClearingWholeListShowsCelebration() {
        launchApp()

        for name in SharedFixtures.starterItems {
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
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-one-checked")

        app.buttons["gotSection.clearAll"].tap()
        attachScreenshot("02-cleared")

        waitForGone(gotSectionHeader)
        XCTAssertFalse(app.buttons["itemRow.check.Milk"].exists)
    }
}
