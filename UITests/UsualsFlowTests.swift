import XCTest

final class UsualsFlowTests: BasketUITestCase {
    /// Focusing the empty add bar after some history exists surfaces "your
    /// usuals" chips — the same suggestion-chip UI as typed suggestions, just
    /// primed from history instead of the query. Tapping one adds it.
    func testFocusingEmptyAddBarShowsUsualsAndTapAdds() {
        launchApp(seeded: false)

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        // Seed history: add an item, then check it off and clear it so it's
        // no longer on the list — only remembered in history.
        field.tap()
        field.typeText("Banana")
        field.typeText("\n")
        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Banana")].waitForExistence(timeout: 5))

        // Adding keeps the add bar focused (rapid-add), which blurs + scrims the
        // list — dismiss the keyboard before interacting with a row, or the tap
        // just lands on the dismiss scrim.
        let dismiss = app.buttons[A11yID.AddBar.dismissKeyboard]
        dismiss.tap()
        waitForGone(dismiss)

        app.buttons[A11yID.ItemRow.check("Banana")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        app.buttons[A11yID.GotSection.clearAll].tap()
        waitForGone(gotSectionHeader)
        attachScreenshot("01-history-seeded-list-empty")

        // Dismiss and refocus the empty field to trigger the usuals path.
        field.tap()
        let usual = app.buttons[A11yID.AddBar.suggestion("Banana")]
        XCTAssertTrue(usual.waitForExistence(timeout: 3))
        attachScreenshot("02-usuals-chip-visible")

        usual.tap()

        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Banana")].waitForExistence(timeout: 5))
        waitForToGetCount(1)
        attachScreenshot("03-added-from-usual")
    }

    /// A brand-new install with no history shows no usuals chips when the
    /// empty add bar is focused.
    func testNoUsualsWithoutHistory() {
        launchApp(seeded: false)

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()

        // No suggestion chips of any kind should appear for a fresh install.
        assertStaysGone(app.buttons[A11yID.AddBar.suggestion("Banana")], for: 2)
    }
}
