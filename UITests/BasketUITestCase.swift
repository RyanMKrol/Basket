import XCTest

/// Shared launch, synchronization, and screenshot plumbing for the flow tests.
/// Every test launches its own fresh process against an in-memory SwiftData
/// store (see `-uiTesting` in `BasketApp.init`), so tests never touch real
/// on-device data and don't interfere with each other.
/// `@MainActor`: XCUITest UI automation (`XCUIApplication`, element queries/taps)
/// is main-actor-isolated under Swift 6; subclasses inherit the isolation.
@MainActor
class BasketUITestCase: XCTestCase {
    let app = XCUIApplication()

    /// The wall-clock instant every UI test runs at (via UITEST_FROZEN_DATE —
    /// see `TestHooks`): an ordinary mid-July morning, so there's no holiday
    /// accent on the empty state, the day-rotating empty-state line never
    /// changes, and the "Got it" TTL cutoff can't move mid-test. Without this,
    /// a run on Halloween renders different UI than the one that passed
    /// yesterday.
    static let frozenDate = "2026-07-15T09:00:00Z"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app. `seeded: false` starts from the empty state instead
    /// of the four starter items (Milk, Sourdough bread, Eggs, Tomatoes).
    ///
    /// By default the app runs deterministically: animations off, the 0.55s
    /// check-commit delay shrunk, and the clock frozen — so tests wait on
    /// state, not choreography. Pass `realTiming: true` to keep production
    /// animations and delays; exactly one flow test does, to keep the real
    /// choreography covered.
    @discardableResult
    func launchApp(seeded: Bool = true, realTiming: Bool = false) -> XCUIApplication {
        var args = ["-uiTesting"]
        if !seeded { args.append("-uiTestingEmpty") }
        if !realTiming { args.append("-uiTestingDisableAnimations") }
        app.launchArguments = args
        app.launchEnvironment["UITEST_FROZEN_DATE"] = Self.frozenDate
        // Pin the zone too, or the frozen instant still renders differently
        // (time-of-day tint, day-of-year line) across machines.
        app.launchEnvironment["TZ"] = "Europe/London"
        app.launch()
        return app
    }

    // MARK: - Synchronization

    // XCUITest gives no guarantee that a tap's effects have rendered by the
    // next line, so a bare XCTAssert on live UI state is a race — it can fail
    // on a slow run, or falsely pass by reading a stale-but-expected value.
    // Every assertion about UI state goes through one of these waits, including
    // absence checks via assertStaysGone (never a bare XCTAssertFalse on .exists).

    /// Waits for `element.label` to equal `expected`; on timeout, fails
    /// showing the label it last saw.
    func waitForLabel(_ element: XCUIElement, equals expected: String,
                      timeout: TimeInterval = 3,
                      file: StaticString = #filePath, line: UInt = #line) {
        if !waitUntilLabel(element, equals: expected, timeout: timeout) {
            XCTFail("Timed out waiting for label '\(expected)' — last saw '\(element.exists ? element.label : "<element gone>")'",
                    file: file, line: line)
        }
    }

    /// Non-failing form of `waitForLabel`, for trial-based tests that tally
    /// misses across many taps before asserting them all at once.
    @discardableResult
    func waitUntilLabel(_ element: XCUIElement, equals expected: String,
                        timeout: TimeInterval = 3) -> Bool {
        let done = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expected), object: element)
        return XCTWaiter().wait(for: [done], timeout: timeout) == .completed
    }

    /// Waits for `element.value` (as a string) to equal `expected`.
    func waitForValue(_ element: XCUIElement, equals expected: String,
                      timeout: TimeInterval = 3,
                      file: StaticString = #filePath, line: UInt = #line) {
        let done = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected), object: element)
        if XCTWaiter().wait(for: [done], timeout: timeout) != .completed {
            XCTFail("Timed out waiting for value '\(expected)' — last saw '\(element.value.map(String.init(describing:)) ?? "nil")'",
                    file: file, line: line)
        }
    }

    /// Waits for the element to stop existing (dismissals, removals).
    func waitForGone(_ element: XCUIElement, timeout: TimeInterval = 3,
                     file: StaticString = #filePath, line: UInt = #line) {
        if !waitUntilExists(element, false, timeout: timeout) {
            XCTFail("Timed out waiting for element to disappear: \(element)",
                    file: file, line: line)
        }
    }

    /// Non-failing existence wait (`exists == true` or `false`).
    @discardableResult
    func waitUntilExists(_ element: XCUIElement, _ exists: Bool = true,
                         timeout: TimeInterval = 3) -> Bool {
        let done = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == %@", NSNumber(value: exists)),
            object: element)
        return XCTWaiter().wait(for: [done], timeout: timeout) == .completed
    }

    /// Waits for the header's to-get counter to show `count` items. The one
    /// place the counter's display copy is asserted — flows say
    /// `waitForToGetCount(3)`, not `staticTexts["3 to get"]`.
    func waitForToGetCount(_ count: Int, timeout: TimeInterval = 3,
                           file: StaticString = #filePath, line: UInt = #line) {
        waitForLabel(app.staticTexts[A11yID.Header.count],
                     equals: A11yID.toGetCountText(count),
                     timeout: timeout, file: file, line: line)
    }

    /// Asserts the element stays absent for the whole settle window, failing
    /// the moment it appears. The bounded-wait counterpart of waitForGone for
    /// the "and it should NOT show up" case — a bare XCTAssertFalse(.exists)
    /// only proves absence at one instant.
    func assertStaysGone(_ element: XCUIElement, for window: TimeInterval = 1.5,
                         _ message: String = "",
                         file: StaticString = #filePath, line: UInt = #line) {
        if waitUntilExists(element, true, timeout: window) {
            let suffix = message.isEmpty ? "" : ": \(message)"
            XCTFail("Element should not appear but did\(suffix)",
                    file: file, line: line)
        }
    }

    /// The "Got it" section header — its presence means at least one checked
    /// item has fully committed into the section.
    var gotSectionHeader: XCUIElement { app.staticTexts[A11yID.GotSection.header] }

    // MARK: - Screenshots

    /// Attaches a screenshot of the current app state to the test report,
    /// kept even on a passing run so flows can be reviewed visually.
    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
