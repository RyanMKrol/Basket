import SwiftUI
import WidgetKit

/// Quick-add widget (small only) — a single '+' button that opens the app via
/// the basket://add deep link, ready to type. Tapping it brings the user into
/// the app with the add bar focused and the keyboard up.
struct BasketAddWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BasketWidgetIdentifiers.addKind, provider: BasketAddWidgetProvider()) { entry in
            BasketAddWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Basket Add")
        .description("Quick add an item.")
        .supportedFamilies([.systemSmall])
    }
}
