import SwiftUI
import SwiftData

/// The "to get" list rows: the not-yet-checked items, each with its quantity
/// chip and inline editor. Extracted from `ShoppingListView` so the root view
/// only wires callbacks, not row-by-row layout.
struct ToGetSection: View {
    let items: [GroceryItem]
    let choreo: CheckOffChoreography<PersistentIdentifier>
    let flashID: PersistentIdentifier?
    let expandedID: PersistentIdentifier?
    let quantityText: (GroceryItem) -> String?
    let editor: (GroceryItem) -> QuantityEditor?
    let onToggle: (GroceryItem) -> Void
    let onTapQuantity: (GroceryItem) -> Void
    var onRename: (GroceryItem, String) -> Void = { _, _ in }

    var body: some View {
        ForEach(items) { item in
            ItemRow(
                name: item.name,
                emoji: Emoji.forName(item.name),
                isChecked: false,
                isChecking: choreo.isInFlight(item.persistentModelID),
                isFlashing: item.persistentModelID == flashID,
                quantityText: quantityText(item),
                showsQuantity: true,
                isExpanded: expandedID == item.persistentModelID,
                onToggle: { onToggle(item) },
                onTapQuantity: { onTapQuantity(item) },
                onRename: { onRename(item, $0) },
                quantityEditor: editor(item)
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.92).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}
