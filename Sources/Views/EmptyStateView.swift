import SwiftUI

/// Shown when there's nothing on the list at all — a warm nudge to add something.
struct EmptyStateView: View {
    /// Injectable so snapshot tests can pin the day-rotating line and the
    /// holiday accent; production uses the app clock.
    var now: Date = AppClock.now
    @ScaledMetric(relativeTo: .largeTitle) private var basketEmojiSize: CGFloat = 76
    @ScaledMetric(relativeTo: .title3) private var accentEmojiSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧺")
                .font(.system(size: basketEmojiSize))
                .overlay(alignment: .topTrailing) {
                    if let accent = Seasonality.holidayAccent(now) {
                        Text(accent)
                            .font(.system(size: accentEmojiSize))
                            .offset(x: 16, y: -4)
                    }
                }
                .accessibilityHidden(true)
            Text(Seasonality.emptyStateLine(now))
                .font(Theme.title(22, weight: .bold))
                .foregroundStyle(Theme.onPaper)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .accessibilityIdentifier("emptyState.title")
            Text("Add something below to get started.")
                .font(Theme.body(17))
                .foregroundStyle(Theme.onPaperSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("emptyState.subtitle")
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

#Preview {
    ZStack {
        BasketBackground()
        EmptyStateView()
    }
}
