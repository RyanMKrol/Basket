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
    /// Items mid spark-burst (the first ~0.55s after a tap).
    @State private var checkingIDs: Set<PersistentIdentifier> = []
    /// Items whose burst finished but whose move into "Got it" is held until no
    /// other check is still animating — so the list doesn't shuffle under taps.
    @State private var pendingCommit: Set<PersistentIdentifier> = []
    /// The one row whose quantity editor is currently open (only one at a time).
    @State private var expandedID: PersistentIdentifier?
    /// Focus of the bottom add-bar field, lifted here so opening a quantity
    /// editor can drop its keyboard along with its draft.
    @FocusState private var addBarFocused: Bool
    @State private var showingAbout = false
    /// True briefly while the "you got everything" celebration plays.
    @State private var celebrating = false
    /// Cold-start launch flourish — fires once per process, not on resume.
    /// Skipped under UI testing so tests don't have to wait out a splash that
    /// isn't part of the flow being verified.
    @State private var showFlourish = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        ? false : LaunchOnce.consume()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(TipJar.self) private var tipJar
    /// Supporters tap the title to toggle the rainbow look. Defaults on after a
    /// tip and persists (UserDefaults) — even across relaunches — until toggled.
    @AppStorage("basket.titleRainbow") private var titleRainbow = true

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

    /// Nothing to get and nothing recently got — the empty state is showing.
    private var listIsEmpty: Bool { toGet.isEmpty && recentlyGot.isEmpty }

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 0) {
                header

                if listIsEmpty {
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
                                    isChecking: checkingIDs.contains(item.persistentModelID)
                                        || pendingCommit.contains(item.persistentModelID),
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

            // Skip the celebration once the screen is fully empty — the empty
            // state is the payoff then, and otherwise the two overlap centred.
            if celebrating && !listIsEmpty {
                ClearedCelebration(reduceMotion: reduceMotion)
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AddBar(
                text: $draft,
                suggestions: liveSuggestions,
                onSubmit: addDraft,
                onPickSuggestion: { add($0.name) },
                focused: $addBarFocused
            )
        }
        .onAppear { now = .now; purgeExpired() }
        .onReceive(ticker) { now = $0; purgeExpired() }
        .sheet(isPresented: $showingAbout) { AboutView() }
        // Full-screen so it covers the add bar too; only on a cold launch.
        .overlay {
            if showFlourish {
                LaunchFlourish(reduceMotion: reduceMotion) {
                    withAnimation(.easeOut(duration: 0.4)) { showFlourish = false }
                }
                .transition(.opacity)
            }
        }
    }

    /// Once you've tipped, the title becomes a per-letter rainbow with a solid
    /// red heart — a small "you're appreciated". Tap it to toggle between the
    /// rainbow and classic looks; the choice persists. No tip → no rainbow, no
    /// heart, no toggle.
    private var supporter: Bool { tipJar.hasTipped }

    /// "Basket" with each letter its own vibrant colour.
    private var rainbowTitle: Text {
        let cols: [Color] = [Color(red: 0.93, green: 0.26, blue: 0.30), Color(red: 0.97, green: 0.58, blue: 0.20),
                             Color(red: 0.92, green: 0.76, blue: 0.22), Color(red: 0.30, green: 0.75, blue: 0.42),
                             Color(red: 0.20, green: 0.55, blue: 0.92), Color(red: 0.62, green: 0.40, blue: 0.85)]
        var t = Text(verbatim: "")
        for (idx, ch) in Array("Basket").enumerated() {
            t = t + Text(String(ch)).foregroundColor(cols[idx % cols.count])
        }
        return t
    }

    @ViewBuilder private var titleView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            if supporter && titleRainbow {
                rainbowTitle.font(Theme.title(34, weight: .bold))
            } else {
                Text("Basket").font(Theme.title(34, weight: .bold)).foregroundStyle(Theme.onPaper)
            }
            if supporter {
                Image(systemName: "heart.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.red)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard supporter else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { titleRainbow.toggle() }
            Haptics.soft()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Basket")
        .accessibilityAddTraits(supporter ? [.isHeader, .isButton] : .isHeader)
        .accessibilityHint(supporter ? "Double tap to toggle the rainbow title" : "")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            titleView
            Spacer()
            Text(toGet.count == 1 ? "1 to get" : "\(toGet.count) to get")
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.onPaperSoft)
            Button { showingAbout = true } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.onPaperSoft)
                    // The icon itself stays visually small; this just grows the
                    // tappable area to Apple's 44x44 minimum (flagged by
                    // performAccessibilityAudit's hit-region check).
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .accessibilityLabel("About Basket")
            .accessibilityHint("Shows app info and the tip jar")
            .accessibilityIdentifier("header.aboutButton")
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
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(Theme.onPaperSoft.opacity(0.25))
                .frame(height: 1)
                .accessibilityHidden(true)
            Button(action: clearGot) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .accessibilityHidden(true)
                    Text("Clear all")
                        .font(Theme.body(13, weight: .semibold))
                }
                .foregroundStyle(Theme.onPaperSoft)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Removes everything in the Got it section")
            .accessibilityIdentifier("gotSection.clearAll")
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
                units: Measure.units(for: Measure.typeForName(item.name)),
                onStep: { up in stepQuantity(item, up: up) },
                onPickUnit: { newUnit in pickQuantityUnit(item, newUnit) },
                onSetValue: { value in setQuantity(item, value) },
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
                // Clear any half-typed add-bar entry and drop its keyboard so the
                // leftover text + suggestion stack don't linger behind the
                // quantity editor.
                draft = ""
                addBarFocused = false
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

    private func pickQuantityUnit(_ item: GroceryItem, _ newUnit: MeasureUnit) {
        guard let u = item.unit else { return }
        let newValue = Measure.changeUnit(item.quantity ?? Measure.defaultValue(for: u),
                                          from: u, to: newUnit)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = newValue
            item.unit = newUnit
        }
        Haptics.soft()
    }

    /// Apply an exact amount typed straight into the editor's value field — the
    /// keyboard shortcut past tapping +/- many times for a large quantity. The
    /// field only hands back values that already parsed sanely (see Measure.parse).
    private func setQuantity(_ item: GroceryItem, _ value: Double) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = value
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
        // Checking off: pop a spark burst in place. The row shows checked but
        // stays put — it only glides into "Got it" once *every* in-flight check
        // animation has finished, so the list never reorders under your taps
        // when you're checking several things off at once.
        let id = item.persistentModelID
        guard !checkingIDs.contains(id), !pendingCommit.contains(id) else { return }
        checkingIDs.insert(id)
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            checkingIDs.remove(id)
            pendingCommit.insert(id)
            // Nothing else still animating? Move everything that's waiting at once.
            if checkingIDs.isEmpty { commitChecked() }
        }
    }

    /// Glide every finished-but-waiting item into the "Got it" section together.
    private func commitChecked() {
        let ids = pendingCommit
        guard !ids.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            for item in items where ids.contains(item.persistentModelID) {
                item.isChecked = true
                item.checkedAt = .now
            }
            pendingCommit.removeAll()
        }
        // Just cleared the last thing to get? Celebrate the finished shop.
        if toGet.isEmpty { celebrateCleared() }
    }

    /// Play the one-shot "you got everything" celebration.
    private func celebrateCleared() {
        guard !celebrating else { return }
        withAnimation(.easeOut(duration: 0.3)) { celebrating = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.4)) { celebrating = false }
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
