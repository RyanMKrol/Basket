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
    @State private var checkingIDs: Set<PersistentIdentifier> = []
    /// The one row whose quantity editor is currently open (only one at a time).
    @State private var expandedID: PersistentIdentifier?
    @State private var showingAbout = false

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
                                    isChecking: checkingIDs.contains(item.persistentModelID),
                                    isFlashing: item.persistentModelID == flashID,
                                    quantityText: quantityText(for: item),
                                    showsQuantity: true,
                                    isExpanded: expandedID == item.persistentModelID,
                                    onToggle: { toggle(item) },
                                    onTapQuantity: { toggleQuantityEditor(item) },
                                    quantityEditor: editor(for: item)
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
        .sheet(isPresented: $showingAbout) { AboutView() }
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
            Button { showingAbout = true } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.onPaperSoft)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
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

    // MARK: - Quantity

    /// Formatted quantity for a row, or nil when none is set (shows "+ Qty").
    private func quantityText(for item: GroceryItem) -> String? {
        guard let q = item.quantity, let u = item.unit else { return nil }
        return Measure.format(q, unit: u)
    }

    /// The inline editor for a row, supplied only while it's expanded.
    private func editor(for item: GroceryItem) -> AnyView? {
        guard expandedID == item.persistentModelID,
              let u = item.unit, let q = item.quantity else { return nil }
        return AnyView(
            QuantityEditor(
                value: q,
                unit: u,
                onStep: { up in stepQuantity(item, up: up) },
                onToggleUnit: { toggleQuantityUnit(item) },
                onClear: { clearQuantity(item) }
            )
        )
    }

    /// Open/close a row's quantity editor. Opening for the first time seeds a
    /// smart default (e.g. milk → 500 ml) inferred from the item name.
    private func toggleQuantityEditor(_ item: GroceryItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if expandedID == item.persistentModelID {
                expandedID = nil
            } else {
                if item.quantity == nil || item.unit == nil {
                    let u = Measure.defaultUnit(for: item.name)
                    item.unit = u
                    item.quantity = Measure.defaultValue(for: u)
                }
                expandedID = item.persistentModelID
            }
        }
        Haptics.soft()
    }

    private func stepQuantity(_ item: GroceryItem, up: Bool) {
        guard let u = item.unit else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = Measure.step(item.quantity ?? Measure.defaultValue(for: u), unit: u, up: up)
        }
        Haptics.soft()
    }

    private func toggleQuantityUnit(_ item: GroceryItem) {
        guard let u = item.unit, let q = item.quantity else { return }
        let (value, unit) = Measure.toggleScale(q, unit: u)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = value
            item.unit = unit
        }
        Haptics.soft()
    }

    private func clearQuantity(_ item: GroceryItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            item.quantity = nil
            item.unitRaw = nil
            expandedID = nil
        }
        Haptics.soft()
    }

    // MARK: - Actions

    /// Toggle an item between the to-get list and the faded "Got it" section.
    private func toggle(_ item: GroceryItem) {
        // Checking off (or restoring) closes this row's quantity editor.
        if expandedID == item.persistentModelID { expandedID = nil }
        if item.isChecked {
            // Un-check from the "Got it" section → straight back to the list.
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                item.isChecked = false
                item.checkedAt = nil
            }
            return
        }
        // Checking off: pop a spark burst in place, then glide it into "Got it".
        // Each check-off runs on its own timer, so you can tap several items in
        // quick succession and their animations overlap instead of queuing up.
        let id = item.persistentModelID
        guard !checkingIDs.contains(id) else { return }
        checkingIDs.insert(id)
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                item.isChecked = true
                item.checkedAt = .now
            }
            checkingIDs.remove(id)
        }
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
