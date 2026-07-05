import XCTest

final class QuantityEditorFlowTests: BasketUITestCase {
    /// Tapping a row opens its inline quantity editor with a smart default
    /// (milk → ml); +/- steps the value, and a unit pill switches scale.
    func testOpeningEditorSteppingAndSwitchingUnit() {
        launchApp()

        let milkRow = app.buttons["itemRow.Milk"]
        XCTAssertTrue(milkRow.waitForExistence(timeout: 5))
        milkRow.tap()

        let value = app.buttons["quantityEditor.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        XCTAssertEqual(value.label, "500 ml")
        attachScreenshot("01-editor-open-default")

        app.buttons["quantityEditor.increase"].tap()
        XCTAssertEqual(app.buttons["quantityEditor.value"].label, "550 ml")
        attachScreenshot("02-after-increase")

        app.buttons["quantityEditor.decrease"].tap()
        app.buttons["quantityEditor.decrease"].tap()
        XCTAssertEqual(app.buttons["quantityEditor.value"].label, "450 ml")
        attachScreenshot("03-after-decrease")

        app.buttons["quantityEditor.unit.L"].tap()
        XCTAssertEqual(app.buttons["quantityEditor.value"].label, "0.45 L")
        attachScreenshot("04-switched-to-liters")
    }

    /// Tapping the value swaps in a keyboard field so an exact amount can be
    /// typed straight in, instead of stepping one bucket at a time.
    func testTypingExactAmount() {
        launchApp()

        app.buttons["itemRow.Milk"].tap()
        let value = app.buttons["quantityEditor.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        value.tap()

        let field = app.textFields["quantityEditor.field"]
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
        app.buttons["itemRow.Eggs"].tap()

        let row = app.buttons["itemRow.Milk"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertEqual(row.label, "Milk, 750 ml")
        attachScreenshot("02-committed")
    }

    /// The clear button drops the quantity back to the unset "+ Qty" state.
    func testClearingQuantity() {
        launchApp()

        app.buttons["itemRow.Milk"].tap()
        XCTAssertTrue(app.buttons["quantityEditor.value"].waitForExistence(timeout: 3))
        attachScreenshot("01-editor-open")

        app.buttons["quantityEditor.clear"].tap()
        attachScreenshot("02-cleared")

        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.buttons["quantityEditor.value"]
        )
        wait(for: [gone], timeout: 3)
    }

    /// Typing an amount that doesn't parse to a positive number (here, just
    /// "0") is rejected on commit — the previous quantity stands.
    func testTypingInvalidAmountKeepsOldValue() {
        launchApp()

        app.buttons["itemRow.Milk"].tap()
        let value = app.buttons["quantityEditor.value"]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        value.tap()

        let field = app.textFields["quantityEditor.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let seeded = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: seeded.count))
        field.typeText("0")
        attachScreenshot("01-typed-zero")

        app.buttons["itemRow.Eggs"].tap()

        let row = app.buttons["itemRow.Milk"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        XCTAssertEqual(row.label, "Milk, 500 ml")
        attachScreenshot("02-unchanged")
    }
}
