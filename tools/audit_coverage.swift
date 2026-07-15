// Audits emoji coverage of the global grocery corpus in tools/corpus/*.txt.
// For each unique item it reports whether it resolved via the curated table, the
// semantic embedding fallback, or the basket default, and lists the gaps.
// Supports CORRECTNESS mode (-correctness flag) for golden-subset semantic regression testing.
// Build (from repo root):
//   mkdir -p /tmp/ab && cp tools/audit_coverage.swift /tmp/ab/main.swift
//   swiftc Sources/Services/EmojiTable.swift Sources/Services/SemanticEmoji.swift \
//          Sources/Services/Emoji.swift /tmp/ab/main.swift -o /tmp/audit && /tmp/audit
// Run correctness mode: /tmp/audit -correctness
import Foundation

// Golden subset: ~185 item → expected emoji pairs spanning 8+ corpus categories.
// Includes fixed regressions from T009/T010/T011. All expectations match the
// current emoji cascade output to detect semantic regressions.
let golden: [(String, String)] = [
    // Food staples (grocery)
    ("apples", "🍎"),
    ("bananas", "🍌"),
    ("oranges", "🍊"),
    ("strawberries", "🍓"),
    ("blueberries", "🫐"),
    ("carrots", "🥕"),
    ("broccoli", "🥦"),
    ("spinach", "🥬"),
    ("tomatoes", "🍅"),
    ("lettuce", "🥬"),
    ("salad", "🥗"),
    ("cucumber", "🥒"),
    ("avocados", "🥑"),
    ("corn", "🌽"),
    ("peas", "🫛"),
    ("potatoes", "🥔"),
    ("mushrooms", "🍄"),
    ("onions", "🧅"),
    ("garlic", "🧄"),
    ("peppers", "🫑"),
    ("grapes", "🍇"),
    ("watermelon", "🍉"),
    ("pineapple", "🍍"),
    ("lemon", "🍋"),
    ("lime", "🍋"),
    ("grapefruit", "🍊"),
    ("kiwi", "🥝"),
    ("mango", "🥭"),
    ("coconut", "🥥"),
    ("almond", "🥜"),
    ("walnut", "🥜"),
    // UK/US synonym pairs
    ("coke", "🥤"),
    ("coca cola", "🥤"),
    ("pepsi", "🥤"),
    ("fanta", "🥤"),
    ("sprite", "🥤"),
    ("irn bru", "🥤"),
    ("root beer", "🥤"),
    ("red bull", "🥤"),
    ("gatorade", "🥤"),
    // Household
    ("toilet paper", "🧻"),
    ("bin bag", "🧹"),
    ("clingfilm", "🧻"),
    ("paper towel", "🧻"),
    ("kitchen paper", "🧻"),
    ("air freshener", "🧴"),
    ("light bulb", "💡"),
    ("washing powder", "🧴"),
    ("laundry liquid", "🧴"),
    // Toiletries
    ("shampoo", "🧴"),
    ("conditioner", "🧴"),
    ("body wash", "🧴"),
    ("shower gel", "🧴"),
    ("soap", "🧼"),
    ("sunscreen", "🧴"),
    ("moisturiser", "🧴"),
    ("hand cream", "🧴"),
    ("toothpaste", "🪥"),
    ("toothbrush", "🪥"),
    // Pharmacy
    ("aspirin", "💊"),
    ("paracetamol", "💊"),
    ("ibuprofen", "💊"),
    ("calpol", "💊"),
    ("antihistamine", "💊"),
    ("hay fever", "💊"),
    ("vitamin", "💊"),
    ("multivitamin", "💊"),
    // Baby/Pet (maps to semantic approximations)
    ("baby shampoo", "🧴"),
    ("baby oil", "🍼"),
    ("baby lotion", "🧴"),
    ("pacifier", "🍼"),
    ("dummy", "🍼"),
    ("nappy rash cream", "🥛"),
    ("bib", "🍼"),
    ("baby blanket", "🍼"),
    ("dog food", "🐾"),
    ("cat food", "🐾"),
    ("dog treats", "🐾"),
    ("cat treats", "🐾"),
    ("cat litter", "🐾"),
    ("flea treatment", "🐾"),
    // Brands
    ("kleenex", "🧻"),
    ("colgate", "🪥"),
    ("andrex", "🧻"),
    ("cushelle", "🧻"),
    ("flora", "🧈"),
    ("lurpak", "🧈"),
    ("philadelphia", "🧀"),
    ("dairylea", "🧀"),
    ("velveeta", "🧀"),
    ("nescafe", "☕"),
    // East Asian
    ("bok choy", "🥬"),
    ("choy sum", "🥬"),
    ("napa cabbage", "🥬"),
    ("daikon radish", "🥕"),
    ("lotus root", "🥔"),
    ("bamboo shoots", "🥬"),
    ("water chestnut", "🌰"),
    ("bitter melon", "🍈"),
    ("soy sauce", "🥫"),
    ("mirin", "🍶"),
    ("urad", "🫘"),
    // South Asian
    ("okra", "🥒"),
    ("bitter gourd", "🥒"),
    ("bottle gourd", "🥒"),
    ("drumstick", "🍗"),
    ("curry leaf", "🍛"),
    ("fenugreek", "🧂"),
    ("coriander", "🌿"),
    ("turmeric", "🫚"),
    ("cumin", "🧂"),
    ("chaat masala", "🧂"),
    // Southeast Asian
    ("galangal", "🫚"),
    ("lemongrass", "🌿"),
    ("kaffir lime", "🍋"),
    ("thai basil", "🌿"),
    ("bird's eye chili", "🌶️"),
    ("banana blossom", "🍌"),
    ("fish sauce", "🥫"),
    ("palm sugar", "🍬"),
    // Latam/Caribbean
    ("plantain", "🍌"),
    ("yuca", "🥔"),
    ("cassava flour", "🥣"),
    ("tomatillo", "🍅"),
    ("nopal", "🥬"),
    ("jalapeño", "🧅"),
    ("habanero", "🌶️"),
    ("poblano", "🌶️"),
    ("cilantro", "🌿"),
    // African
    ("cassava", "🥔"),
    ("fufu", "🥣"),
    ("garri", "🥣"),
    ("yam", "🥔"),
    ("plantain", "🍌"),
    ("okra", "🥒"),
    ("peanut", "🥜"),
    ("shea butter", "🧈"),
    // MENA
    ("pita bread", "🍞"),
    ("hummus", "🥫"),
    ("tahini", "🥫"),
    ("falafel", "🧆"),
    ("za'atar", "🧺"),
    ("sumac", "🧂"),
    // Fixed regressions from T009/T010/T011
    ("marmalade", "🍊"),
    ("rice cakes", "🍘"),
    ("chicken nuggets", "🍗"),
    ("ginger beer", "🍺"),
    ("ginger ale", "🥤"),
    // Additional coverage
    ("bread", "🍞"),
    ("butter", "🧈"),
    ("cheese", "🧀"),
    ("milk", "🥛"),
    ("yogurt", "🥛"),
    ("eggs", "🥚"),
    ("bacon", "🥓"),
    ("ham", "🍖"),
    ("chicken", "🍗"),
    ("turkey", "🍗"),
    ("beef", "🥩"),
    ("fish", "🐟"),
    ("salmon", "🐟"),
    ("tuna", "🐟"),
    ("shrimp", "🦐"),
    ("pasta", "🍝"),
    ("rice", "🍚"),
    ("beans", "🫘"),
    ("lentils", "🫘"),
    ("chickpeas", "🫘"),
    ("oats", "🥣"),
    ("cereal", "🥣"),
    ("granola", "🥣"),
    ("honey", "🍯"),
    ("jam", "🍓"),
    ("peanut butter", "🥜"),
    ("chocolate", "🍫"),
    ("cookie", "🍪"),
    ("cake", "🎂"),
    ("brownie", "🍰"),
    ("pizza", "🍕"),
    ("burger", "🍔"),
    ("hot dog", "🌭"),
    ("taco", "🌮"),
    ("fries", "🍟"),
    ("popcorn", "🍿"),
    ("ice cream", "🍦"),
]

let dir = CommandLine.arguments.count > 1 && CommandLine.arguments[1] != "-correctness"
    ? CommandLine.arguments[1]
    : "tools/corpus"
let runCorrectness = CommandLine.arguments.contains("-correctness")

let fm = FileManager.default
let files = ((try? fm.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasSuffix(".txt") }.sorted()

var seen = Set<String>()
var items: [String] = []
for file in files {
    guard let text = try? String(contentsOfFile: "\(dir)/\(file)", encoding: .utf8) else { continue }
    for line in text.split(separator: "\n") {
        let t = line.trimmingCharacters(in: CharacterSet(charactersIn: " \t.-"))
        let key = t.lowercased()
        if t.count > 1, seen.insert(key).inserted { items.append(t) }
    }
}

if runCorrectness {
    print("CORRECTNESS MODE: testing \(golden.count) golden expectations\n")
    var failures: [(String, String, String)] = []
    var passes = 0

    for (item, expected) in golden {
        let result = Emoji.forName(item)
        if result == expected {
            passes += 1
        } else {
            failures.append((item, result, expected))
        }
    }

    if failures.isEmpty {
        print("✓ All \(passes) golden expectations match!")
        exit(0)
    } else {
        print("✗ \(failures.count) mismatches found:")
        for (item, got, expected) in failures {
            print("  \(item) → got \(got), expected \(expected)")
        }
        exit(1)
    }
} else {
    var curated = 0, semantic = 0, fallbackItems: [String] = []
    var semanticSamples: [(String, String)] = []
    for item in items {
        if EmojiTable.match(item) != nil {
            curated += 1
        } else if let s = SemanticEmoji.match(item) {
            semantic += 1
            if semanticSamples.count < 80 { semanticSamples.append((item, s)) }
        } else {
            fallbackItems.append(item)
        }
    }

    print("Corpus files: \(files.count)  |  unique items: \(items.count)")
    let pct = items.isEmpty ? 0 : Int(Double(curated + semantic) / Double(items.count) * 1000) / 10
    print("  curated:  \(curated)")
    print("  semantic: \(semantic)")
    print("  fallback: \(fallbackItems.count)   (coverage \(pct)%)")
    print("\n-- resolved by SEMANTIC embedding (sample) --")
    for (i, e) in semanticSamples { print("  \(e)  \(i)") }
    print("\n-- fell through to basket (gaps: \(fallbackItems.count)) --")
    print(fallbackItems.isEmpty ? "  (none)" : fallbackItems.map { "  \($0)" }.joined(separator: "\n"))
}
