import SwiftUI

/// Shown when there's nothing on the list at all — a warm nudge to add something.
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧺")
                .font(.system(size: 76))
                .overlay(alignment: .topTrailing) {
                    if let accent = Seasonality.holidayAccent(.now) {
                        Text(accent)
                            .font(.system(size: 30))
                            .offset(x: 16, y: -4)
                    }
                }
                .accessibilityHidden(true)
            Text(Seasonality.emptyStateLine(.now))
                .font(Theme.title(22, weight: .bold))
                .foregroundStyle(Theme.onPaper)
            Text("Add something below to get started.")
                .font(Theme.body(17))
                .foregroundStyle(Theme.onPaperSoft)
                .multilineTextAlignment(.center)
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
