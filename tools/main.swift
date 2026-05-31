// Native (macOS) logic check for Basket's pure logic, compiled together with the
// app's real source files via swiftc — no simulator needed. This exists because
// this machine's Xcode lacks the iOS platform component xcodebuild needs to
// synthesise a simulator *test* destination. The XCTest suite in Tests/ covers
// the same cases for anyone whose Xcode can run it.
//
//   swiftc Sources/Services/Emoji.swift Sources/Services/Suggestions.swift \
//          Sources/Models/Suggestion.swift tools/main.swift -o /tmp/basket_check
//
import Foundation

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if cond { print("  ✓ \(msg)") } else { print("  ✗ FAIL: \(msg)"); failures += 1 }
}

let now = Date(timeIntervalSince1970: 1_700_000_000)
func cand(_ name: String, times: Int, daysAgo: Double) -> SuggestionCandidate {
    SuggestionCandidate(name: name, timesAdded: times,
                        lastAddedAt: now.addingTimeInterval(-daysAgo * 86_400))
}

print("Emoji:")
check(Emoji.forName("Milk") == "🥛", "Milk → 🥛")
check(Emoji.forName("almond milk") == "🥛", "almond milk → 🥛")
check(Emoji.forName("Sourdough bread") == "🍞", "Sourdough bread → 🍞")
check(Emoji.forName("red apples") == "🍎", "red apples → 🍎")
check(Emoji.forName("Tomatoes") == "🍅", "Tomatoes → 🍅")
check(Emoji.forName("Toilet roll") == "🧻", "Toilet roll → 🧻 (not 'oil')")
check(Emoji.forName("Shampoo") == "🧴", "Shampoo → 🧴 (not 'ham')")
check(Emoji.forName("Ice cream") == "🍦", "multi-word: Ice cream → 🍦")
check(Emoji.forName("Strawberries") == "🍓", "stem: Strawberries → 🍓")
check(Emoji.forName("widget") == Emoji.fallback, "unknown → fallback")

print("Suggestions:")
check(Suggestions.rank(query: " ", candidates: [cand("Milk", times: 5, daysAgo: 1)], onList: [], now: now).isEmpty,
      "empty query → nothing")
check(Suggestions.rank(query: "TOM", candidates: [cand("Tomatoes", times: 1, daysAgo: 1), cand("Milk", times: 1, daysAgo: 1)], onList: [], now: now).map(\.name) == ["Tomatoes"],
      "substring, case-insensitive")
check(Suggestions.rank(query: "to", candidates: [cand("Tomatoes", times: 9, daysAgo: 0)], onList: ["tomatoes"], now: now).isEmpty,
      "excludes items already on list")
check(Suggestions.rank(query: "te", candidates: [cand("Tea", times: 9, daysAgo: 40)], onList: [], now: now).isEmpty,
      "forgets things older than a month")
check(Suggestions.rank(query: "t", candidates: [cand("Tortillas", times: 1, daysAgo: 20), cand("Tea", times: 8, daysAgo: 0)], onList: [], now: now).first?.name == "Tea",
      "frequent + recent ranks higher")
check(Suggestions.rank(query: "thing", candidates: (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }, onList: [], now: now).count == Suggestions.maxResults,
      "caps at maxResults")

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
