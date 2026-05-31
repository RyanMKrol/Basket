import SwiftUI

/// A single shopping-list row: a soft white card with an emoji, the item name,
/// and a tappable check circle. Checking fills the circle green and strikes the
/// text through; the parent then animates the row out of the list.
struct ItemRow: View {
    let name: String
    let emoji: String
    let isChecked: Bool
    /// Transient: the user just tapped to check it off — show the checked look
    /// plus a spark burst, briefly, before it moves to the "Got it" section.
    var isChecking: Bool = false
    var isFlashing: Bool = false
    let onToggle: () -> Void

    private var showChecked: Bool { isChecked || isChecking }

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 34, height: 34)

            Text(name)
                .font(Theme.body(17, weight: .medium))
                .foregroundStyle(showChecked ? Theme.inkSoft : Theme.ink)
                // Strikethrough that draws left → right, in sync with the check.
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Theme.inkSoft)
                        .frame(height: 1.5)
                        .scaleEffect(x: showChecked ? 1 : 0, anchor: .leading)
                        .animation(.easeInOut(duration: 0.45), value: showChecked)
                }

            Spacer(minLength: 8)

            CheckCircle(isChecked: showChecked)
                .overlay { if isChecking { SparkleBurst() } }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .basketCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.leaf, lineWidth: 2)
                .opacity(isFlashing ? 1 : 0)
        )
        .scaleEffect(isFlashing ? 1.03 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isFlashing)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onTapGesture(perform: onToggle)
    }
}

/// The check control: an empty soft ring that fills with green + a checkmark.
struct CheckCircle: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isChecked ? Theme.leaf : Theme.inkSoft.opacity(0.45),
                              lineWidth: 2)
                .frame(width: 26, height: 26)

            Circle()
                .fill(Theme.leaf)
                .frame(width: 26, height: 26)
                .scaleEffect(isChecked ? 1 : 0.1)
                .opacity(isChecked ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(isChecked ? 1 : 0.1)
                .opacity(isChecked ? 1 : 0)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.6), value: isChecked)
        .contentShape(Rectangle())
    }
}
