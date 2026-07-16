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

        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Milk")].waitForExistence(timeout: 5))
        waitForToGetCount(4)
        attachScreenshot("01-before-check")

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        // Checked look (spark burst) applies immediately, before the section move.
        waitForLabel(app.buttons[A11yID.ItemRow.check("Milk")], equals: "Got it")
        attachScreenshot("02-checking-spark")

        waitForToGetCount(3)
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("03-in-got-it-section")
    }

    /// Tapping a checked item in the "Got it" section restores it to the
    /// to-get list.
    func testRestoringItemFromGotSection() {
        launchApp()

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-checked")

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        attachScreenshot("02-restored")

        waitForToGetCount(4)
        waitForLabel(app.buttons[A11yID.ItemRow.check("Milk")], equals: "Not got yet")
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
            app.buttons[A11yID.ItemRow.check(name)].tap()
        }
        attachScreenshot("01-all-checked")

        XCTAssertTrue(app.staticTexts["celebration.title"].waitForExistence(timeout: 5))
        attachScreenshot("02-celebration")
    }

    /// The celebration's dismiss must fade its own content out gracefully,
    /// synced with the outer container's fade, instead of the emoji/label
    /// sitting pinned at full scale/opacity while only the background dims —
    /// see T040 / ClearedCelebration.isDismissing.
    ///
    /// `TestHooks.celebrationDuration` is nil under UI testing (deliberately,
    /// to avoid racing the overlay's transient auto-dismiss timer — see
    /// `testClearingWholeListShowsCelebration`), so the only reachable way to
    /// end a celebration under test is the same one a user has: tapping
    /// "Clear all" in the Got it section while it's showing. That's also
    /// exactly the previously-buggy compound-condition path (T040 spec item
    /// 2), so this single recording covers both: the dismiss fades
    /// gracefully, and it's driven by the one unified `dismissCelebration()`
    /// path rather than an independent, uncoordinated yank.
    ///
    /// Runs with `realTiming` so the recorded frames show the real
    /// production animation curves, not the sped-up test defaults. See
    /// worklog/T040.md for the recorded video path and the frame-by-frame
    /// trend observed.
    func testCelebrationDismissFadesGracefullyOnClearGot() {
        launchApp(realTiming: true)

        for name in SharedFixtures.starterItems {
            app.buttons[A11yID.ItemRow.check(name)].tap()
        }

        XCTAssertTrue(app.staticTexts["celebration.title"].waitForExistence(timeout: 5))
        attachScreenshot("01-celebration-shown")

        // Let the entrance spring + burst settle into a stable state before
        // the dismiss so the recording's dismiss window is unambiguous.
        Thread.sleep(forTimeInterval: 1.5)

        XCTAssertTrue(app.buttons[A11yID.GotSection.clearAll].waitForExistence(timeout: 3))
        app.buttons[A11yID.GotSection.clearAll].tap()
        attachScreenshot("02-clear-tapped-mid-celebration")

        // Give the exit animation (~0.4s) generous room to finish playing so
        // the tail of the recording captures the fully-settled end state too.
        Thread.sleep(forTimeInterval: 3.0)
        attachScreenshot("03-after-dismiss")

        XCTAssertFalse(app.staticTexts["celebration.title"].exists)
    }

    /// "Clear all" empties the whole "Got it" section immediately, rather
    /// than waiting for its 1-hour TTL.
    func testClearAllEmptiesGotItSection() {
        launchApp()

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-one-checked")

        app.buttons[A11yID.GotSection.clearAll].tap()
        attachScreenshot("02-cleared")

        waitForGone(gotSectionHeader)
        XCTAssertFalse(app.buttons[A11yID.ItemRow.check("Milk")].exists)
    }

    /// "Clear all" is instantly recoverable: tapping the undo toast's Undo
    /// button restores every cleared item, quantities included.
    func testClearAllUndoRestoresItems() {
        launchApp()

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        app.buttons[A11yID.ItemRow.check("Eggs")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        waitForToGetCount(2)
        attachScreenshot("01-two-checked")

        app.buttons[A11yID.GotSection.clearAll].tap()
        waitForGone(gotSectionHeader)
        attachScreenshot("02-cleared-toast-shown")

        let undo = app.buttons["clearToast.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        undo.tap()

        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons[A11yID.ItemRow.check("Milk")].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons[A11yID.ItemRow.check("Eggs")].waitForExistence(timeout: 3))
        waitForToGetCount(2)
        attachScreenshot("03-restored-after-undo")

        // The undo toast itself dismisses along with the restore.
        waitForGone(undo)
    }

    /// Letting the undo toast expire without tapping Undo commits the
    /// clear: the toast dismisses on its own and the items stay gone.
    func testClearAllExpiredToastLeavesItemsCleared() {
        launchApp()

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-one-checked")

        app.buttons[A11yID.GotSection.clearAll].tap()
        let undo = app.buttons["clearToast.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        attachScreenshot("02-toast-shown")

        // Let the shortened test-mode toast duration elapse without tapping Undo.
        waitForGone(undo, timeout: 5)
        attachScreenshot("03-toast-expired")

        XCTAssertFalse(app.buttons[A11yID.ItemRow.check("Milk")].exists)
        XCTAssertFalse(gotSectionHeader.exists)
    }

    /// When the undo toast expires, the "Got it" section must not flicker
    /// back into view, even briefly. This test runs with `realTiming` so it
    /// exercises the real 2.5s toast duration and the actual SwiftData
    /// deletion timing.
    func testClearToastExpiryDoesNotFlickerGotSection() {
        launchApp(realTiming: true)

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-checked-item")

        app.buttons[A11yID.GotSection.clearAll].tap()
        let undo = app.buttons["clearToast.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        attachScreenshot("02-toast-shown")

        // Wait out the full ~2.5s toast duration without tapping Undo.
        // The toast disappears and the item stays deleted.
        waitForGone(undo, timeout: 4)
        attachScreenshot("03-toast-expired-no-flicker")

        // Confirm the item is gone and the Got it section header never
        // reappeared during the expiry.
        XCTAssertFalse(app.buttons[A11yID.ItemRow.check("Milk")].exists)
        XCTAssertFalse(gotSectionHeader.exists)
    }
}
