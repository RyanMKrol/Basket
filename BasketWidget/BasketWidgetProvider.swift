import WidgetKit
import SwiftData
import os

/// Reads the shared App Group store once per timeline refresh and turns it
/// into a `BasketWidgetEntry` via the pure `BasketWidgetSnapshotBuilder`.
/// Read-only: builds its container exclusively through `AppSchema`'s shared
/// factory (never `ModelContainer(for:)` directly) and never inserts/saves —
/// the widget process only ever observes the app's writes.
struct BasketWidgetProvider: TimelineProvider {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ryankrol.basket.widget",
                                        category: "widget")

    func placeholder(in context: Context) -> BasketWidgetEntry {
        .placeholder(date: AppClock.now)
    }

    func getSnapshot(in context: Context, completion: @escaping (BasketWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder(date: AppClock.now) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BasketWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // The app nudges WidgetCenter after every write (see WidgetReload),
        // so this is a fallback self-heal in case a nudge is ever missed —
        // not the primary freshness mechanism.
        let nextRefresh = AppClock.now.addingTimeInterval(4 * 60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> BasketWidgetEntry {
        do {
            let container = try AppSchema.makeSharedContainer()
            let fetchContext = ModelContext(container)
            let descriptor = FetchDescriptor<GroceryItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let items = try fetchContext.fetch(descriptor)
            return BasketWidgetSnapshotBuilder.entry(from: items, date: AppClock.now)
        } catch {
            Self.logger.error("Failed to fetch shared store for widget: \(String(describing: error), privacy: .public)")
            return BasketWidgetEntry(date: AppClock.now, toGetCount: 0, topItems: [])
        }
    }
}
