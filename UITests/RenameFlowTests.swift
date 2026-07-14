import XCTest

/// Tapping an item's name enters an inline rename, distinct from tapping the
/// rest of the row (which still opens the quantity editor).
final class RenameFlowTests: BasketUITestCase {
    func testTappingNameRenamesUpdatesEmojiKeepsPositionAndClearsQuantity() {
        launchApp()

        // Give Milk a quantity first, so we can assert it's cleared by the
        // rename — then close the editor back down.
        let milkRow = app.buttons[A11yID.ItemRow.row("Milk")]
        XCTAssertTrue(milkRow.waitForExistence(timeout: 5))
        milkRow.tap()
        XCTAssertTrue(app.buttons[A11yID.QuantityEditor.value].waitForExistence(timeout: 3))
        milkRow.tap()
        waitForGone(app.buttons[A11yID.QuantityEditor.value])
        attachScreenshot("01-quantity-set-and-closed")

        let milkYBeforeRename = milkRow.frame.minY

        let nameLabel = app.buttons[A11yID.ItemRow.nameLabel("Milk")]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 3))
        nameLabel.tap()

        let field = app.textFields[A11yID.ItemRow.renameField("Milk")]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        attachScreenshot("02-renaming")

        let seeded = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: seeded.count))
        field.typeText("Bananas\n")

        let renamedRow = app.buttons[A11yID.ItemRow.row("Bananas")]
        XCTAssertTrue(renamedRow.waitForExistence(timeout: 3))
        attachScreenshot("03-renamed")

        // Name changed, old row gone.
        XCTAssertFalse(app.buttons[A11yID.ItemRow.row("Milk")].exists)

        // Quantity cleared: the row's label is bare "Bananas" (no ", 500 ml"
        // suffix), which the row only carries when a quantity is set.
        waitForLabel(renamedRow, equals: "Bananas")

        // Emoji re-derived for the new name (EmojiTable maps "banana" → 🍌;
        // pinned independently, at the pure-logic level, in RenameLogicTests).
        let emoji = app.staticTexts[A11yID.ItemRow.emoji("Bananas")]
        XCTAssertTrue(emoji.waitForExistence(timeout: 3))
        XCTAssertEqual(emoji.label, "🍌")

        // List position unchanged — the renamed row sits exactly where
        // Milk's did.
        XCTAssertEqual(renamedRow.frame.minY, milkYBeforeRename, accuracy: 2)
    }

    /// An empty rename is rejected: the old name stands.
    func testEmptyRenameIsRejected() {
        launchApp()

        let nameLabel = app.buttons[A11yID.ItemRow.nameLabel("Milk")]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        nameLabel.tap()

        let field = app.textFields[A11yID.ItemRow.renameField("Milk")]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let seeded = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: seeded.count))
        attachScreenshot("01-cleared-field")
        field.typeText("\n")

        let milkRow = app.buttons[A11yID.ItemRow.row("Milk")]
        XCTAssertTrue(milkRow.waitForExistence(timeout: 3))
        attachScreenshot("02-rejected-name-unchanged")
    }

    /// Tapping the rest of the row (the "+ Qty" chip / stepper area) still
    /// opens the quantity editor — the exact regression risk this feature
    /// introduces, since the name now has its own competing tap target.
    func testQuantityChipStillOpensEditor() {
        launchApp()

        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        let value = app.buttons[A11yID.QuantityEditor.value]
        XCTAssertTrue(value.waitForExistence(timeout: 3))
        waitForLabel(value, equals: "500 ml")
        attachScreenshot("01-quantity-editor-still-opens")
    }
}
