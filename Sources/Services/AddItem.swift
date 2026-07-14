import Foundation
import SwiftData

/// The core "add an item" mutation, shared between the in-app add bar
/// (`ShoppingListView`) and the Siri "Add to Basket" App Intent, so both
/// entry points behave identically: re-adding an existing item (case-
/// insensitive) bumps it back to the top of the to-get list instead of
/// duplicating it, otherwise a new row is inserted. Either way the
/// suggestion memory is updated. Purely a model mutation — the view wraps
/// this in its own animation/flash presentation.
enum AddItem {
    @discardableResult
    static func perform(_ rawName: String, context: ModelContext, now: Date) -> GroceryItem? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).capitalisedFirstLetter
        guard !name.isEmpty else { return nil }
        let key = name.lowercased()

        let existing: GroceryItem?
        do {
            existing = try context.fetch(FetchDescriptor<GroceryItem>())
                .first { $0.name.lowercased() == key }
        } catch {
            existing = nil
        }

        let item: GroceryItem
        if let existing {
            existing.isChecked = false
            existing.checkedAt = nil
            existing.createdAt = now
            item = existing
        } else {
            item = GroceryItem(name: name, createdAt: now)
            context.insert(item)
        }

        KnownItems.rememberAdd(name, context: context, now: now)
        return item
    }
}
