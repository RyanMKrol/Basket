import SwiftUI
import SwiftData

/// Main screen: title, the to-get list, a faded "Got it" section for recently
/// checked items, and the pinned bottom add bar. Backed by SwiftData.
struct ShoppingListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryItem.createdAt, order: .reverse) private var items: [GroceryItem]
    @Query private var known: [KnownItem]

    @State private var draft: String = ""
    @State private var now: Date = .now
    @State private var flashID: PersistentIdentifier?

    /// How long a checked-off item lingers in the faded section before it clears.
    private let gotTTL: TimeInterval = 60 * 60   // 1 hour

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var cutoff: Date { now.addingTimeInterval(-gotTTL) }

    private var toGet: [GroceryItem] {
        items.filter { !$0.isChecked }
    }

    /// Checked items still within their TTL window, most-recently-got first.
    private var recentlyGot: [GroceryItem] {
        items
            .filter { $0.isChecked && ($0.checkedAt ?? .distantPast) > cutoff }
            .sorted { ($0.checkedAt ?? .distantPast) > ($1.checkedAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 0) {
                header

                if toGet.isEmpty && recentlyGot.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // To-get section.
                            ForEach(toGet) { item in
                                ItemRow(
                                    name: item.name,
                                    emoji: Emoji.forName(item.name),
                                    isChecked: false,
                                    isFlashing: item.persistentModelID == flashID,
                                    onToggle: { toggle(item) }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }

                            // Faded "Got it" section.
                            if !recentlyGot.isEmpty {
                                gotHeader
                                ForEach(recentlyGot) { item in
                                    ItemRow(
                                        name: item.name,
                                        emoji: Emoji.forName(item.name),
                                        isChecked: true,
                                        onToggle: { toggle(item) }
                                    )
                                    .opacity(0.5)
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: items.map(\.isChecked))
                    }
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
        .onAppear { now = .now; purgeExpired() }
        .onReceive(ticker) { now = $0; purgeExpired() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Basket")
                .font(Theme.title(34, weight: .bold))
                .foregroundStyle(Theme.onPaper)
            Spacer()
            Text(toGet.count == 1 ? "1 to get" : "\(toGet.count) to get")
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.onPaperSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var gotHeader: some View {
        HStack(spacing: 8) {
            Text("Got it")
                .font(Theme.body(13, weight: .semibold))
                .foregroundStyle(Theme.onPaperSoft)
            Rectangle()
                .fill(Theme.onPaperSoft.opacity(0.25))
                .frame(height: 1)
            Button(action: clearGot) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Clear all")
                        .font(Theme.body(13, weight: .semibold))
                }
                .foregroundStyle(Theme.onPaperSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    // Typing suggestions: your personal history first (last month, ranked by
    // frequency + recency), then a built-in food dictionary for autocomplete.
    // Only items still on the to-get list are excluded (checked-off ones can be
    // re-suggested so you can re-add them).
    private var liveSuggestions: [Suggestion] {
        let onList = Set(items.filter { !$0.isChecked }.map { $0.name.lowercased() })
        let candidates = known.map {
            SuggestionCandidate(name: $0.displayName,
                                timesAdded: $0.timesAdded,
                                lastAddedAt: $0.lastAddedAt)
        }
        return Suggestions.combined(query: draft,
                                    history: candidates,
                                    dictionary: SuggestionDictionary.items,
                                    onList: onList,
                                    now: now)
    }

    // MARK: - Actions

    /// Toggle an item between the to-get list and the faded "Got it" section.
    private func toggle(_ item: GroceryItem) {
        let checkingOff = !item.isChecked
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            if item.isChecked {
                item.isChecked = false
                item.checkedAt = nil
            } else {
                item.isChecked = true
                item.checkedAt = .now
            }
        }
        if checkingOff { Haptics.success() }
    }

    /// Clear the whole "Got it" section now (manual tidy-up).
    private func clearGot() {
        let checked = items.filter { $0.isChecked }
        guard !checked.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            for item in checked { context.delete(item) }
        }
        Haptics.soft()
    }

    /// Remove checked items whose TTL has elapsed.
    private func purgeExpired() {
        let expired = items.filter { $0.isChecked && ($0.checkedAt ?? .distantPast) <= cutoff }
        guard !expired.isEmpty else { return }
        withAnimation(.easeInOut) {
            for item in expired { context.delete(item) }
        }
    }

    private func addDraft() { add(draft) }

    private func add(_ rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).capitalisedFirstLetter
        guard !name.isEmpty else { return }
        let key = name.lowercased()

        // Duplicate: if it's already known to the list, don't create a second row.
        // Bump it back to the top of the to-get list (un-checking it if it was in
        // the "Got it" section) and give it a little flash instead.
        if let existing = items.first(where: { $0.name.lowercased() == key }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                existing.isChecked = false
                existing.checkedAt = nil
                existing.createdAt = .now
            }
            flash(existing)
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                context.insert(GroceryItem(name: name))
            }
        }

        rememberAdd(name)
        Haptics.soft()
        draft = ""
    }

    /// Briefly highlight a row (used when an add resolves to an existing item).
    private func flash(_ item: GroceryItem) {
        flashID = item.persistentModelID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if flashID == item.persistentModelID {
                withAnimation(.easeOut(duration: 0.3)) { flashID = nil }
            }
        }
    }

    /// Upsert into the long-term memory that powers suggestions.
    private func rememberAdd(_ name: String) {
        let key = name.lowercased()
        let descriptor = FetchDescriptor<KnownItem>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.timesAdded += 1
            existing.lastAddedAt = .now
            existing.displayName = name
        } else {
            context.insert(KnownItem(key: key, displayName: name))
        }
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(for: [GroceryItem.self, KnownItem.self], inMemory: true)
}
