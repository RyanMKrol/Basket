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
}
