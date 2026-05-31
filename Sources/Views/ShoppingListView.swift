import SwiftUI

/// Main screen: the title, the scrolling list of item cards, and the pinned
/// bottom add bar. M1 uses in-memory sample data; persistence + real behaviour
/// arrive in later milestones.
struct ShoppingListView: View {
    // Temporary in-memory model for M1 (replaced by SwiftData @Query in M2).
    private struct Row: Identifiable {
        let id = UUID()
        var name: String
        var isChecked: Bool
    }

    @State private var rows: [Row] = [
        Row(name: "Milk", isChecked: false),
        Row(name: "Sourdough bread", isChecked: false),
        Row(name: "Eggs", isChecked: false),
        Row(name: "Tomatoes", isChecked: false),
        Row(name: "Bananas", isChecked: true),
    ]
    @State private var draft: String = ""

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rows) { row in
                            ItemRow(
                                name: row.name,
                                emoji: Emoji.forName(row.name),
                                isChecked: row.isChecked,
                                onToggle: { toggle(row) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AddBar(
                text: $draft,
                suggestions: sampleSuggestions,
                onSubmit: addDraft,
                onPickSuggestion: { add($0.name) }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Basket")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(rows.filter { !$0.isChecked }.count) to get")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // Visual-only suggestions for M1, shown while the user is typing.
    private var sampleSuggestions: [Suggestion] {
        guard !draft.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let pool = ["Tomatoes", "Toilet roll", "Tortillas", "Tea"]
        return pool
            .filter { $0.lowercased().contains(draft.lowercased()) }
            .prefix(3)
            .map { Suggestion(name: $0, emoji: Emoji.forName($0)) }
    }

    private func toggle(_ row: Row) {
        guard let idx = rows.firstIndex(where: { $0.id == row.id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            rows[idx].isChecked.toggle()
        }
    }

    private func addDraft() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        add(name)
    }

    private func add(_ name: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            rows.insert(Row(name: name, isChecked: false), at: 0)
        }
        draft = ""
    }
}

#Preview {
    ShoppingListView()
}
