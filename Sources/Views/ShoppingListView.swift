import SwiftUI
import SwiftData

/// Main screen: title, the to-get list, a faded "Got it" section for recently
/// checked items, and the pinned bottom add bar. Backed by SwiftData.
struct ShoppingListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryItem.createdAt, order: .reverse) private var items: [GroceryItem]
    @Query private var known: [KnownItem]

    @State private var draft: String = ""
    @State private var now: Date = AppClock.now
    @State private var flashID: PersistentIdentifier?
    /// The check-off spark→commit state machine (the ~0.55s burst, and the
    /// hold-until-nothing-else-is-animating batching — see CheckOffChoreography).
    @State private var choreo = CheckOffChoreography<PersistentIdentifier>()
    /// The one row whose quantity editor is currently open (only one at a time).
    @State private var expandedID: PersistentIdentifier?
    /// Focus of the bottom add-bar field, lifted here so opening a quantity
    /// editor can drop its keyboard along with its draft.
    @FocusState private var addBarFocused: Bool
    @State private var showingAbout = false
    /// True briefly while the "you got everything" celebration plays.
    @State private var celebrating = false
    /// "Clear all" soft-delete buffer: items are hidden immediately but only
    /// actually deleted once the undo toast expires, so an accidental tap is
    /// recoverable. Kept as IDs (not copies) so undo just un-hides the real
    /// SwiftData objects — `persistentModelID` stays intact.
    @State private var pendingClearIDs: Set<PersistentIdentifier> = []
    @State private var showClearToast = false
    @State private var clearedToastCount = 0
    /// Invalidates an in-flight expiry timer when a newer "Clear all" or an
    /// undo supersedes it, so a stale timer can't delete the wrong batch.
    @State private var clearToken = 0
    /// Cold-start launch flourish — fires once per process, not on resume.
    /// Skipped under UI testing so tests don't have to wait out a splash that
    /// isn't part of the flow being verified.
    @State private var showFlourish = TestHooks.isUITesting ? false : LaunchOnce.consume()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(TipJar.self) private var tipJar
    /// Supporters tap the title to toggle the rainbow look. Defaults on after a
    /// tip and persists (UserDefaults) — even across relaunches — until toggled.
    @AppStorage("basket.titleRainbow") private var titleRainbow = true

    /// How long a checked-off item lingers in the faded section before it clears.
    private let gotTTL: TimeInterval = 60 * 60   // 1 hour

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var toGet: [GroceryItem] {
        ListLogic.toGet(items)
    }

    /// Checked items still within their TTL window, most-recently-got first.
    /// Excludes anything buffered by a pending "Clear all" — those vanish
    /// from view the instant "Clear all" is tapped, even though the actual
    /// delete is deferred until the undo toast expires.
    private var recentlyGot: [GroceryItem] {
        ListLogic.recentlyGot(items, now: now, ttl: gotTTL)
            .filter { !pendingClearIDs.contains($0.persistentModelID) }
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
                                    isChecking: choreo.isInFlight(item.persistentModelID),
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
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.82).unlessUITesting,
                            value: items.map(\.isChecked)
                        )
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
            VStack(spacing: 8) {
                if showClearToast {
                    ClearToast(count: clearedToastCount, onUndo: undoClear)
                        .transition(reduceMotion ? .opacity
                                                  : .move(edge: .bottom).combined(with: .opacity))
                }
                AddBar(
                    text: $draft,
                    suggestions: liveSuggestions,
                    onSubmit: addDraft,
                    onPickSuggestion: { add($0.name) },
                    focused: $addBarFocused
                )
            }
        }
        .onAppear { now = AppClock.now; purgeExpired() }
        .onReceive(ticker) { _ in now = AppClock.now; purgeExpired() }
        .sheet(isPresented: $showingAbout) { AboutView() }
        // Full-screen so it covers the add bar too; only on a cold launch.
        .overlay {
            if showFlourish {
                LaunchFlourish(reduceMotion: reduceMotion) {
                    withAppAnimation(.easeOut(duration: 0.4)) { showFlourish = false }
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
            withAppAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { titleRainbow.toggle() }
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
            Text(A11yID.toGetCountText(toGet.count))
                .font(Theme.body(15, weight: .medium))
                .foregroundStyle(Theme.onPaperSoft)
                // Stable handle for tests, so they don't have to query the
                // display copy itself ("3 to get") to find the counter.
                .accessibilityIdentifier(A11yID.Header.count)
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
            .accessibilityIdentifier(A11yID.Header.aboutButton)
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
                // Distinct from the check circles' "Got it" *label*: tests use
                // this to detect the section itself, unambiguously.
                .accessibilityIdentifier(A11yID.GotSection.header)
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
            .accessibilityIdentifier(A11yID.GotSection.clearAll)
        }
        .padding(.horizontal, 6)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    // Typing suggestions: your personal history first (last month, ranked by
    // frequency + recency), then a built-in food dictionary for autocomplete.
    // Only items still on the to-get list are excluded (checked-off ones can be
    // re-suggested so you can re-add them). Focusing an empty field surfaces
    // "your usuals" instead, so the add bar isn't a dead end before you type.
    private var liveSuggestions: [Suggestion] {
        let onList = Set(items.filter { !$0.isChecked }.map { $0.name.lowercased() })
        let candidates = known.map {
            SuggestionCandidate(name: $0.displayName,
                                timesAdded: $0.timesAdded,
                                lastAddedAt: $0.lastAddedAt)
        }
        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && addBarFocused {
            return Suggestions.usuals(history: candidates, onList: onList, now: now)
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
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
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
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = Measure.step(item.quantity ?? Measure.defaultValue(for: u), unit: u, up: up)
        }
        Haptics.soft()
    }

    private func pickQuantityUnit(_ item: GroceryItem, _ newUnit: MeasureUnit) {
        guard let u = item.unit else { return }
        let newValue = Measure.changeUnit(item.quantity ?? Measure.defaultValue(for: u),
                                          from: u, to: newUnit)
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = newValue
            item.unit = newUnit
        }
        Haptics.soft()
    }

    /// Apply an exact amount typed straight into the editor's value field — the
    /// keyboard shortcut past tapping +/- many times for a large quantity. The
    /// field only hands back values that already parsed sanely (see Measure.parse).
    private func setQuantity(_ item: GroceryItem, _ value: Double) {
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = value
        }
        Haptics.soft()
    }

    private func clearQuantity(_ item: GroceryItem) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
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
            Haptics.restore()
            withAppAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                item.isChecked = false
                item.checkedAt = nil
            }
            return
        }
        // Checking off: pop a spark burst in place. The row shows checked but
        // stays put — it only glides into "Got it" once *every* in-flight check
        // animation has finished, so the list never reorders under your taps
        // when you're checking several things off at once. (That batching, and
        // the rapid-re-tap guard, live in CheckOffChoreography.)
        let id = item.persistentModelID
        guard choreo.beginCheck(id) else { return }
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + TestHooks.checkCommitDelay) {
            if let batch = choreo.finishBurst(id) { commitChecked(batch) }
        }
    }

    /// Glide every finished-but-waiting item into the "Got it" section together.
    private func commitChecked(_ ids: Set<PersistentIdentifier>) {
        withAppAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            for item in items where ids.contains(item.persistentModelID) {
                item.isChecked = true
                item.checkedAt = AppClock.now
            }
        }
        // Just cleared the last thing to get? Celebrate the finished shop.
        if toGet.isEmpty { celebrateCleared() }
    }

    /// Play the one-shot "you got everything" celebration.
    private func celebrateCleared() {
        guard !celebrating else { return }
        Haptics.success()
        withAppAnimation(.easeOut(duration: 0.3)) { celebrating = true }
        // Auto-dismiss after the product-timed flourish. Suppressed under UI
        // testing (nil) so the transient overlay can't vanish before the test
        // observes it — see TestHooks.celebrationDuration.
        guard let duration = TestHooks.celebrationDuration else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAppAnimation(.easeIn(duration: 0.4)) { celebrating = false }
        }
    }

    /// Clear the whole "Got it" section now (manual tidy-up). Items vanish
    /// from view immediately but the SwiftData delete is deferred until the
    /// undo toast expires (see `pendingClearIDs`), so a mis-tap is
    /// recoverable without re-inserting copies (which would break
    /// `persistentModelID`-based state like `expandedID`/`flashID`).
    private func clearGot() {
        let toClear = items.filter { $0.isChecked && !pendingClearIDs.contains($0.persistentModelID) }
        guard !toClear.isEmpty else { return }
        withAppAnimation(reduceMotion ? .easeInOut(duration: 0.25)
                                       : .spring(response: 0.4, dampingFraction: 0.85)) {
            pendingClearIDs.formUnion(toClear.map(\.persistentModelID))
            clearedToastCount = pendingClearIDs.count
            showClearToast = true
        }
        Haptics.soft()

        clearToken += 1
        let token = clearToken
        DispatchQueue.main.asyncAfter(deadline: .now() + TestHooks.clearToastDuration) {
            guard clearToken == token else { return }
            commitClear()
        }
    }

    /// The undo toast expired without being tapped: actually delete the
    /// buffered items now.
    private func commitClear() {
        let ids = pendingClearIDs
        guard !ids.isEmpty else { return }
        for item in items where ids.contains(item.persistentModelID) {
            context.delete(item)
        }
        pendingClearIDs.removeAll()
        withAppAnimation(.easeOut(duration: 0.3)) { showClearToast = false }
    }

    /// Undo tapped: drop the buffer so the items reappear with their prior
    /// state intact, and invalidate the pending expiry timer.
    private func undoClear() {
        guard !pendingClearIDs.isEmpty else { return }
        clearToken += 1
        withAppAnimation(reduceMotion ? .easeInOut(duration: 0.25)
                                       : .spring(response: 0.4, dampingFraction: 0.82)) {
            pendingClearIDs.removeAll()
            showClearToast = false
        }
        Haptics.soft()
    }

    /// Remove checked items whose TTL has elapsed.
    private func purgeExpired() {
        let expired = ListLogic.expired(items, now: now, ttl: gotTTL)
        guard !expired.isEmpty else { return }
        withAppAnimation(.easeInOut) {
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
            withAppAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                existing.isChecked = false
                existing.checkedAt = nil
                existing.createdAt = AppClock.now
            }
            flash(existing)
        } else {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                context.insert(GroceryItem(name: name, createdAt: AppClock.now))
            }
        }

        KnownItems.rememberAdd(name, context: context, now: AppClock.now)
        Haptics.soft()
        draft = ""
    }

    /// Briefly highlight a row (used when an add resolves to an existing item).
    private func flash(_ item: GroceryItem) {
        let id = item.persistentModelID
        flashID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if flashID == id {
                withAppAnimation(.easeOut(duration: 0.3)) { flashID = nil }
            }
        }
    }

}

#Preview {
    ShoppingListView()
        .modelContainer(for: [GroceryItem.self, KnownItem.self], inMemory: true)
}
