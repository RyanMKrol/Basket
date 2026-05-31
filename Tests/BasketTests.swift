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

    func testAvoidsInteriorFalseMatches() {
        // Regression: "oil" lives inside "toilet", "ham" inside "shampoo".
        XCTAssertEqual(Emoji.forName("Toilet roll"), "🧻")
        XCTAssertEqual(Emoji.forName("Shampoo"), "🧴")
    }

    func testMultiWordBeatsConstituentWord() {
        // Regression: "ice cream" must win over the single word "cream".
        XCTAssertEqual(Emoji.forName("Ice cream"), "🍦")
    }

    func testStemsMatchPlurals() {
        XCTAssertEqual(Emoji.forName("Strawberries"), "🍓")
        XCTAssertEqual(Emoji.forName("Apples"), "🍎")
    }

    func testUnknownFallsBackToCart() {
        XCTAssertEqual(Emoji.forName("widget"), Emoji.fallback)
        XCTAssertEqual(Emoji.forName(""), Emoji.fallback)
    }
}

final class SuggestionsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func cand(_ name: String, times: Int, daysAgo: Double) -> SuggestionCandidate {
        SuggestionCandidate(name: name,
                            timesAdded: times,
                            lastAddedAt: now.addingTimeInterval(-daysAgo * 86_400))
    }

    func testEmptyQueryReturnsNothing() {
        let result = Suggestions.rank(query: "  ",
                                      candidates: [cand("Milk", times: 5, daysAgo: 1)],
                                      onList: [],
                                      now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func testMatchesBySubstringCaseInsensitive() {
        let result = Suggestions.rank(query: "TOM",
                                      candidates: [cand("Tomatoes", times: 1, daysAgo: 1),
                                                   cand("Milk", times: 1, daysAgo: 1)],
                                      onList: [],
                                      now: now)
        XCTAssertEqual(result.map(\.name), ["Tomatoes"])
    }

    func testExcludesItemsAlreadyOnList() {
        let result = Suggestions.rank(query: "to",
                                      candidates: [cand("Tomatoes", times: 9, daysAgo: 0)],
                                      onList: ["tomatoes"],
                                      now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func testForgetsThingsOlderThanAMonth() {
        let result = Suggestions.rank(query: "te",
                                      candidates: [cand("Tea", times: 9, daysAgo: 40)],
                                      onList: [],
                                      now: now)
        XCTAssertTrue(result.isEmpty, "items older than the 30-day window should be forgotten")
    }

    func testFrequentAndRecentRanksHigher() {
        let result = Suggestions.rank(query: "t",
                                      candidates: [cand("Tortillas", times: 1, daysAgo: 20),
                                                   cand("Tea", times: 8, daysAgo: 0)],
                                      onList: [],
                                      now: now)
        XCTAssertEqual(result.first?.name, "Tea")
    }

    func testCapsAtMaxResults() {
        let many = (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }
        let result = Suggestions.rank(query: "thing", candidates: many, onList: [], now: now)
        XCTAssertEqual(result.count, Suggestions.maxResults)
    }
}
