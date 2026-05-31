import SwiftUI

/// A single shopping-list row: a soft white card with an emoji, the item name,
/// and a tappable check circle. Checking fills the circle green and strikes the
/// text through; the parent then animates the row out of the list.
struct ItemRow: View {
    let name: String
    let emoji: String
    let isChecked: Bool
    var isFlashing: Bool = false
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 34, height: 34)

            Text(name)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(isChecked ? Theme.inkSoft : Theme.ink)
                .strikethrough(isChecked, color: Theme.inkSoft)

            Spacer(minLength: 8)

            CheckCircle(isChecked: isChecked)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
        .contentShape(Rectangle())
    }
}
