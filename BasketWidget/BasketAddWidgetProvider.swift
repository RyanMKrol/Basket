import WidgetKit

/// Provider for the add widget — a simple placeholder since this widget
/// doesn't display any dynamic data, just serves as a quick-add button.
struct BasketAddWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BasketAddWidgetEntry {
        BasketAddWidgetEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (BasketAddWidgetEntry) -> Void) {
        completion(BasketAddWidgetEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BasketAddWidgetEntry>) -> Void) {
        let entry = BasketAddWidgetEntry()
        let nextRefresh = AppClock.now.addingTimeInterval(4 * 60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct BasketAddWidgetEntry: TimelineEntry {
    let date: Date = AppClock.now
}
