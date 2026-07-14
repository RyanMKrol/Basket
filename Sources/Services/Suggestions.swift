import Foundation

/// A pure, SwiftData-free view of a remembered item, so ranking can be unit-tested.
struct SuggestionCandidate: Equatable {
    let name: String
    let timesAdded: Int
    let lastAddedAt: Date
}

/// Ranks remembered items into typing suggestions.
/// Pure and deterministic (takes `now` as input) so it is fully unit-testable.
enum Suggestions {
    /// Only suggest things bought within this window (~1 month).
    static let memoryTTL: TimeInterval = 60 * 60 * 24 * 30
    /// Cap for the combined (history + dictionary) suggestion list.
    static let combinedMax = 4

    /// Typing suggestions from the user's personal history first (ranked by
    /// frequency + recency), then a built-in food dictionary for autocomplete.
    /// De-duplicated and with anything currently on the list removed.
    static func combined(query: String,
                         history: [SuggestionCandidate],
                         dictionary: [String],
                         onList: Set<String>,
                         now: Date) -> [Suggestion] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }

        var ordered: [String] = []
        var seen = Set<String>()
        func consider(_ name: String) {
            let key = name.lowercased()
            guard !onList.contains(key), seen.insert(key).inserted else { return }
            ordered.append(name)
        }

        // 1) Personal history, ranked by frequency + recency, with a stable
        // name tiebreak so equal-scoring items don't reorder between redraws.
        let cutoff = now.addingTimeInterval(-memoryTTL)
        let hist = history
            .filter { $0.lastAddedAt > cutoff && $0.name.lowercased().contains(q) }
            .sorted { a, b in
                let sa = score(a, query: q, now: now)
                let sb = score(b, query: q, now: now)
                if sa != sb { return sa > sb }
                return a.name.lowercased() < b.name.lowercased()
            }
        for c in hist { consider(c.name) }

        // 2) Dictionary: prefix matches first ("tom" → Tomatoes), then mid-word.
        for n in dictionary where n.lowercased().hasPrefix(q) { consider(n) }
        for n in dictionary where !n.lowercased().hasPrefix(q) && n.lowercased().contains(q) {
            consider(n)
        }

        return ordered.prefix(combinedMax).map { Suggestion(name: $0, emoji: Emoji.forName($0)) }
    }

    /// "Your usuals": the add bar's empty-query state. Surfaces the user's
    /// most-frequent recent items (same frequency + recency ranking and
    /// on-list exclusion as `combined`'s history path), so focusing an empty
    /// field isn't a dead end. Nothing shows for users with no history.
    static func usuals(history: [SuggestionCandidate],
                       onList: Set<String>,
                       now: Date) -> [Suggestion] {
        let cutoff = now.addingTimeInterval(-memoryTTL)
        let ranked = history
            .filter { $0.lastAddedAt > cutoff && !onList.contains($0.name.lowercased()) }
            .sorted { a, b in
                let sa = score(a, query: "", now: now)
                let sb = score(b, query: "", now: now)
                if sa != sb { return sa > sb }
                return a.name.lowercased() < b.name.lowercased()
            }

        var ordered: [String] = []
        var seen = Set<String>()
        for c in ranked {
            let key = c.name.lowercased()
            guard seen.insert(key).inserted else { continue }
            ordered.append(c.name)
        }

        return ordered.prefix(combinedMax).map { Suggestion(name: $0, emoji: Emoji.forName($0)) }
    }

    /// Blend of: prefix match (you're probably typing the start of it),
    /// frequency (you buy it a lot), and recency (you bought it lately).
    static func score(_ c: SuggestionCandidate, query q: String, now: Date) -> Double {
        let lower = c.name.lowercased()
        let prefixBonus = lower.hasPrefix(q) ? 2.0 : 0.0
        let frequency = Double(c.timesAdded) * 0.5
        let days = max(0, now.timeIntervalSince(c.lastAddedAt) / (60 * 60 * 24))
        let recency = 3.0 / (1.0 + days)   // ~3 today, decaying with age
        return prefixBonus + frequency + recency
    }
}
