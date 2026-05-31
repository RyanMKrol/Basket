import SwiftUI
import SwiftData

/// Main screen: title, the scrolling list of item cards, and the pinned bottom
/// add bar. Backed by SwiftData — adds persist, and checking a row off animates
/// it away and removes it.
struct ShoppingListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryItem.createdAt, order: .reverse) private var items: [GroceryItem]

    @State private var draft: String = ""

    private var remaining: Int { items.filter { !$0.isChecked }.count }

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            ItemRow(
                                name: item.name,
                                emoji: Emoji.forName(item.name),
                                isChecked: item.isChecked,
                                onToggle: { checkOff(item) }
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
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
                suggestions: liveSuggestions,
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
            Text(remaining == 1 ? "1 to get" : "\(remaining) to get")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // Placeholder suggestions until history-backed ones arrive (M4).
    private var liveSuggestions: [Suggestion] {
        let q = draft.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        let pool = ["Tomatoes", "Toilet roll", "Tortillas", "Tea", "Butter", "Bananas"]
        let onList = Set(items.map { $0.name.lowercased() })
        return pool
            .filter { $0.lowercased().contains(q.lowercased()) && !onList.contains($0.lowercased()) }
            .prefix(3)
            .map { Suggestion(name: $0, emoji: Emoji.forName($0)) }
    }

    // MARK: - Actions

    /// Check an item off: show the green tick + strikethrough, then animate the
    /// row away and delete it shortly after.
    private func checkOff(_ item: GroceryItem) {
        guard !item.isChecked else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.isChecked = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                context.delete(item)
            }
        }
    }

    private func addDraft() {
        add(draft)
    }

    private func add(_ rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            context.insert(GroceryItem(name: name))
        }
        draft = ""
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(for: GroceryItem.self, inMemory: true)
}
