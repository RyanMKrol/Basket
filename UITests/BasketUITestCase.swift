import XCTest

/// Shared launch + screenshot plumbing for the flow tests below. Every test
/// launches its own fresh process against an in-memory SwiftData store (see
/// `-uiTesting` in `BasketApp.init`), so tests never touch real on-device data
/// and don't interfere with each other.
class BasketUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app. `seeded: false` starts from the empty state instead
    /// of the four starter items (Milk, Sourdough bread, Eggs, Tomatoes).
    @discardableResult
    func launchApp(seeded: Bool = true) -> XCUIApplication {
        app.launchArguments += ["-uiTesting"]
        if !seeded { app.launchArguments += ["-uiTestingEmpty"] }
        app.launch()
        return app
    }

    /// Attaches a screenshot of the current app state to the test report,
    /// kept even on a passing run so flows can be reviewed visually.
    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
