import SwiftUI

/// Shown when there's nothing on the list at all — a warm nudge to add something.
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🧺")
                .font(.system(size: 76))
            Text("Your basket's empty")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Add something below to get started.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
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
