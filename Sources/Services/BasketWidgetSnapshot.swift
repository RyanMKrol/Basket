import Foundation
import WidgetKit

/// One row in the widget's item list — just enough to render an emoji +
/// name, computed once per timeline refresh (see
/// `BasketWidgetSnapshotBuilder`).
struct BasketWidgetItem: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let emoji: String
}

/// The widget's timeline entry: the "N to get" count plus its top items.
/// `topItems` carries however many items `BasketWidgetSnapshotBuilder` was
/// asked for — `BasketWidgetEntryView` trims further per widget family
/// (small shows fewer than medium).
struct BasketWidgetEntry: TimelineEntry {
    let date: Date
    let toGetCount: Int
    let topItems: [BasketWidgetItem]

    /// Nothing left to get — the view shows the "All done" empty state.
    var isEmpty: Bool { toGetCount == 0 }

    static func placeholder(date: Date) -> BasketWidgetEntry {
        BasketWidgetEntry(date: date, toGetCount: 3, topItems: [
            BasketWidgetItem(name: "Milk", emoji: "🥛"),
            BasketWidgetItem(name: "Bread", emoji: "🍞"),
            BasketWidgetItem(name: "Eggs", emoji: "🥚"),
        ])
    }
}

/// Pure computation from a fetch of live items to a widget timeline entry —
/// no rendering, no SwiftData context of its own — so it's directly
/// unit-testable against items fetched from a scratch container (see
/// `BasketWidgetSnapshotBuilderTests`). The widget's `TimelineProvider`
/// (`BasketWidget/BasketWidgetProvider.swift`) is the only production caller.
enum BasketWidgetSnapshotBuilder {
    /// The medium widget's item list length; the small widget trims further
    /// in `BasketWidgetEntryView`.
    static let maxTopItems = 6

    static func entry(from items: [GroceryItem], date: Date) -> BasketWidgetEntry {
        let toGet = ListLogic.toGet(items)
        let top = toGet.prefix(maxTopItems).map {
            BasketWidgetItem(name: $0.name, emoji: Emoji.forName($0.name))
        }
        return BasketWidgetEntry(date: date, toGetCount: toGet.count, topItems: Array(top))
    }
}
