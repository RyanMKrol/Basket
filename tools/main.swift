// Native (macOS) logic check for Basket's pure logic, compiled together with the
// app's real source files via swiftc — no simulator needed. This exists because
// this machine's Xcode lacks the iOS platform component xcodebuild needs to
// synthesise a simulator *test* destination. The XCTest suite in Tests/ covers
// the same cases for anyone whose Xcode can run it.
//
//   swiftc Sources/Services/Emoji.swift Sources/Services/EmojiTable.swift \
//          Sources/Services/SemanticEmoji.swift Sources/Services/Suggestions.swift \
//          Sources/Services/SuggestionDictionary.swift Sources/Models/Suggestion.swift \
//          Sources/Services/Formatting.swift \
//          Sources/Services/Measure.swift Sources/Services/Seasonality.swift \
//          tools/main.swift -o /tmp/basket_check && /tmp/basket_check
//
// (Emoji's cascade pulls in EmojiTable + SemanticEmoji; the dictionary checks
// pull in SuggestionDictionary; the capitalisation checks pull in Formatting;
// the smart-units checks pull in Measure — which now classifies by the emoji
// glyph, so it leans on Emoji too; the date flourishes pull in Seasonality —
// all must be on the swiftc line or it won't link.)
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

print("Suggestions (history ranking, via combined with an empty dictionary):")
func ranked(_ query: String, _ candidates: [SuggestionCandidate], onList: Set<String> = []) -> [Suggestion] {
    Suggestions.combined(query: query, history: candidates, dictionary: [], onList: onList, now: now)
}
check(ranked(" ", [cand("Milk", times: 5, daysAgo: 1)]).isEmpty,
      "empty query → nothing")
check(ranked("TOM", [cand("Tomatoes", times: 1, daysAgo: 1), cand("Milk", times: 1, daysAgo: 1)]).map(\.name) == ["Tomatoes"],
      "substring, case-insensitive")
check(ranked("to", [cand("Tomatoes", times: 9, daysAgo: 0)], onList: ["tomatoes"]).isEmpty,
      "excludes items already on list")
check(ranked("te", [cand("Tea", times: 9, daysAgo: 40)]).isEmpty,
      "forgets things older than a month")
check(ranked("t", [cand("Tortillas", times: 1, daysAgo: 20), cand("Tea", times: 8, daysAgo: 0)]).first?.name == "Tea",
      "frequent + recent ranks higher")
check(ranked("thing", (0..<10).map { cand("Thing\($0)", times: 1, daysAgo: 1) }).count == Suggestions.combinedMax,
      "caps at combinedMax")

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

print("Real dictionary (unified corpora + emoji vocabulary):")
check(SuggestionDictionary.items.contains("Cordial"),
      "Cordial is in the dictionary (emoji-known; was missing from typeahead)")
check(Suggestions.combined(query: "cord", history: [], dictionary: SuggestionDictionary.items,
                           onList: [], now: now).map(\.name).contains("Cordial"),
      "typing 'cord' now suggests Cordial")
check(SuggestionDictionary.items.allSatisfy { $0 == ($0.prefix(1).uppercased() + $0.dropFirst()) },
      "every dictionary entry is capitalised-first")

print("Capitalisation:")
check("milk".capitalisedFirstLetter == "Milk", "milk → Milk")
check("olive oil".capitalisedFirstLetter == "Olive oil", "olive oil → Olive oil (only first)")
check("BBQ sauce".capitalisedFirstLetter == "BBQ sauce", "BBQ sauce unchanged")
check("".capitalisedFirstLetter == "", "empty stays empty")

print("Measure — smart units:")
check(Measure.typeForName("Milk") == .volume, "Milk → volume")
check(Measure.typeForName("Almond milk") == .volume, "Almond milk → volume (not weight via 'almond')")
check(Measure.typeForName("Orange juice") == .volume, "Orange juice → volume")
check(Measure.typeForName("Olive oil") == .volume, "Olive oil → volume")
check(Measure.typeForName("Cordial") == .volume, "Cordial → volume")
check(Measure.typeForName("Chicken breast") == .weight, "Chicken breast → weight")
check(Measure.typeForName("Plain flour") == .weight, "Flour → weight")
check(Measure.typeForName("Cheddar") == .weight, "Cheddar → weight")
check(Measure.typeForName("Cream cheese") == .weight, "Cream cheese → weight (cheese glyph)")
check(Measure.typeForName("Potatoes") == .weight, "Potatoes → weight")
check(Measure.typeForName("Fresh basil") == .weight, "Fresh basil → weight (herb, not ml)")
check(Measure.typeForName("Habanero pepper") == .weight, "Habanero → weight (pepper, not ml)")
check(Measure.typeForName("Yoghurt drink") == .volume, "Yoghurt drink → volume (not grams)")
check(Measure.typeForName("Eggs") == .count, "Eggs → count")
check(Measure.typeForName("Toilet roll") == .count, "Toilet roll → count")
check(Measure.typeForName("Sourdough bread") == .count, "Bread → count")
check(Measure.typeForName("zzxqwflumph") == nil, "unrecognised item → nil")
check(Measure.defaultUnit(for: "Milk") == .milliliter, "Milk starts in ml")
check(Measure.defaultUnit(for: "Beef mince") == .gram, "Beef starts in g")
check(Measure.defaultUnit(for: "Eggs") == .count, "Eggs start as a count")
check(Measure.step(500, unit: .milliliter, up: true) == 550, "500 ml +50 = 550")
check(Measure.step(1000, unit: .gram, up: true) == 1100, "1000 g +100 = 1100 (bigger step ≥1kg)")
check(Measure.step(50, unit: .gram, up: false) == 50, "50 g floored, won't go to 0")
check(Measure.step(1, unit: .count, up: false) == 1, "count floored at 1")
check(Measure.changeUnit(500, from: .milliliter, to: .liter) == 0.5, "500 ml → 0.5 L (scale preserved)")
check(Measure.changeUnit(0.5, from: .liter, to: .milliliter) == 500, "0.5 L → 500 ml")
check(Measure.changeUnit(500, from: .milliliter, to: .count) == 1, "500 ml → units starts at 1 (not 500)")
check(Measure.changeUnit(2, from: .count, to: .milliliter) == 500, "units → ml uses the 500 default")
check(Measure.units(for: .volume) == [.milliliter, .liter, .count], "volume offers ml/L/units")
check(Measure.units(for: .weight) == [.gram, .kilogram, .count], "weight → g/kg/units (no ml)")
check(Measure.units(for: .count) == [.count], "counted things → units only")
check(Measure.units(for: nil) == [.milliliter, .liter, .gram, .kilogram, .count],
      "unrecognised → every unit")
check(Measure.units(for: Measure.typeForName("Fresh basil")) == [.gram, .kilogram, .count],
      "basil offers only g/kg/units")
check(Measure.format(500, unit: .milliliter) == "500 ml", "format → 500 ml")
check(Measure.format(1.5, unit: .kilogram) == "1.5 kg", "format → 1.5 kg")
check(Measure.format(2, unit: .count) == "2", "format count → 2 (no unit)")

print("Seasonality:")
var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(identifier: "UTC")!
func seasonDate(_ y: Int, _ m: Int, _ day: Int, _ h: Int = 12) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: day, hour: h))!
}
check(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 8), calendar: utc) == .morning, "8am → morning")
check(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 19), calendar: utc) == .evening, "7pm → evening")
check(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 2), calendar: utc) == .night, "2am → night")
check(Seasonality.holidayAccent(seasonDate(2026, 10, 31), calendar: utc) == "🎃", "Oct 31 → 🎃")
check(Seasonality.holidayAccent(seasonDate(2026, 12, 20), calendar: utc) == "🎄", "mid-December → 🎄")
check(Seasonality.holidayAccent(seasonDate(2026, 7, 4), calendar: utc) == nil, "ordinary July day → no accent")
check(Seasonality.emptyStateLine(seasonDate(2026, 3, 10), calendar: utc)
      == Seasonality.emptyStateLine(seasonDate(2026, 3, 10), calendar: utc), "empty-state line stable within a day")

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
