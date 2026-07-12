import XCTest

/// Stress-tests the app's smallest, most precision-sensitive controls with
/// taps offset from dead-center — standing in for a real finger, since
/// XCUITest's default `.tap()` always lands exactly on the accessibility
/// center, which a fingertip never does.
///
/// Every trial is asserted individually and nothing is averaged away: if a
/// control's hit target is too small to reliably reach with a realistic
/// offset, that's a UX bug to go fix, not a flaky result to tolerate at some
/// pass-rate threshold. All trials run against a fixed seed, so a failure at
/// a given trial index reproduces exactly on rerun.
final class TapPrecisionTests: BasketUITestCase {
    private let trialsPerControl = 8
    /// Max offset from center, as a fraction of the control's own size.
    private let jitterMagnitude = 0.3
    /// Per-trial settle deadline. Generous relative to the (animation-free)
    /// updates being waited on, so a timeout means a genuinely missed tap.
    private let trialTimeout: TimeInterval = 2

    /// The +/- stepper buttons are 32x32 — right at the edge of Apple's
    /// 44x44 minimum tap-target guidance — so they're the single most likely
    /// control in the app to fail under an imprecise tap.
    func testJitteredStepperTaps() {
        launchApp()
        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))

        var jitter = SeededJitter(seed: 0xBA5C_E7A1)
        // Milk starts at 500 ml; step() adds 50 while under 1000.
        let expected = [550, 600, 650, 700, 750, 800, 850, 900].map { "\($0) ml" }
        var misses: [String] = []

        for i in 0..<trialsPerControl {
            let dx = jitter.next() * jitterMagnitude
            let dy = jitter.next() * jitterMagnitude
            app.buttons[A11yID.QuantityEditor.increase].tapJittered(dx: dx, dy: dy)
            if !waitUntilLabel(value, equals: expected[i], timeout: trialTimeout) {
                misses.append("trial \(i) (dx: \(String(format: "%.2f", dx)), dy: \(String(format: "%.2f", dy))): got '\(value.label)', want '\(expected[i])'")
            }
        }

        XCTAssertTrue(misses.isEmpty, "Jittered stepper taps missed:\n" + misses.joined(separator: "\n"))
    }

    /// Unit pills are small, text-sized capsules — alternate two of them
    /// (ml/L) so every trial is a genuine, independently-verifiable state
    /// change rather than a no-op re-tap of the same selection.
    func testJitteredUnitPillTaps() {
        launchApp()
        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))

        var jitter = SeededJitter(seed: 0xBA5C_E7B2)
        var misses: [String] = []

        for i in 0..<trialsPerControl {
            let toLiters = i % 2 == 0
            let identifier = toLiters ? A11yID.QuantityEditor.unit("L") : A11yID.QuantityEditor.unit("ml")
            let want = toLiters ? "0.5 L" : "500 ml"

            let dx = jitter.next() * jitterMagnitude
            let dy = jitter.next() * jitterMagnitude
            app.buttons[identifier].tapJittered(dx: dx, dy: dy)
            if !waitUntilLabel(value, equals: want, timeout: trialTimeout) {
                misses.append("trial \(i) tapping \(identifier) (dx: \(String(format: "%.2f", dx)), dy: \(String(format: "%.2f", dy))): got '\(value.label)', want '\(want)'")
            }
        }

        XCTAssertTrue(misses.isEmpty, "Jittered unit pill taps missed:\n" + misses.joined(separator: "\n"))
    }

    /// The check circle is the single most-used gesture in the whole app —
    /// worth stress-testing even though, at 40x40, it's a shade under the
    /// stepper buttons' risk.
    func testJitteredCheckCircleTaps() {
        launchApp()
        let check = app.buttons[A11yID.ItemRow.check("Milk")]
        XCTAssertTrue(check.waitForExistence(timeout: 5))

        var jitter = SeededJitter(seed: 0xBA5C_E7C3)
        var misses: [String] = []

        for i in 0..<trialsPerControl {
            let checking = i % 2 == 0
            let want = checking ? "Got it" : "Not got yet"
            let dx = jitter.next() * jitterMagnitude
            let dy = jitter.next() * jitterMagnitude
            check.tapJittered(dx: dx, dy: dy)
            if !waitUntilLabel(check, equals: want, timeout: trialTimeout) {
                misses.append("trial \(i) (dx: \(String(format: "%.2f", dx)), dy: \(String(format: "%.2f", dy))): got '\(check.label)', want '\(want)'")
            }
            // A check isn't finished when its label flips — the row only
            // moves into (or out of) "Got it" once the commit lands, and a
            // tap in that window is swallowed by the app's re-entrancy
            // guard. Wait for the section itself so the next trial measures
            // tap precision, not rapid-tap protection.
            waitUntilExists(gotSectionHeader, checking, timeout: trialTimeout)
        }

        XCTAssertTrue(misses.isEmpty, "Jittered check-circle taps missed:\n" + misses.joined(separator: "\n"))
    }
}
