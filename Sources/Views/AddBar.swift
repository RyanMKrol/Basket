import SwiftUI

/// The always-visible bottom add bar plus its live suggestion stack.
/// Presentational: the parent owns the text binding and computes the live
/// suggestions (personal history + the food dictionary, via `Suggestions`),
/// passing them in here purely to render and tap.
struct AddBar: View {
    @Binding var text: String
    var suggestions: [Suggestion]
    var onSubmit: () -> Void
    var onPickSuggestion: (Suggestion) -> Void
    /// Focus is owned by the parent so it can drop the keyboard when another
    /// surface (e.g. the quantity editor) takes over.
    var focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 8) {
            // Suggestions float just above the field.
            if !suggestions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(suggestions) { s in
                        Button {
                            onPickSuggestion(s)
                            focused.wrappedValue = true   // keep the keyboard up for rapid adding
                        } label: {
                            HStack(spacing: 12) {
                                Text(s.emoji).font(.system(size: 20))
                                Text(s.name)
                                    .font(Theme.body(17, weight: .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .basketCard()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(s.name)")
                        .accessibilityIdentifier("addBar.suggestion.\(s.name)")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
            }

            // The pinned input field. The leading + is the add button: it adds
            // the typed item (keeping the keyboard up), or just focuses the field
            // when empty. It turns from grey to green once there's something to add.
            HStack(spacing: 12) {
                TextField("Add an item…", text: $text)
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.leaf)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused(focused)
                    .onSubmit(submit)
                    .accessibilityIdentifier("addBar.textField")

                // While the keyboard is up, offer a way to put it away. Adding
                // is the common case — submit and suggestion-pick keep focus —
                // but there was no escape hatch, so the keyboard felt stuck. This
                // tucks it down without touching the rapid-add flow.
                if focused.wrappedValue {
                    Button {
                        focused.wrappedValue = false
                        Haptics.soft()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.inkSoft.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss keyboard")
                    .accessibilityIdentifier("addBar.dismissKeyboard")
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    if text.trimmingCharacters(in: .whitespaces).isEmpty {
                        focused.wrappedValue = true
                    } else {
                        submit()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(text.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Theme.inkSoft.opacity(0.4) : Theme.leaf)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(text.trimmingCharacters(in: .whitespaces).isEmpty ? "Add item" : "Add \(text)")
                .accessibilityIdentifier("addBar.addButton")
                .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: -2)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: suggestions)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: focused.wrappedValue)
    }

    /// Submit the current text, then keep focus so the keyboard stays up — adding
    /// many items in a row is the common case.
    private func submit() {
        onSubmit()
        focused.wrappedValue = true
    }
}
