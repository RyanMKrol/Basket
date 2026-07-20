import XCTest

/// While the add bar is focused, the list behind it is blurred and covered by a
/// transparent scrim: tapping the blurred backdrop should ONLY dismiss the
/// keyboard, never fall through to a row underneath.
final class BlurDismissTests: BasketUITestCase {

    func testTappingBlurredBackdropDismissesKeyboardWithoutFallingThrough() {
        launchApp(seeded: true)

        // A check circle that, tapped directly, would check "Milk" off. We grab
        // its coordinate while it's still hittable (before focus/blur), then tap
        // that same screen point after focusing — it must hit the scrim instead.
        let milkCheck = app.buttons[A11yID.ItemRow.check("Milk")]
        XCTAssertTrue(milkCheck.waitForExistence(timeout: 5))
        waitForToGetCount(4)
        let checkPoint = milkCheck.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        attachScreenshot("01-before-focus")

        // Focus the add bar → blur + scrim appear; the keyboard-down button only
        // exists while focused, so it's our proxy for "keyboard is up".
        app.textFields[A11yID.AddBar.textField].tap()
        let dismissButton = app.buttons[A11yID.AddBar.dismissKeyboard]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 3), "add bar never focused")
        attachScreenshot("02-focused-blurred")

        // Tap where Milk's check circle is — over the blurred backdrop.
        checkPoint.tap()
        attachScreenshot("03-after-backdrop-tap")

        // The keyboard dismissed…
        waitForGone(dismissButton)
        // …and the tap did NOT fall through: nothing was checked off.
        waitForToGetCount(4)
        assertStaysGone(gotSectionHeader)
        waitForLabel(milkCheck, equals: "Not got yet")
    }

    /// Sanity counter-check: the check circle still works normally (no scrim in
    /// the way) when the add bar is NOT focused, so the scrim didn't break
    /// ordinary check-off.
    func testCheckCircleStillWorksWhenNotFocused() {
        launchApp(seeded: true)

        let milkCheck = app.buttons[A11yID.ItemRow.check("Milk")]
        XCTAssertTrue(milkCheck.waitForExistence(timeout: 5))
        milkCheck.tap()

        waitForLabel(milkCheck, equals: "Got it")
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
    }
}
