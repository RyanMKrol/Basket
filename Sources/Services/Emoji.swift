import Foundation

/// Maps a grocery item name to a playful emoji glyph.
/// Pure and deterministic so it can be unit-tested. Matching is case-insensitive
/// and looks for whole-word-ish keyword hits anywhere in the name
/// (e.g. "almond milk" -> 🥛, "red apples" -> 🍎).
enum Emoji {
    /// Fallback when nothing matches — a neutral grocery glyph.
    static let fallback = "🛒"

    /// Keyword -> emoji. Order matters only for overlapping keywords; more
    /// specific terms are listed before generic ones.
    private static let table: [(String, String)] = [
        ("milk", "🥛"), ("cream", "🥛"), ("yogurt", "🥛"), ("yoghurt", "🥛"),
        ("cheese", "🧀"), ("butter", "🧈"),
        ("bread", "🍞"), ("bagel", "🥯"), ("croissant", "🥐"), ("baguette", "🥖"),
        ("toast", "🍞"), ("flour", "🌾"),
        ("egg", "🥚"),
        ("tomato", "🍅"), ("potato", "🥔"), ("carrot", "🥕"), ("onion", "🧅"),
        ("garlic", "🧄"), ("pepper", "🫑"), ("chilli", "🌶️"), ("chili", "🌶️"),
        ("cucumber", "🥒"), ("lettuce", "🥬"), ("salad", "🥬"), ("broccoli", "🥦"),
        ("avocado", "🥑"), ("corn", "🌽"), ("mushroom", "🍄"), ("aubergine", "🍆"),
        ("eggplant", "🍆"), ("bean", "🫘"), ("pea", "🫛"),
        ("apple", "🍎"), ("banana", "🍌"), ("grape", "🍇"), ("strawberr", "🍓"),
        ("blueberr", "🫐"), ("lemon", "🍋"), ("lime", "🍋"), ("orange", "🍊"),
        ("peach", "🍑"), ("pear", "🍐"), ("cherr", "🍒"), ("melon", "🍈"),
        ("watermelon", "🍉"), ("pineapple", "🍍"), ("mango", "🥭"), ("kiwi", "🥝"),
        ("coconut", "🥥"),
        ("chicken", "🍗"), ("beef", "🥩"), ("steak", "🥩"), ("pork", "🥓"),
        ("bacon", "🥓"), ("sausage", "🌭"), ("ham", "🍖"), ("meat", "🥩"),
        ("fish", "🐟"), ("salmon", "🐟"), ("tuna", "🐟"), ("prawn", "🦐"),
        ("shrimp", "🦐"),
        ("rice", "🍚"), ("pasta", "🍝"), ("spaghetti", "🍝"), ("noodle", "🍜"),
        ("pizza", "🍕"), ("burger", "🍔"), ("fries", "🍟"), ("taco", "🌮"),
        ("burrito", "🌯"), ("sandwich", "🥪"), ("soup", "🍲"),
        ("coffee", "☕"), ("tea", "🍵"), ("juice", "🧃"), ("water", "💧"),
        ("wine", "🍷"), ("beer", "🍺"), ("soda", "🥤"), ("cola", "🥤"),
        ("chocolate", "🍫"), ("candy", "🍬"), ("sweet", "🍬"), ("cookie", "🍪"),
        ("biscuit", "🍪"), ("cake", "🍰"), ("donut", "🍩"), ("doughnut", "🍩"),
        ("ice cream", "🍦"), ("honey", "🍯"), ("jam", "🍓"), ("sugar", "🍬"),
        ("salt", "🧂"), ("oil", "🫗"), ("sauce", "🥫"), ("ketchup", "🍅"),
        ("nut", "🥜"), ("peanut", "🥜"), ("popcorn", "🍿"), ("crisp", "🍟"),
        ("chip", "🍟"), ("pretzel", "🥨"), ("cereal", "🥣"), ("oat", "🥣"),
        ("toilet", "🧻"), ("tissue", "🧻"), ("paper", "🧻"), ("soap", "🧼"),
        ("shampoo", "🧴"), ("detergent", "🧴"), ("toothpaste", "🪥"),
        ("toothbrush", "🪥"), ("napkin", "🧻"),
        ("flower", "💐"), ("plant", "🪴"), ("candle", "🕯️"), ("battery", "🔋"),
        ("dog", "🦴"), ("cat", "🐱"), ("baby", "🍼"), ("diaper", "🍼"),
        ("nappy", "🍼"), ("medicine", "💊"), ("vitamin", "💊"),
    ]

    static func forName(_ name: String) -> String {
        let lower = name.lowercased()
        // Split into letter-only words so we can match on word boundaries and
        // avoid interior false hits (e.g. "oil" inside "toilet", "ham" in "shampoo").
        let words = lower.split { !$0.isLetter }.map(String.init)
        // Multi-word keywords first (more specific, e.g. "ice cream" should beat "cream").
        for (keyword, glyph) in table where keyword.contains(" ") {
            if lower.contains(keyword) { return glyph }
        }
        // Then single keywords: a word must START with the keyword, so stems like
        // "apple" still match "apples" without matching mid-word ("oil" in "toilet").
        for (keyword, glyph) in table where !keyword.contains(" ") {
            if words.contains(where: { $0.hasPrefix(keyword) }) { return glyph }
        }
        return fallback
    }
}
