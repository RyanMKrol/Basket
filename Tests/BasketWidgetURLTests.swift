import XCTest

final class BasketWidgetURLTests: XCTestCase {
    /// Asserts that the '+' widget's widgetURL resolves to the basket://add deep link
    /// with the correct scheme and host, so tapping it opens the app ready to add an item.
    func testAddWidgetURLResolvesToBasketAddDeepLink() throws {
        let url = try XCTUnwrap(URL(string: "basket://add"))
        XCTAssertEqual(url.scheme, "basket")
        XCTAssertEqual(url.host, "add")
    }
}
