import XCTest
@testable import Basket

final class EmojiTests: XCTestCase {
    func testKnownFoodsMapToGlyphs() {
        XCTAssertEqual(Emoji.forName("Milk"), "🥛")
        XCTAssertEqual(Emoji.forName("almond milk"), "🥛")
        XCTAssertEqual(Emoji.forName("Sourdough bread"), "🍞")
        XCTAssertEqual(Emoji.forName("red apples"), "🍎")
        XCTAssertEqual(Emoji.forName("Tomatoes"), "🍅")
        XCTAssertEqual(Emoji.forName("Toilet roll"), "🧻")
    }

    func testUnknownFallsBackToCart() {
        XCTAssertEqual(Emoji.forName("widget"), Emoji.fallback)
        XCTAssertEqual(Emoji.forName(""), Emoji.fallback)
    }
}
