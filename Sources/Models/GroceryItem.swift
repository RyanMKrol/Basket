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

    init(name: String, isChecked: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.isChecked = isChecked
        self.createdAt = createdAt
    }
}
