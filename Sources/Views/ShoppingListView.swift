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
    /// True while the celebration is animating itself back out — see
    /// `dismissCelebration()`, the single path that ends the celebration.
    @State private var celebrationDismissing = false
    /// The "Clear all" soft-delete/undo state machine (hide-then-defer-delete,
    /// with a token that invalidates a superseded expiry — see
    /// `ClearChoreography`). Kept as IDs (not copies) so undo just un-hides
    /// the real SwiftData objects — `persistentModelID` stays intact.
    @State private var clearChoreo = ClearChoreography<PersistentIdentifier>()
    @State private var showClearToast = false
    @State private var clearedToastCount = 0
    /// Cold-start launch flourish — fires once per process, not on resume.
    /// Skipped under UI testing so tests don't have to wait out a splash that
    /// isn't part of the flow being verified.
    @State private var showFlourish = TestHooks.isUITesting ? false : LaunchOnce.consume()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.shouldFocusAddBar) private var shouldFocusAddBar
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
            .filter { !clearChoreo.isHidden($0.persistentModelID) }
    }

    /// Nothing to get and nothing recently got — the empty state is showing.
    private var listIsEmpty: Bool { toGet.isEmpty && recentlyGot.isEmpty }

    var body: some View {
        ZStack {
            BasketBackground()

            VStack(spacing: 0) {
                header

                // Defer the empty state while the celebration is up (and
                // through its own dismiss animation) so the two never
                // overlap, even if "Clear got items" empties the list mid-
                // celebration — see dismissCelebration().
                if listIsEmpty && !celebrating {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ToGetSection(
                                items: toGet,
                                choreo: choreo,
                                flashID: flashID,
                                expandedID: expandedID,
                                quantityText: quantityText(for:),
                                editor: editor(for:),
                                onToggle: toggle,
                                onTapQuantity: quantity.toggle,
                                onRename: rename
                            )

                            // Faded "Got it" section.
                            if !recentlyGot.isEmpty {
                                gotHeader
                                GotItSection(items: recentlyGot, onToggle: toggle)
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

            // `celebrating` is the ONLY thing that mounts/unmounts this —
            // see dismissCelebration() for the single path that ends it.
            if celebrating {
                ClearedCelebration(reduceMotion: reduceMotion, isDismissing: celebrationDismissing)
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
        .onChange(of: shouldFocusAddBar) { _, newValue in
            if newValue {
                addBarFocused = true
            }
        }
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

    /// Wires the quantity editor's five actions onto a `GroceryItem`; see
    /// `QuantityController`.
    private var quantity: QuantityController {
        QuantityController(expandedID: $expandedID, draft: $draft, addBarFocused: $addBarFocused)
    }

    /// Formatted quantity for a row, or nil when none is set (shows "+ Qty").
    private func quantityText(for item: GroceryItem) -> String? {
        guard let q = item.quantity, let u = item.unit else { return nil }
        return Measure.format(q, unit: u)
    }

    /// The inline editor for a row, supplied only while it's expanded.
    private func editor(for item: GroceryItem) -> QuantityEditor? {
        guard expandedID == item.persistentModelID,
              let u = item.unit, let q = item.quantity else { return nil }
        return QuantityEditor(
            value: q,
            unit: u,
            units: Measure.units(for: Measure.typeForName(item.name)),
            onStep: { up in quantity.step(item, up: up) },
            onPickUnit: { newUnit in quantity.pickUnit(item, newUnit) },
            onSetValue: { value in quantity.setValue(item, value) },
            onClear: { quantity.clear(item) }
        )
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

    /// Name-tap rename: applies the trimmed new name (ListLogic.renamed
    /// already rejected an empty one before calling this), re-derives the
    /// emoji by virtue of the row reading `item.name` fresh next render, and
    /// resets any quantity — a renamed item starts fresh since the old
    /// amount may no longer make sense. List position and createdAt are
    /// untouched since this mutates the existing item in place.
    private func rename(_ item: GroceryItem, to newName: String) {
        if expandedID == item.persistentModelID { expandedID = nil }
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            item.name = newName
            item.quantity = nil
            item.unitRaw = nil
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
            dismissCelebration()
        }
    }

    /// The one path that ends the celebration: tell ClearedCelebration to
    /// animate its own content back down in step with the outer fade, then
    /// unmount the overlay once that exit animation has actually played out.
    /// Both the timed auto-dismiss and an in-celebration "Clear got items"
    /// tap route through here, so there's never a second, uncoordinated way
    /// for the overlay to disappear (that compound-trigger yank was the bug).
    private func dismissCelebration() {
        guard celebrating, !celebrationDismissing else { return }
        withAppAnimation(.easeOut(duration: celebrationExitDuration)) {
            celebrationDismissing = true
        }
        let delay = TestHooks.disableAnimations ? 0.05 : celebrationExitDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            celebrating = false
            celebrationDismissing = false
        }
    }

    /// Mirrors ClearedCelebration's own exit-animation duration so the
    /// overlay unmounts right as its content finishes fading, not before.
    private var celebrationExitDuration: TimeInterval { reduceMotion ? 0.3 : 0.4 }

    /// Clear the whole "Got it" section now (manual tidy-up). Items vanish
    /// from view immediately but the SwiftData delete is deferred until the
    /// undo toast expires (see `ClearChoreography`), so a mis-tap is
    /// recoverable without re-inserting copies (which would break
    /// `persistentModelID`-based state like `expandedID`/`flashID`).
    private func clearGot() {
        let toClear = items.filter { $0.isChecked }.map(\.persistentModelID)
        guard let (token, count) = clearChoreo.beginClear(toClear) else { return }
        withAppAnimation(reduceMotion ? .easeInOut(duration: 0.25)
                                       : .spring(response: 0.4, dampingFraction: 0.85)) {
            clearedToastCount = count
            showClearToast = true
        }
        Haptics.soft()
        // Emptying "Got it" mid-celebration used to yank the overlay out via
        // the old `!listIsEmpty` visibility guard, independent of and out of
        // step with the celebration's own dismiss. Route it through the same
        // graceful dismiss instead.
        if celebrating { dismissCelebration() }

        DispatchQueue.main.asyncAfter(deadline: .now() + TestHooks.clearToastDuration) {
            commitClear(token: token)
        }
    }

    /// The undo toast expired without being tapped: actually delete the
    /// buffered items now.
    private func commitClear(token: Int) {
        guard let ids = clearChoreo.expire(token: token) else { return }
        for item in items where ids.contains(item.persistentModelID) {
            context.delete(item)
        }
        clearChoreo.narrow { id in items.contains { $0.persistentModelID == id } }
        withAppAnimation(.easeOut(duration: 0.3)) { showClearToast = false }
    }

    /// Undo tapped: drop the buffer so the items reappear with their prior
    /// state intact, and invalidate the pending expiry timer.
    private func undoClear() {
        guard clearChoreo.undo() else { return }
        withAppAnimation(reduceMotion ? .easeInOut(duration: 0.25)
                                       : .spring(response: 0.4, dampingFraction: 0.82)) {
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
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let key = name.lowercased()

        // Duplicate: if it's already known to the list, don't create a second row.
        // Bump it back to the top of the to-get list (un-checking it if it was in
        // the "Got it" section) and give it a little flash instead.
        let wasExisting = items.contains { $0.name.lowercased() == key }
        let animation = wasExisting
            ? Animation.spring(response: 0.4, dampingFraction: 0.8)
            : Animation.spring(response: 0.35, dampingFraction: 0.75)

        var result: GroceryItem?
        withAppAnimation(animation) {
            result = AddItem.perform(name, context: context, now: AppClock.now)
        }
        if wasExisting, let result {
            flash(result)
        }

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
