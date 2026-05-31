import SwiftUI

/// Shown when there's nothing on the list at all — a warm nudge to add something.
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧺")
                .font(.system(size: 76))
            Text("Your basket's empty")
                .font(Theme.title(22, weight: .bold))
                .foregroundStyle(Theme.onPaper)
            Text("Add something below to get started.")
                .font(Theme.body(17))
                .foregroundStyle(Theme.onPaperSoft)
                .multilineTextAlignment(.center)
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
