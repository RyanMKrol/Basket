import XCTest

final class AddItemFlowTests: BasketUITestCase {
    /// Empty list → type a new item → it appears as a row on the to-get list.
    func testAddingItemAppearsInList() {
        launchApp(seeded: false)

        XCTAssertTrue(app.staticTexts["emptyState.subtitle"].waitForExistence(timeout: 5))
        attachScreenshot("01-empty-state")

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Bananas")
        attachScreenshot("02-typed-item")

        app.buttons[A11yID.AddBar.addButton].tap()

        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Bananas")].waitForExistence(timeout: 5))
        waitForToGetCount(1)
        attachScreenshot("03-item-added")
    }

    /// Re-adding an item already on the list bumps + flashes it rather than
    /// creating a duplicate row.
    func testReAddingExistingItemDoesNotDuplicate() {
        launchApp(seeded: false)

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        field.tap()
        field.typeText("Bananas")
        app.buttons[A11yID.AddBar.addButton].tap()
        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Bananas")].waitForExistence(timeout: 5))

        field.tap()
        field.typeText("Bananas")
        app.buttons[A11yID.AddBar.addButton].tap()
        attachScreenshot("01-readded")

        waitForToGetCount(1)
        XCTAssertEqual(app.buttons.matching(identifier: A11yID.ItemRow.row("Bananas")).count, 1)
    }

    /// Re-adding an item that's currently checked off (sitting in "Got it")
    /// restores it to the to-get list instead of creating a second row.
    func testReAddingCheckedOffItemRestoresIt() {
        launchApp()

        app.buttons[A11yID.ItemRow.check("Milk")].tap()
        XCTAssertTrue(gotSectionHeader.waitForExistence(timeout: 3))
        attachScreenshot("01-milk-checked-off")

        let field = app.textFields[A11yID.AddBar.textField]
        field.tap()
        field.typeText("Milk")
        app.buttons[A11yID.AddBar.addButton].tap()
        attachScreenshot("02-readded-from-got-it")

        waitForToGetCount(4)
        waitForLabel(app.buttons[A11yID.ItemRow.check("Milk")], equals: "Not got yet")
        XCTAssertEqual(app.buttons.matching(identifier: A11yID.ItemRow.row("Milk")).count, 1)
    }

    /// The keyboard-dismiss chevron only shows while the add bar is focused,
    /// and drops the keyboard without touching the draft text.
    func testDismissKeyboardButton() {
        launchApp(seeded: false)

        let field = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Bananas")

        let dismiss = app.buttons[A11yID.AddBar.dismissKeyboard]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 3))
        attachScreenshot("01-keyboard-up")

        dismiss.tap()
        attachScreenshot("02-keyboard-dismissed")

        waitForGone(dismiss)
        waitForValue(field, equals: "Bananas")
    }
}
