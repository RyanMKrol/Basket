import Foundation

/// Maps a grocery item name to a playful emoji via a three-stage cascade:
///   1. `EmojiTable` — the curated ~1750-entry keyword table (fast, exact).
///   2. `SemanticEmoji` — offline word-embedding nearest-anchor (handles novel
///      items and collapses variants like "frozen peas" → 🫛).
///   3. `fallback` — a neutral basket when nothing else fits.
enum Emoji {
    /// Shown when an item has no mapped emoji.
    static let fallback = "🧺"

    /// `forName` is pure but not free — the cascade scans the curated table and
    /// can fall through to an `NLEmbedding` lookup. The list view calls it for
    /// every visible row on every redraw (and again via `Measure`), and the
    /// 60s ticker forces those redraws, so the same names recur constantly.
    /// `NSCache` memoises by name (thread-safe, self-evicting under pressure).
    private static let cache = NSCache<NSString, NSString>()

    static func forName(_ name: String) -> String {
        let key = name as NSString
        if let cached = cache.object(forKey: key) { return cached as String }
        let glyph = EmojiTable.match(name) ?? SemanticEmoji.match(name) ?? fallback
        cache.setObject(glyph as NSString, forKey: key)
        return glyph
    }
}
