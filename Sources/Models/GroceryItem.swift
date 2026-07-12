import Foundation
import SwiftData
import SwiftUI

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

    /// Optional amount + unit. Both nil means "no quantity set" (the row shows a
    /// faint "+ Qty" chip). Stored as primitives — a Double and the unit's raw
    /// string — so adding them is a purely-additive, migration-safe change.
    var quantity: Double?
    var unitRaw: String?

    /// Typed accessor over `unitRaw` (not persisted itself).
    var unit: MeasureUnit? {
        get { unitRaw.flatMap(MeasureUnit.init(rawValue:)) }
        set { unitRaw = newValue?.rawValue }
    }

    init(name: String, isChecked: Bool = false, createdAt: Date = AppClock.now, checkedAt: Date? = nil,
         quantity: Double? = nil, unitRaw: String? = nil) {
        self.name = name
        self.isChecked = isChecked
        self.createdAt = createdAt
        self.checkedAt = checkedAt
        self.quantity = quantity
        self.unitRaw = unitRaw
    }
}

/// Lets `ListLogic` partition live items (unit tests use plain structs).
extension GroceryItem: ListEntry {}
