import SwiftUI

/// A single shopping-list row: a soft white card with an emoji, the item name, an
/// optional quantity chip, and a tappable check circle.
///
/// Tap targets differ by section. On the to-get list the **check circle** checks
/// the item off, while tapping the **rest of the row** (or the "+ Qty" chip)
/// opens an inline quantity editor that slides down inside the card. In the faded
/// "Got it" section there's no quantity affordance, so tapping anywhere restores
/// the item.
struct ItemRow: View {
    let name: String
    let emoji: String
    let isChecked: Bool
    /// Transient: the user just tapped to check it off — show the checked look
    /// plus a spark burst, briefly, before it moves to the "Got it" section.
    var isChecking: Bool = false
    var isFlashing: Bool = false
    /// The formatted quantity ("500 ml"); nil shows the faint "+ Qty" affordance.
    var quantityText: String? = nil
    /// Whether this row offers quantity editing at all (to-get rows only).
    var showsQuantity: Bool = false
    var isExpanded: Bool = false
    let onToggle: () -> Void
    var onTapQuantity: () -> Void = {}
    /// The quantity editor, supplied by the parent when this row is expanded.
    var quantityEditor: AnyView? = nil

    private var showChecked: Bool { isChecked || isChecking }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 34, height: 34)

                    Text(name)
                        .font(Theme.body(17, weight: .medium))
                        .foregroundStyle(showChecked ? Theme.inkSoft : Theme.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        // Strikethrough that draws left → right, in sync with the check.
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Theme.inkSoft)
                                .frame(height: 1.5)
                                .offset(y: 2)   // nudge to the glyphs' visual middle (pixel fonts sit low)
                                .scaleEffect(x: showChecked ? 1 : 0, anchor: .leading)
                                .animation(.easeInOut(duration: 0.45), value: showChecked)
                        }

                    Spacer(minLength: 8)

                    if showsQuantity {
                        quantityChip
                            .fixedSize()
                    }
                }
                // One VoiceOver stop for the row's info, separate from the check
                // button below — otherwise every child (emoji, name, quantity
                // chip) reads as its own stop.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(quantityText.map { "\(name), \($0)" } ?? name)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(showsQuantity ? "Double tap to set quantity" : "Double tap to restore to your list")
                .accessibilityAction { showsQuantity ? onTapQuantity() : onToggle() }

                CheckCircle(isChecked: showChecked)
                    .overlay { if isChecking { SparkleBurst() } }
                    .frame(width: 40, height: 40)   // comfortable tap target around the 26pt ring
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onToggle)
                    .accessibilityElement()
                    .accessibilityLabel(showChecked ? "Got it" : "Not got yet")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onToggle() }
            }
            .contentShape(Rectangle())
            // To-get rows open the quantity editor on a body tap; got-it rows
            // (no quantity affordance) restore the item instead. (Touch only —
            // VoiceOver uses the accessibility actions above instead.)
            .onTapGesture { showsQuantity ? onTapQuantity() : onToggle() }

            if isExpanded, let quantityEditor {
                quantityEditor
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
    }

    /// The quantity affordance: a faint, tappable "+ Qty" when unset, or the
    /// value in a leaf-tinted capsule once set.
    private var quantityChip: some View {
        Group {
            if let quantityText {
                Text(quantityText)
                    .font(Theme.body(13, weight: .semibold))
                    .foregroundStyle(Theme.leaf)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.leaf.opacity(0.14), in: Capsule())
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                    Text("Qty").font(Theme.body(13, weight: .medium))
                }
                .foregroundStyle(Theme.inkSoft.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.inkSoft.opacity(0.08), in: Capsule())
            }
        }
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
