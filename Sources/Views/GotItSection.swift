import SwiftUI

/// The faded "Got it" rows: recently checked-off items, each a bare, dimmed
/// row that toggles back onto the to-get list when tapped. Extracted from
/// `ShoppingListView` alongside `ToGetSection`.
struct GotItSection: View {
    let items: [GroceryItem]
    let onToggle: (GroceryItem) -> Void

    var body: some View {
        ForEach(items) { item in
            ItemRow(
                name: item.name,
                emoji: Emoji.forName(item.name),
                isChecked: true,
                onToggle: { onToggle(item) }
            )
            .opacity(0.5)
            .transition(.opacity)
        }
    }
}
