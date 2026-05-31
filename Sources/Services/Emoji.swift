import Foundation

/// Maps a grocery item name to a playful emoji via a three-stage cascade:
///   1. `EmojiTable` — the curated ~960-entry keyword table (fast, exact).
///   2. `SemanticEmoji` — offline word-embedding nearest-anchor (handles novel
///      items and collapses variants like "frozen peas" → 🫛).
///   3. `fallback` — a neutral basket when nothing else fits.
enum Emoji {
    /// Shown when an item has no mapped emoji.
    static let fallback = "🧺"

    static func forName(_ name: String) -> String {
        EmojiTable.match(name) ?? SemanticEmoji.match(name) ?? fallback
    }
}
