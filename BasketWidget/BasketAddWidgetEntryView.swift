import SwiftUI
import WidgetKit

/// Renders the add widget: a simple '+' button that opens the app via the
/// basket://add deep link. The button uses widgetURL(...) to ensure tapping
/// it lands in the app with the add bar focused and the keyboard up.
struct BasketAddWidgetEntryView: View {
    let entry: BasketAddWidgetEntry

    var body: some View {
        Link(destination: URL(string: "basket://add")!) {
            VStack(spacing: 8) {
                Text("+")
                    .font(Theme.title(40, weight: .semibold))
                    .foregroundStyle(Theme.leaf)
                Text("Add")
                    .font(Theme.body(13, weight: .medium))
                    .foregroundStyle(Theme.onPaperSoft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .widgetURL(URL(string: "basket://add"))
        .containerBackground(Theme.paper, for: .widget)
    }
}
