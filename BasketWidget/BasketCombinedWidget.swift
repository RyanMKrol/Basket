import SwiftUI
import WidgetKit

/// Combined widget (medium only) — shows the list of items plus an add button
/// at the top that opens the app via the basket://add deep link. Combines
/// both viewing and quick-add in one widget.
struct BasketCombinedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BasketWidgetIdentifiers.combinedKind, provider: BasketWidgetProvider()) { entry in
            BasketCombinedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Basket Add + List")
        .description("Add an item or view your list.")
        .supportedFamilies([.systemMedium])
    }
}
