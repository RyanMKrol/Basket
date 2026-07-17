// Audits emoji coverage of the global grocery corpus in tools/corpus/*.txt.
// For each unique item it reports whether it resolved via the curated table, the
// semantic embedding fallback, or the basket default, and lists the gaps.
// Supports CORRECTNESS mode (-correctness flag) for golden-subset semantic regression testing.
// Supports SEMANTIC-REPORT mode (-semantic-report flag) to analyze semantic anchor mappings.
// Build (from repo root):
//   mkdir -p /tmp/ab && cp tools/audit_coverage.swift /tmp/ab/main.swift
//   swiftc Sources/Services/EmojiTable.swift Sources/Services/SemanticEmoji.swift \
//          Sources/Services/Emoji.swift /tmp/ab/main.swift -o /tmp/audit && /tmp/audit
// Run correctness mode: /tmp/audit -correctness
// Run semantic-report mode: /tmp/audit -semantic-report
import Foundation
import NaturalLanguage

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

let dir = CommandLine.arguments.count > 1 && CommandLine.arguments[1] != "-correctness" && CommandLine.arguments[1] != "-semantic-report"
    ? CommandLine.arguments[1]
    : "tools/corpus"
let runCorrectness = CommandLine.arguments.contains("-correctness")
let runSemanticReport = CommandLine.arguments.contains("-semantic-report")

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
} else if runSemanticReport {
    print("SEMANTIC-REPORT MODE: analyzing semantic anchor mappings\n")

    let anchors: [(String, String)] = [
        ("milk", "🥛"), ("cheese", "🧀"), ("butter", "🧈"), ("yogurt", "🥛"),
        ("cream", "🥛"), ("custard", "🍮"),
        ("bread", "🍞"), ("loaf", "🍞"), ("baguette", "🥖"), ("croissant", "🥐"),
        ("bagel", "🥯"), ("pancake", "🥞"), ("pretzel", "🥨"), ("waffle", "🧇"),
        ("fish", "🐟"), ("salmon", "🐟"), ("tuna", "🐟"), ("cod", "🐟"),
        ("shrimp", "🦐"), ("prawn", "🦐"), ("crab", "🦀"), ("lobster", "🦞"),
        ("oyster", "🦪"), ("clam", "🦪"), ("squid", "🦑"), ("octopus", "🦑"),
        ("chicken", "🍗"), ("turkey", "🍗"), ("duck", "🍗"), ("beef", "🥩"),
        ("steak", "🥩"), ("pork", "🥩"), ("lamb", "🥩"), ("veal", "🥩"),
        ("bacon", "🥓"), ("sausage", "🌭"), ("ham", "🍖"), ("meat", "🥩"),
        ("egg", "🥚"),
        ("apple", "🍎"), ("banana", "🍌"), ("orange", "🍊"), ("lemon", "🍋"),
        ("lime", "🍋"), ("grape", "🍇"), ("strawberry", "🍓"), ("blueberry", "🫐"),
        ("raspberry", "🍓"), ("cherry", "🍒"), ("peach", "🍑"), ("apricot", "🍑"),
        ("plum", "🍑"), ("pear", "🍐"), ("melon", "🍈"), ("watermelon", "🍉"),
        ("pineapple", "🍍"), ("mango", "🥭"), ("kiwi", "🥝"), ("coconut", "🥥"),
        ("avocado", "🥑"), ("fig", "🍇"),
        ("tomato", "🍅"), ("potato", "🥔"), ("carrot", "🥕"), ("corn", "🌽"),
        ("onion", "🧅"), ("garlic", "🧄"), ("broccoli", "🥦"), ("cauliflower", "🥦"),
        ("cabbage", "🥬"), ("lettuce", "🥬"), ("spinach", "🥬"), ("kale", "🥬"),
        ("cucumber", "🥒"), ("zucchini", "🥒"), ("pumpkin", "🎃"), ("eggplant", "🍆"),
        ("pepper", "🫑"), ("chili", "🌶️"), ("mushroom", "🍄"), ("pea", "🫛"),
        ("bean", "🫘"), ("lentil", "🫘"), ("ginger", "🥔"), ("celery", "🥬"),
        ("asparagus", "🥬"), ("radish", "🥕"), ("beet", "🥔"), ("olive", "🫒"),
        ("rice", "🍚"), ("pasta", "🍝"), ("noodle", "🍜"), ("spaghetti", "🍝"),
        ("flour", "🥣"), ("oats", "🥣"), ("cereal", "🥣"), ("quinoa", "🥣"),
        ("cake", "🎂"), ("cookie", "🍪"), ("biscuit", "🍪"), ("chocolate", "🍫"),
        ("candy", "🍬"), ("donut", "🍩"), ("pie", "🥧"), ("dessert", "🍰"),
        ("honey", "🍯"), ("jam", "🍓"), ("sugar", "🍬"), ("popcorn", "🍿"),
        ("chips", "🍟"), ("nuts", "🥜"), ("peanut", "🥜"), ("almond", "🥜"),
        ("coffee", "☕"), ("tea", "🍵"), ("juice", "🧃"), ("water", "💧"),
        ("soda", "🥤"), ("wine", "🍷"), ("beer", "🍺"), ("whiskey", "🥃"),
        ("cocktail", "🍹"),
        ("salt", "🧂"), ("vinegar", "🥫"), ("sauce", "🥫"), ("ketchup", "🥫"),
        ("mustard", "🥫"), ("soup", "🍲"),
        ("pizza", "🍕"), ("burger", "🍔"), ("sandwich", "🥪"), ("taco", "🌮"),
        ("sushi", "🍣"), ("dumpling", "🥟"),
        ("soap", "🧼"), ("shampoo", "🧴"), ("toothpaste", "🪥"), ("tissue", "🧻"),
        ("detergent", "🧴"), ("diaper", "🍼"), ("battery", "🔋"), ("candle", "🕯️"),
        ("medicine", "💊"), ("vitamin", "💊"),
    ]

    let stopwords: Set<String> = [
        "frozen", "fresh", "dried", "smoked", "canned", "tinned", "organic",
        "whole", "baby", "mixed", "roasted", "salted", "unsalted", "ground",
        "plain", "natural", "ready", "raw", "free", "range", "low", "fat",
        "the", "and", "with", "of", "in", "for",
    ]

    var reports: [(item: String, anchor: String, distance: Double, glyph: String)] = []

    for item in items {
        if EmojiTable.match(item) == nil {
            if let semantic = SemanticEmoji.match(item) {
                let itemWords = item.lowercased()
                    .split { !$0.isLetter }.map(String.init)
                    .filter { $0.count > 2 && !stopwords.contains($0) }

                var bestMatch: (anchor: String, distance: Double) = ("unknown", 2.0)

                for word in itemWords {
                    for (anchor, glyph) in anchors {
                        if glyph == semantic {
                            let dist = NLEmbedding.wordEmbedding(for: .english)?
                                .distance(between: word, and: anchor) ?? 2.0
                            if dist >= 0 && dist < bestMatch.distance {
                                bestMatch = (anchor, dist)
                            }
                        }
                    }
                }

                reports.append((item: item, anchor: bestMatch.anchor, distance: bestMatch.distance, glyph: semantic))
            }
        }
    }

    if reports.isEmpty {
        print("No items fell through to semantic matching.")
        exit(0)
    }

    var reportText = "Semantic Anchor Report\n"
    reportText += "======================\n\n"

    var byGlyph: [String: [(item: String, anchor: String, distance: Double)]] = [:]
    for (item, anchor, distance, glyph) in reports {
        if byGlyph[glyph] == nil {
            byGlyph[glyph] = []
        }
        byGlyph[glyph]?.append((item: item, anchor: anchor, distance: distance))
    }

    for glyph in byGlyph.keys.sorted() {
        reportText += "\(glyph)\n"
        var grouped: [String: [(String, Double)]] = [:]
        for (item, anchor, distance) in byGlyph[glyph] ?? [] {
            if grouped[anchor] == nil {
                grouped[anchor] = []
            }
            grouped[anchor]?.append((item, distance))
        }
        for anchor in grouped.keys.sorted() {
            for (item, distance) in grouped[anchor]?.sorted(by: { $0.0 < $1.0 }) ?? [] {
                let distStr = String(format: "%.3f", distance)
                reportText += "  \(item) → \(anchor) (\(distStr))\n"
            }
        }
        reportText += "\n"
    }

    let reportFile = "tools/semantic-anchor-report.txt"
    do {
        try reportText.write(toFile: reportFile, atomically: true, encoding: .utf8)
        print("✓ Wrote report to \(reportFile)")
        print("\nSummary: \(reports.count) items resolved via semantic embedding")
        print("Glyphs represented: \(byGlyph.keys.count)")
        for glyph in byGlyph.keys.sorted() {
            let count = byGlyph[glyph]?.count ?? 0
            print("  \(glyph): \(count) items")
        }
        exit(0)
    } catch {
        print("✗ Failed to write report: \(error)")
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
