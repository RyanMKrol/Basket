import SwiftUI
import WidgetKit

/// View-only Home Screen widget: small + medium, reading the shared App
/// Group store through `BasketWidgetProvider`. Never writes to the store.
struct BasketWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BasketWidgetIdentifiers.kind, provider: BasketWidgetProvider()) { entry in
            BasketWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Basket")
        .description("See what's left to get.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
