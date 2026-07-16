import XCTest

final class DeepLinkTests: BasketUITestCase {
    /// Cold launch via the basket://add deep link should open the app with the
    /// add bar focused and the keyboard up.
    func testColdLaunchWithDeepLink() {
        var args = ["-uiTesting"]
        app.launchArguments = args
        app.launchEnvironment["UITEST_FROZEN_DATE"] = Self.frozenDate
        app.launchEnvironment["TZ"] = "Europe/London"

        // Launch via the deep link.
        let url = URL(string: "basket://add")!
        app.open(url)

        // Wait for the app to launch and the add bar to be focused.
        let textField = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))

        // The keyboard dismiss button should be visible, indicating the keyboard is up.
        let dismissButton = app.buttons[A11yID.AddBar.dismissKeyboard]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 3))

        attachScreenshot("01-cold-launch-add-focused")
    }

    /// When the app is already running, opening the deep link should focus the
    /// add bar and raise the keyboard without affecting the list state.
    func testDeepLinkOnAlreadyRunningApp() {
        launchApp()

        // Verify the app is running with the list.
        waitForToGetCount(4)
        attachScreenshot("01-app-running")

        // Tap elsewhere to unfocus the add bar and dismiss the keyboard.
        app.staticTexts[A11yID.Header.count].tap()

        let textField = app.textFields[A11yID.AddBar.textField]
        let dismissButton = app.buttons[A11yID.AddBar.dismissKeyboard]

        // Wait for the keyboard to be dismissed (dismiss button should be gone).
        waitForGone(dismissButton)
        attachScreenshot("02-keyboard-dismissed")

        // Now open the deep link.
        let url = URL(string: "basket://add")!
        app.open(url)

        // The keyboard dismiss button should reappear, indicating focus returned.
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 3))
        attachScreenshot("03-deep-link-refocused")

        // The list state should be unchanged.
        waitForToGetCount(4)
    }

    /// A normal launch (no deep link) should not auto-focus the add bar.
    func testNormalLaunchDoesNotAutoFocus() {
        launchApp(seeded: false)

        let textField = app.textFields[A11yID.AddBar.textField]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))

        // The keyboard dismiss button should not be visible since focus is not set.
        let dismissButton = app.buttons[A11yID.AddBar.dismissKeyboard]
        assertStaysGone(dismissButton)

        attachScreenshot("01-normal-launch-not-focused")
    }
}
