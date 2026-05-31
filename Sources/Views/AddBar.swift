import SwiftUI

/// The always-visible bottom add bar plus its live suggestion stack.
/// In M1 this is wired to plain bindings/closures; suggestions are passed in by
/// the parent (real history-backed suggestions arrive in a later milestone).
struct AddBar: View {
    @Binding var text: String
    var suggestions: [Suggestion]
    var onSubmit: () -> Void
    var onPickSuggestion: (Suggestion) -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Suggestions float just above the field.
            if !suggestions.isEmpty {
                VStack(spacing: 6) {
                    ForEach(suggestions) { s in
                        Button {
                            onPickSuggestion(s)
                            focused = true   // keep the keyboard up for rapid adding
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
                    .focused($focused)
                    .onSubmit(submit)

                Button {
                    if text.trimmingCharacters(in: .whitespaces).isEmpty {
                        focused = true
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
    }

    /// Submit the current text, then keep focus so the keyboard stays up — adding
    /// many items in a row is the common case.
    private func submit() {
        onSubmit()
        focused = true
    }
}
