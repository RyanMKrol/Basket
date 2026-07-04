import XCTest

final class AddItemFlowTests: BasketUITestCase {
    /// Empty list → type a new item → it appears as a row on the to-get list.
    func testAddingItemAppearsInList() {
        launchApp(seeded: false)

        XCTAssertTrue(app.staticTexts["emptyState.subtitle"].waitForExistence(timeout: 5))
        attachScreenshot("01-empty-state")

        let field = app.textFields["addBar.textField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Bananas")
        attachScreenshot("02-typed-item")

        app.buttons["addBar.addButton"].tap()

        let row = app.buttons["itemRow.Bananas"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 to get"].waitForExistence(timeout: 3))
        attachScreenshot("03-item-added")
    }

    /// Re-adding an item already on the list bumps + flashes it rather than
    /// creating a duplicate row.
    func testReAddingExistingItemDoesNotDuplicate() {
        launchApp(seeded: false)

        let field = app.textFields["addBar.textField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        field.tap()
        field.typeText("Bananas")
        app.buttons["addBar.addButton"].tap()
        XCTAssertTrue(app.buttons["itemRow.Bananas"].waitForExistence(timeout: 5))

        field.tap()
        field.typeText("Bananas")
        app.buttons["addBar.addButton"].tap()
        attachScreenshot("01-readded")

        XCTAssertTrue(app.staticTexts["1 to get"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons.matching(identifier: "itemRow.Bananas").count, 1)
    }
}
