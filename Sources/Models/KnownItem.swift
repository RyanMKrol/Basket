import Foundation
import SwiftData

/// Long-term memory of things you've bought, powering typing suggestions.
/// Separate from `GroceryItem` (the live list) so the suggestion pool outlives
/// the faded "Got it" section's short TTL.
@Model
final class KnownItem {
    /// Lower-cased name — the stable identity used for upserts.
    @Attribute(.unique) var key: String
    /// The name as the user last typed it (for display).
    var displayName: String
    var timesAdded: Int
    var lastAddedAt: Date

    init(key: String, displayName: String, timesAdded: Int = 1, lastAddedAt: Date = .now) {
        self.key = key
        self.displayName = displayName
        self.timesAdded = timesAdded
        self.lastAddedAt = lastAddedAt
    }
}
