import XCTest

/// Proves Theme's `relativeTo:` threading actually scales rendered text with
/// the user's Dynamic Type setting, not just that it compiles.
final class DynamicTypeTests: BasketUITestCase {
    func testItemNameScalesUnderAccessibilityContentSize() {
        launchApp()
        let defaultLabel = app.buttons[A11yID.ItemRow.nameLabel("Milk")]
        XCTAssertTrue(defaultLabel.waitForExistence(timeout: 5))
        let defaultHeight = defaultLabel.frame.height
        attachScreenshot("01-default-content-size")
        app.terminate()

        app.launchArguments = ["-uiTesting", "-uiTestingDisableAnimations",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"]
        app.launchEnvironment["UITEST_FROZEN_DATE"] = Self.frozenDate
        app.launchEnvironment["TZ"] = "Europe/London"
        app.launch()

        let scaledLabel = app.buttons[A11yID.ItemRow.nameLabel("Milk")]
        XCTAssertTrue(scaledLabel.waitForExistence(timeout: 5))
        let scaledHeight = scaledLabel.frame.height
        attachScreenshot("02-accessibility-content-size")

        XCTAssertGreaterThan(scaledHeight, defaultHeight,
                              "Item name label should render taller under an accessibility content size, since Theme fonts now scale via relativeTo:")
    }

    /// Visual evidence for T052: at the largest supported accessibility
    /// content size, the main list, quantity editor, empty state, and about
    /// sheet all still render their key elements — no crash, no vanished
    /// content — even though EmptyStateView's title and the quantity value
    /// are internally capped at `.accessibility2` (see their doc comments).
    func testLargestAccessibilitySizeScreensRenderWithoutBreaking() {
        app.launchArguments = ["-uiTesting", "-uiTestingDisableAnimations",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["UITEST_FROZEN_DATE"] = Self.frozenDate
        app.launchEnvironment["TZ"] = "Europe/London"
        app.launch()

        XCTAssertTrue(app.buttons[A11yID.ItemRow.row("Milk")].waitForExistence(timeout: 5))
        attachScreenshot("01-main-list-accessibilityXXXL")

        app.buttons[A11yID.ItemRow.row("Milk")].tap()
        XCTAssertTrue(app.buttons[A11yID.QuantityEditor.value].waitForExistence(timeout: 3))
        attachScreenshot("02-quantity-editor-accessibilityXXXL")

        app.terminate()
        app.launchArguments = ["-uiTesting", "-uiTestingEmpty", "-uiTestingDisableAnimations",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["UITEST_FROZEN_DATE"] = Self.frozenDate
        app.launchEnvironment["TZ"] = "Europe/London"
        app.launch()
        XCTAssertTrue(app.staticTexts["emptyState.subtitle"].waitForExistence(timeout: 5))
        attachScreenshot("03-empty-state-accessibilityXXXL")

        app.buttons[A11yID.Header.aboutButton].tap()
        XCTAssertTrue(app.staticTexts["about.title"].waitForExistence(timeout: 3))
        attachScreenshot("04-about-sheet-accessibilityXXXL")
    }
}
