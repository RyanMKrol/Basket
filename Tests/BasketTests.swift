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

    func testShortKeywordsRequireExactWordMatch() {
        // Regression: short keywords ("pap", "carp", "ham") used to match any
        // word starting with them, causing "toilet paper" → 🥣, "carpet
        // cleaner" → 🐠, "hamper" → 🍖.
        XCTAssertNotEqual(Emoji.forName("Toilet paper"), "🥣")
        XCTAssertNotEqual(Emoji.forName("Paper towels"), "🥣")
        XCTAssertNotEqual(Emoji.forName("Carpet cleaner"), "🐠")
        XCTAssertNotEqual(Emoji.forName("Hamper"), "🍖")
        XCTAssertEqual(Emoji.forName("Pap"), "🥣")
        XCTAssertEqual(Emoji.forName("Ham"), "🍖")
        XCTAssertEqual(Emoji.forName("Hams"), "🍖")
        XCTAssertEqual(Emoji.forName("Carp"), "🐠")
        XCTAssertEqual(Emoji.forName("Figs"), "🍇")
        XCTAssertEqual(Emoji.forName("Peas"), "🫛")
        XCTAssertEqual(Emoji.forName("Yams"), "🥔")
        XCTAssertEqual(Emoji.forName("Strawberries"), "🍓")
    }

    func testHeadNounPreferredOverModifierWord() {
        // T010: when several simple keywords match different words of a
        // compound, the rightmost word (the head noun) wins.
        XCTAssertEqual(Emoji.forName("Ginger beer"), "🍺")
        XCTAssertEqual(Emoji.forName("Carrot cake"), "🎂")
        XCTAssertEqual(Emoji.forName("Mince pies"), "🥧")
        XCTAssertEqual(Emoji.forName("Assam tea"), "🍵")
        // "in"/"of" start a trailing modifier phrase excluded from the head
        // noun search, so "tuna" (not "water") wins here.
        XCTAssertEqual(Emoji.forName("Tuna in spring water"), "🐟")
        // Complex (multi-word) keyword matches keep absolute priority.
        XCTAssertEqual(Emoji.forName("Peanut butter"), "🥜")
        XCTAssertEqual(Emoji.forName("Sugar snap peas"), "🫛")
    }

    func testBroadCategoryCoverage() {
        XCTAssertEqual(Emoji.forName("Cheddar"), "🧀")
        XCTAssertEqual(Emoji.forName("Salmon fillet"), "🐟")
        XCTAssertEqual(Emoji.forName("Chicken breast"), "🍗")
        XCTAssertEqual(Emoji.forName("Spaghetti"), "🍝")
        XCTAssertEqual(Emoji.forName("Coffee"), "☕")
        XCTAssertEqual(Emoji.forName("Red wine"), "🍷")
        XCTAssertEqual(Emoji.forName("Chickpeas"), "🫘")
        XCTAssertEqual(Emoji.forName("Olive oil"), "🫒")
        XCTAssertEqual(Emoji.forName("Washing up liquid"), "🧴")
        XCTAssertEqual(Emoji.forName("Dog food"), "🐾")
    }

    func testPrefixCollisionsResolveToLongestMatch() {
        XCTAssertEqual(Emoji.forName("Peach"), "🍑")       // not "pea"
        XCTAssertEqual(Emoji.forName("Cornflour"), "🥣")   // not "corn"
        XCTAssertEqual(Emoji.forName("Ginger"), "🫚")      // corrected in T008
        XCTAssertEqual(Emoji.forName("Brandy"), "🥃")      // not "bran"
        XCTAssertEqual(Emoji.forName("Pineapple"), "🍍")   // not "apple"
        XCTAssertEqual(Emoji.forName("T-bone steak"), "🥩") // hyphenated keyword
    }

    func testUnknownFallsBackToBasket() {
        XCTAssertEqual(Emoji.forName("qwertyuiop"), Emoji.fallback)
        XCTAssertEqual(Emoji.forName(""), Emoji.fallback)
    }

    func testSemanticFallbackForNovelItems() {
        // Not in the curated table — resolved via on-device word embeddings.
        XCTAssertEqual(Emoji.forName("Flounder"), "🐟")
        XCTAssertEqual(Emoji.forName("Grouper"), "🐟")
    }

    func testVariantsCollapseToSameEmoji() {
        XCTAssertEqual(Emoji.forName("Frozen peas"), Emoji.forName("Peas"))
        XCTAssertEqual(Emoji.forName("Smoked haddock"), Emoji.forName("Haddock"))
    }

    func testGlobalCuisineItemsAreMapped() {
        // A spread of items from the global corpus — none should hit the basket.
        let items = ["Gochujang", "Kimchi", "Injera", "Berbere", "Jollof rice",
                     "Garri", "Banh mi", "Toor dal", "Paneer", "Halloumi",
                     "Falafel", "Tahini", "Gnocchi", "Chorizo", "Tempeh",
                     "Mochi", "Matcha", "Kombu", "Masa harina", "Plantain"]
        for item in items {
            XCTAssertNotEqual(Emoji.forName(item), Emoji.fallback, "\(item) should map to a real emoji")
        }
    }
}

final class SuggestionsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func cand(_ name: String, times: Int, daysAgo: Double) -> SuggestionCandidate {
        SuggestionCandidate(name: name,
                            timesAdded: times,
                            lastAddedAt: now.addingTimeInterval(-daysAgo * 86_400))
    }

    // History ranking is exercised through `combined` (the only path the app
    // uses); these pass an empty dictionary to isolate the history behaviour.
    private func ranked(_ query: String, _ candidates: [SuggestionCandidate],
                        onList: Set<String> = []) -> [Suggestion] {
        Suggestions.combined(query: query, history: candidates, dictionary: [],
                             onList: onList, now: now)
    }

    func testEmptyQueryReturnsNothing() {
        XCTAssertTrue(ranked("  ", [cand("Milk", times: 5, daysAgo: 1)]).isEmpty)
    }

    func testMatchesBySubstringCaseInsensitive() {
        let result = ranked("TOM", [cand("Tomatoes", times: 1, daysAgo: 1),
                                    cand("Milk", times: 1, daysAgo: 1)])
        XCTAssertEqual(result.map(\.name), ["Tomatoes"])
    }

    func testExcludesItemsAlreadyOnList() {
        let result = ranked("to", [cand("Tomatoes", times: 9, daysAgo: 0)],
                            onList: ["tomatoes"])
        XCTAssertTrue(result.isEmpty)
    }

    func testForgetsThingsOlderThanAMonth() {
        let result = ranked("te", [cand("Tea", times: 9, daysAgo: 40)])
        XCTAssertTrue(result.isEmpty, "items older than the 30-day window should be forgotten")
    }

    func testFrequentAndRecentRanksHigher() {
        let result = ranked("t", [cand("Tortillas", times: 1, daysAgo: 20),
                                  cand("Tea", times: 8, daysAgo: 0)])
        XCTAssertEqual(result.first?.name, "Tea")
    }

    func testCapsAtCombinedMax() {
        let many = (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }
        XCTAssertEqual(ranked("thing", many).count, Suggestions.combinedMax)
    }

    // The add-bar suggestion stack is capped at 3 rows (T039). Pins the concrete
    // value so the symbolic caps tests above can't silently drift back to 4.
    func testCombinedMaxIsThree() {
        XCTAssertEqual(Suggestions.combinedMax, 3)
    }

    func testCombinedShowsAtMostThreeRows() {
        let many = (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }
        XCTAssertEqual(ranked("thing", many).count, 3)
    }

    func testUsualsShowsAtMostThreeRows() {
        let many = (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }
        XCTAssertEqual(Suggestions.usuals(history: many, onList: [], now: now).count, 3)
    }

    private let dict = ["Tomatoes", "Tomato Soup", "Tomato Ketchup", "Milk", "Bananas"]

    func testCombinedAutocompletesFromDictionary() {
        let r = Suggestions.combined(query: "tom", history: [], dictionary: dict, onList: [], now: now)
        XCTAssertTrue(r.map(\.name).contains("Tomatoes"))
    }

    func testCombinedExcludesOnListButKeepsOthers() {
        let r = Suggestions.combined(query: "tom", history: [], dictionary: dict, onList: ["tomatoes"], now: now)
        XCTAssertFalse(r.map(\.name).contains("Tomatoes"))
        XCTAssertTrue(r.map(\.name).contains("Tomato Soup"))
    }

    func testCombinedRanksPersonalHistoryFirst() {
        let hist = [cand("Harissa", times: 3, daysAgo: 0)]
        let r = Suggestions.combined(query: "har", history: hist, dictionary: dict, onList: [], now: now)
        XCTAssertEqual(r.first?.name, "Harissa")
    }

    // MARK: - usuals (empty-query "your usuals" chips)

    func testUsualsRanksByFrequencyAndRecency() {
        let hist = [cand("Tortillas", times: 1, daysAgo: 20), cand("Tea", times: 8, daysAgo: 0)]
        let r = Suggestions.usuals(history: hist, onList: [], now: now)
        XCTAssertEqual(r.first?.name, "Tea")
    }

    func testUsualsExcludesItemsAlreadyOnList() {
        let hist = [cand("Milk", times: 5, daysAgo: 0)]
        let r = Suggestions.usuals(history: hist, onList: ["milk"], now: now)
        XCTAssertTrue(r.isEmpty)
    }

    func testUsualsCapsAtCombinedMax() {
        let many = (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }
        XCTAssertEqual(Suggestions.usuals(history: many, onList: [], now: now).count, Suggestions.combinedMax)
    }

    func testUsualsEmptyWithNoHistory() {
        XCTAssertTrue(Suggestions.usuals(history: [], onList: [], now: now).isEmpty)
    }

    func testUsualsForgetsThingsOlderThanAMonth() {
        let hist = [cand("Tea", times: 9, daysAgo: 40)]
        XCTAssertTrue(Suggestions.usuals(history: hist, onList: [], now: now).isEmpty)
    }
}
