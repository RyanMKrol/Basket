import Foundation
import NaturalLanguage

/// Offline semantic fallback. When the curated `EmojiTable` has no entry, find
/// the nearest "anchor" food word using Apple's on-device word embeddings
/// (`NLEmbedding`, no network) and use that anchor's emoji. This generalises to
/// novel items ("kohlrabi" ≈ a leafy veg) and collapses variants to one glyph.
enum SemanticEmoji {
    /// Accept a match only when the nearest anchor is at least this close
    /// (cosine distance: 0 = identical, ~2 = unrelated / out-of-vocabulary).
    static let threshold = 1.0

    /// Pure qualifiers that don't change the food category — skipped so the
    /// embedding focuses on the head noun ("smoked haddock" → "haddock").
    private static let stopwords: Set<String> = [
        "frozen", "fresh", "dried", "smoked", "canned", "tinned", "organic",
        "whole", "baby", "mixed", "roasted", "salted", "unsalted", "ground",
        "plain", "natural", "ready", "raw", "free", "range", "low", "fat",
        "the", "and", "with", "of", "in", "for",
    ]

    /// `nonisolated(unsafe)`: `NLEmbedding` is a class and not `Sendable`. It is loaded
    /// once and thereafter only read (`contains`, `distance(between:and:)`) against an
    /// immutable model, and every caller (the main-thread list view and the single-threaded
    /// native harness) touches it serially. Keeping it non-isolated is deliberate — marking
    /// `SemanticEmoji` `@MainActor` would cascade through `Emoji`/`Measure` and force the
    /// native harness into a `@main` entry point. Revisit if it ever gains concurrent readers.
    nonisolated(unsafe) private static let embedding = NLEmbedding.wordEmbedding(for: .english)

    /// Anchor words → emoji. Filtered at load to those actually in the
    /// embedding's vocabulary (some, e.g. brand-y or compound words, are not).
    private static let rawAnchors: [(String, String)] = [
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

    private static let anchors: [(String, String)] = {
        guard let emb = embedding else { return [] }
        var seen = Set<String>()
        return rawAnchors.filter { emb.contains($0.0) && seen.insert($0.0).inserted }
    }()

    static func match(_ name: String) -> String? {
        guard let emb = embedding, !anchors.isEmpty else { return nil }
        let words = name.lowercased()
            .split { !$0.isLetter }.map(String.init)
            .filter { $0.count > 2 && !stopwords.contains($0) && emb.contains($0) }
        guard !words.isEmpty else { return nil }

        var best: (dist: Double, glyph: String)?
        for word in words {
            for (anchor, glyph) in anchors {
                let d = emb.distance(between: word, and: anchor)
                if d >= 0, best == nil || d < best!.dist {
                    best = (d, glyph)
                }
            }
        }
        if let best, best.dist <= threshold { return best.glyph }
        return nil
    }
}
