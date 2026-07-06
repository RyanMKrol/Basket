import XCTest

/// End-to-end persistence coverage. Every other UI test runs on a throwaway
/// in-memory store, so nothing else verifies that data actually survives a
/// cold start — or that the "Got it" TTL holds across one. These launch the
/// app against a temp *file* store (see UITEST_STORE_URL in TestHooks),
/// terminate it, and launch again.
final class PersistenceFlowTests: BasketUITestCase {
    /// A unique store path per test, so parallel/repeated runs can't bleed
    /// into each other. The file lives in the simulator's temp dir.
    private let storePath = FileManager.default.temporaryDirectory
        .appendingPathComponent("basket-uitest-\(UUID().uuidString).store").path

    /// Background the app before killing it. SwiftData's autosave is
    /// debounced, and `terminate()` alone can beat it to disk, silently
    /// losing the change being tested; backgrounding is the moment both
    /// autosave and the app's own scene-phase flush run — same as a real
    /// user switching away before iOS eventually kills the process.
    private func backgroundThenTerminate() {
        XCUIDevice.shared.press(.home)
        let backgrounded = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "state == %d",
                                   XCUIApplication.State.runningBackground.rawValue),
            object: app)
        XCTAssertEqual(XCTWaiter().wait(for: [backgrounded], timeout: 5), .completed,
                       "app never reached the background")
        app.terminate()
    }

    func testAddedItemSurvivesRelaunch() {
        app.launchEnvironment["UITEST_STORE_URL"] = storePath
        launchApp(seeded: false)

        let field = app.textFields["addBar.textField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Bananas")
        app.buttons["addBar.addButton"].tap()
        XCTAssertTrue(app.buttons["itemRow.Bananas"].waitForExistence(timeout: 5))
        attachScreenshot("01-before-relaunch")

        backgroundThenTerminate()
        app.launch()   // same arguments + environment → same store file

        XCTAssertTrue(app.buttons["itemRow.Bananas"].waitForExistence(timeout: 5))
        waitForToGetCount(1)
        attachScreenshot("02-after-relaunch")
    }

    /// The 1-hour "Got it" TTL is enforced across launches: check an item
    /// off at the frozen 09:00, relaunch at a frozen 11:30, and it has been
    /// purged rather than restored.
    func testGotItemExpiresAcrossRelaunch() {
        app.launchEnvironment["UITEST_STORE_URL"] = storePath
        launchApp()

        app.buttons["itemRow.check.Milk"].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-checked-at-0900")

        backgroundThenTerminate()
        app.launchEnvironment["UITEST_FROZEN_DATE"] = "2026-07-15T11:30:00Z"
        app.launch()

        waitForToGetCount(3)
        waitForGone(gotSectionHeader, timeout: 5)
        XCTAssertFalse(app.buttons["itemRow.Milk"].exists,
                       "expired item should be deleted, not restored to the list")
        attachScreenshot("02-purged-at-1130")
    }
}
