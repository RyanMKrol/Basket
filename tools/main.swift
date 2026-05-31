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

print("Emoji — categories:")
check(Emoji.forName("Milk") == "🥛", "Milk → 🥛")
check(Emoji.forName("almond milk") == "🥛", "almond milk → 🥛")
check(Emoji.forName("Sourdough bread") == "🍞", "Sourdough → 🍞")
check(Emoji.forName("Cheddar") == "🧀", "Cheddar → 🧀")
check(Emoji.forName("Salmon fillet") == "🐟", "Salmon → 🐟")
check(Emoji.forName("Chicken breast") == "🍗", "Chicken breast → 🍗")
check(Emoji.forName("Bananas") == "🍌", "Bananas → 🍌")
check(Emoji.forName("Spaghetti") == "🍝", "Spaghetti → 🍝")
check(Emoji.forName("Basmati rice") == "🍚", "Basmati rice → 🍚")
check(Emoji.forName("Coffee") == "☕", "Coffee → ☕")
check(Emoji.forName("Red wine") == "🍷", "Red wine → 🍷")
check(Emoji.forName("Orange juice") == "🧃", "Orange juice → 🧃")
check(Emoji.forName("Chickpeas") == "🫘", "Chickpeas → 🫘")
check(Emoji.forName("Olive oil") == "🫒", "Olive oil → 🫒")
check(Emoji.forName("Paprika") == "🧂", "Paprika → 🧂")
check(Emoji.forName("Dark chocolate") == "🍫", "Dark chocolate → 🍫")

print("Emoji — non-food:")
check(Emoji.forName("Toilet roll") == "🧻", "Toilet roll → 🧻 (not 'oil')")
check(Emoji.forName("Washing up liquid") == "🧴", "washing up liquid → 🧴")
check(Emoji.forName("Toothpaste") == "🪥", "Toothpaste → 🪥")
check(Emoji.forName("Dog food") == "🐾", "Dog food → 🐾")
check(Emoji.forName("Ibuprofen") == "💊", "Ibuprofen → 💊")

print("Emoji — tricky prefix collisions:")
check(Emoji.forName("Peach") == "🍑", "peach not 'pea'")
check(Emoji.forName("Peas") == "🫛", "peas → 🫛")
check(Emoji.forName("Eggplant") == "🍆", "eggplant not 'egg'")
check(Emoji.forName("Hamburger") == "🍔", "hamburger not 'ham'")
check(Emoji.forName("Cornflour") == "🥣", "cornflour not 'corn'")
check(Emoji.forName("Ginger") == "🥔", "ginger not 'gin'")
check(Emoji.forName("Brandy") == "🥃", "brandy not 'bran'")
check(Emoji.forName("Portobello mushrooms") == "🍄", "portobello not 'port'")
check(Emoji.forName("Shampoo") == "🧴", "shampoo not 'ham'")
check(Emoji.forName("Pineapple") == "🍍", "pineapple not 'apple'")
check(Emoji.forName("T-bone steak") == "🥩", "hyphenated t-bone")
check(Emoji.forName("Ice cream") == "🍦", "multi-word beats 'cream'")
check(Emoji.forName("Strawberries") == "🍓", "stem: strawberries")
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

print("Semantic fallback (NLEmbedding):")
check(Emoji.forName("Flounder") == "🐟", "novel fish Flounder → 🐟")
check(Emoji.forName("Grouper") == "🐟", "novel fish Grouper → 🐟")
check(Emoji.forName("Frozen peas") == Emoji.forName("Peas"), "frozen peas == peas (variant collapse)")
check(Emoji.forName("Smoked haddock") == "🐟", "smoked haddock → 🐟")
check(Emoji.forName("qwertyuiop") == Emoji.fallback, "nonsense → basket fallback")
check(Emoji.forName("") == Emoji.fallback, "empty → basket fallback")

print("Combined suggestions (history + dictionary):")
let dict = ["Tomatoes", "Tomato Soup", "Tomato Ketchup", "Milk", "Bananas"]
let hist = [SuggestionCandidate(name: "Harissa", timesAdded: 3, lastAddedAt: now)]
let r1 = Suggestions.combined(query: "tom", history: [], dictionary: dict, onList: [], now: now)
check(r1.map(\.name).contains("Tomatoes"), "dictionary autocomplete: tom → Tomatoes")
let r2 = Suggestions.combined(query: "tom", history: [], dictionary: dict, onList: ["tomatoes"], now: now)
check(!r2.map(\.name).contains("Tomatoes"), "on-list Tomatoes excluded")
check(r2.map(\.name).contains("Tomato Soup"), "but Tomato Soup still suggested")
let r3 = Suggestions.combined(query: "har", history: hist, dictionary: dict, onList: [], now: now)
check(r3.first?.name == "Harissa", "personal history ranks first")
check(Suggestions.combined(query: "  ", history: hist, dictionary: dict, onList: [], now: now).isEmpty,
      "empty query → nothing")

print("Capitalisation:")
check("milk".capitalisedFirstLetter == "Milk", "milk → Milk")
check("olive oil".capitalisedFirstLetter == "Olive oil", "olive oil → Olive oil (only first)")
check("BBQ sauce".capitalisedFirstLetter == "BBQ sauce", "BBQ sauce unchanged")
check("".capitalisedFirstLetter == "", "empty stays empty")

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
