import XCTest
@testable import Basket

/// Proves TestHooks.isHostedByXCTest fires when the app is running as a
/// unit-test host (BasketTests linked into the Basket process), which is
/// what BasketApp.init relies on to bypass the real App Group store and
/// starter-item seeding during unit tests.
final class TestHostTests: XCTestCase {
    func testHostedByXCTestIsTrueUnderUnitTestHost() {
        XCTAssertTrue(TestHooks.isHostedByXCTest,
                       "XCTestCase should be loaded in-process when Basket is hosting BasketTests")
    }
}
