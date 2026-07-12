import XCTest

final class SuggestionsFlowTests: BasketUITestCase {
    /// Typing a known word floats matching suggestion chips above the add
    /// bar; tapping one adds that item without needing to finish typing.
    func testTappingSuggestionChipAddsItem() {
        launchApp(seeded: false)

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Banana")

        let suggestion = app.buttons[A11yID.AddBar.suggestion("Banana")]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 3))
        attachScreenshot("01-suggestions-visible")

        suggestion.tap()

        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Banana")].waitForExistence(timeout: 5))
        waitForToGetCount(1)
        attachScreenshot("02-added-from-suggestion")
    }
}
