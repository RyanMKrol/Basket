import AppIntents
import SwiftUI
import WidgetKit

/// Renders the widget in Basket's Pastel Dots look: small shows the count
/// plus the first couple of items, medium shows the count plus a longer
/// list — both emoji + name, matching the in-app row style. Falls back to
/// the "All done" empty state when there's nothing left to get.
struct BasketWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BasketWidgetEntry

    private var displayedItems: [BasketWidgetItem] {
        switch family {
        case .systemMedium: Array(entry.topItems)
        default: Array(entry.topItems.prefix(2))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            countLine
            if entry.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayedItems) { row($0) }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Theme.paper, for: .widget)
    }

    private var countLine: some View {
        Text(A11yID.toGetCountText(entry.toGetCount))
            .font(Theme.body(15, weight: .semibold))
            .foregroundStyle(Theme.onPaperSoft)
    }

    private func row(_ item: BasketWidgetItem) -> some View {
        Group {
            if #available(iOS 17, *) {
                Button(intent: CheckOffItemIntent(itemName: item.name)) {
                    rowContent(item)
                }
            } else {
                rowContent(item)
            }
        }
    }

    private func rowContent(_ item: BasketWidgetItem) -> some View {
        HStack(spacing: 8) {
            Text(item.emoji)
                .font(.system(size: 16))
            Text(item.name)
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            Text("🧺")
                .font(.system(size: 16))
            Text("All done")
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
