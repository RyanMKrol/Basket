import SwiftUI
import UIKit

/// A soft, theme-consistent banner shown after "Clear all" empties the "Got
/// it" section, offering a short window to undo before the items are
/// actually deleted. Non-blocking — it floats above the add bar rather than
/// covering it.
struct ClearToast: View {
    let count: Int
    var onUndo: () -> Void

    private var message: String {
        count == 1 ? "Cleared 1 item" : "Cleared \(count) items"
    }

    var body: some View {
        // No accessibility modifier on the HStack itself: putting one there
        // (even just an identifier) makes SwiftUI collapse the whole banner
        // into a single element, hiding the Undo button from VoiceOver and
        // XCUITest alike. Keeping the container plain leaves the message and
        // the button as two distinct, separately reachable elements.
        HStack(spacing: 12) {
            Text(message)
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.ink)
                .accessibilityIdentifier("clearToast.message")

            Spacer(minLength: 8)

            Button(action: onUndo) {
                Text("Undo")
                    .font(Theme.body(15, weight: .bold))
                    .foregroundStyle(Theme.leaf)
                    // The text itself stays visually compact; this just grows
                    // the tappable area to Apple's 44x44 minimum (flagged by
                    // performAccessibilityAudit's hit-region check).
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("clearToast.undo")
            .accessibilityHint("Restores the cleared items")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .basketCard()
        .padding(.horizontal, 16)
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: "\(message). Undo available.")
        }
    }
}

#Preview {
    ClearToast(count: 3, onUndo: {})
}
