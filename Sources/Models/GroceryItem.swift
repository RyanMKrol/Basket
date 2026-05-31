import Foundation
import SwiftData

/// One row on the active shopping list.
/// When checked off it is animated out and deleted; the name lives on in
/// `KnownItem` so it keeps coming back as a suggestion.
@Model
final class GroceryItem {
    var name: String
    var isChecked: Bool
    var createdAt: Date
    /// When the item was checked off. Drives the faded "Got it" section's TTL.
    /// nil while the item is still on the to-get list.
    var checkedAt: Date?

    init(name: String, isChecked: Bool = false, createdAt: Date = .now, checkedAt: Date? = nil) {
        self.name = name
        self.isChecked = isChecked
        self.createdAt = createdAt
        self.checkedAt = checkedAt
    }
}
