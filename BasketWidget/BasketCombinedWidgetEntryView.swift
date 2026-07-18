import AppIntents
import SwiftUI
import WidgetKit

/// Renders the combined widget (medium only): shows a small add button at the
/// top, followed by the item list below. The add button uses widgetURL to open
/// the app's add flow.
struct BasketCombinedWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BasketWidgetEntry

    private var displayedItems: [BasketWidgetItem] {
        Array(entry.topItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            addButton
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

    private var addButton: some View {
        Link(destination: URL(string: "basket://add")!) {
            HStack(spacing: 8) {
                Text("+")
                    .font(Theme.title(16, weight: .semibold))
                    .foregroundStyle(Theme.leaf)
                Text("Add item")
                    .font(Theme.body(14, weight: .medium))
                    .foregroundStyle(Theme.onPaperSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.card)
            .cornerRadius(8)
        }
        .widgetURL(URL(string: "basket://add"))
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
