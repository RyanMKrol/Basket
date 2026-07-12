import XCTest
@testable import Basket

final class FormattingTests: XCTestCase {
    func testCapitalisedFirstLetter() {
        XCTAssertEqual("milk".capitalisedFirstLetter, "Milk")
        XCTAssertEqual("olive oil".capitalisedFirstLetter, "Olive oil")
        XCTAssertEqual("BBQ sauce".capitalisedFirstLetter, "BBQ sauce")
        XCTAssertEqual("".capitalisedFirstLetter, "")
    }
}
