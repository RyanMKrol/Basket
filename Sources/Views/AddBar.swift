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
                        } label: {
                            HStack(spacing: 12) {
                                Text(s.emoji).font(.system(size: 20))
                                Text(s.name)
                                    .font(.system(.body, design: .rounded).weight(.medium))
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

            // The pinned input field.
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.leaf)

                TextField("Add an item…", text: $text)
                    .font(.system(.body, design: .rounded))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(onSubmit)

                if !text.isEmpty {
                    Button {
                        onSubmit()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.tomato)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
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
}
