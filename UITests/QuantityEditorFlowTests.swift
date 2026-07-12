import XCTest

final class QuantityEditorFlowTests: BasketUITestCase {
    /// Tapping a row opens its inline quantity editor with a smart default
    /// (milk → ml); +/- steps the value, and a unit pill switches scale.
    func testOpeningEditorSteppingAndSwitchingUnit() {
        launchApp()

        let milkRow = app.buttons[A11yID.ItemRow.row("Milk")]
        XCTAssertTrue(milkRow.waitForExistence(timeout: 5))
        milkRow.tap()

        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        waitForLabel(value, equals: "500 ml")
        attachScreenshot("01-editor-open-default")

        app.buttons[A11yID.QuantityEditor.increase].tap()
        waitForLabel(value, equals: "550 ml")
        attachScreenshot("02-after-increase")

        app.buttons[A11yID.QuantityEditor.decrease].tap()
        waitForLabel(value, equals: "500 ml")
        app.buttons[A11yID.QuantityEditor.decrease].tap()
        waitForLabel(value, equals: "450 ml")
        attachScreenshot("03-after-decrease")

        app.buttons[A11yID.QuantityEditor.unit("L")].tap()
        waitForLabel(value, equals: "0.45 L")
        attachScreenshot("04-switched-to-liters")
    }

    /// Tapping the value swaps in a keyboard field so an exact amount can be
    /// typed straight in, instead of stepping one bucket at a time.
    func testTypingExactAmount() {
        launchApp()

        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        value.tap()

        let field = app.textFields[A11yID.QuantityEditor.field]
        XCTAssertTrue(field.waitForExistence(timeout: 3))

        // The field seeds with the current amount ("500"), cursor at the end —
        // back it out before typing the new one.
        let seeded = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: seeded.count))
        field.typeText("750")
        attachScreenshot("01-typed-exact-amount")

        // Committing happens when focus leaves the field — tapping another
        // row's body moves focus there (and closes Milk's editor, since only
        // one can be expanded at a time).
        app.buttons[A11yID.ItemRow.row("Eggs")].tap()

        let row = app.buttons[A11yID.ItemRow.row("Milk")]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        waitForLabel(row, equals: "Milk, 750 ml")
        attachScreenshot("02-committed")
    }

    /// The clear button drops the quantity back to the unset "+ Qty" state.
    func testClearingQuantity() {
        launchApp()

        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        XCTAssertTrue(app.buttons[A11yID.QuantityEditor.value].waitForExistence(timeout: 3))
        attachScreenshot("01-editor-open")

        app.buttons[A11yID.QuantityEditor.clear].tap()
        attachScreenshot("02-cleared")

        waitForGone(app.buttons[A11yID.QuantityEditor.value])
    }

    /// Typing an amount that doesn't parse to a positive number (here, just
    /// "0") is rejected on commit — the previous quantity stands.
    func testTypingInvalidAmountKeepsOldValue() {
        launchApp()

        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        value.tap()

        let field = app.textFields[A11yID.QuantityEditor.field]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let seeded = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: seeded.count))
        field.typeText("0")
        attachScreenshot("01-typed-zero")

        app.buttons[A11yID.ItemRow.row("Eggs")].tap()

        let row = app.buttons[A11yID.ItemRow.row("Milk")]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        waitForLabel(row, equals: "Milk, 500 ml")
        attachScreenshot("02-unchanged")
    }
}
