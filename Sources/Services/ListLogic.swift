import Foundation

/// The pure decision logic behind the main list — which section each item
/// belongs to, and the check-off spark→commit choreography — extracted from
/// `ShoppingListView` so it's unit-testable without a simulator.

/// Anything the list can section: a live `GroceryItem`, or a plain struct in
/// a unit test.
protocol ListEntry {
    var isChecked: Bool { get }
    var checkedAt: Date? { get }
}

enum ListLogic {
    /// Decide whether the 60-second ticker should be connected: only when
    /// there are items in the "Got it" section to age toward their TTL.
    /// Returns true iff recentlyGot is non-empty.
    static func tickerNeeded(_ recentlyGotCount: Int) -> Bool {
        recentlyGotCount > 0
    }

    /// Items still to get, in the caller's order (the view queries
    /// newest-first).
    static func toGet<T: ListEntry>(_ items: [T]) -> [T] {
        items.filter { !$0.isChecked }
    }

    /// Checked items still within their TTL window, most-recently-got first.
    static func recentlyGot<T: ListEntry>(_ items: [T], now: Date, ttl: TimeInterval) -> [T] {
        let cutoff = now.addingTimeInterval(-ttl)
        return items
            .filter { $0.isChecked && ($0.checkedAt ?? .distantPast) > cutoff }
            .sorted { ($0.checkedAt ?? .distantPast) > ($1.checkedAt ?? .distantPast) }
    }

    /// Checked items whose TTL has elapsed — due for deletion.
    static func expired<T: ListEntry>(_ items: [T], now: Date, ttl: TimeInterval) -> [T] {
        let cutoff = now.addingTimeInterval(-ttl)
        return items.filter { $0.isChecked && ($0.checkedAt ?? .distantPast) <= cutoff }
    }

    /// The name-tap rename business rule: trim whitespace and reject an
    /// empty result — the caller keeps the old name in that case. Doesn't
    /// touch quantity/emoji itself; the caller applies those alongside the
    /// name once it has a non-nil result.
    static func renamed(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// The check-off choreography: a tapped item sparks in place (`checking`),
/// then waits (`pending`) until no other spark is mid-flight, so the list
/// commits every finished check in one move instead of reshuffling under the
/// user's fingers. Pure state machine — the view supplies the timers and the
/// actual model mutation.
struct CheckOffChoreography<ID: Hashable> {
    private(set) var checking: Set<ID> = []
    private(set) var pending: Set<ID> = []

    /// The item is somewhere in flight (sparking or awaiting commit): its row
    /// should render checked even though the model isn't yet.
    func isInFlight(_ id: ID) -> Bool {
        checking.contains(id) || pending.contains(id)
    }

    /// Begin checking an item off. Returns false — changing nothing — if it's
    /// already in flight: the re-entrancy guard that swallows rapid re-taps.
    mutating func beginCheck(_ id: ID) -> Bool {
        guard !isInFlight(id) else { return false }
        checking.insert(id)
        return true
    }

    /// The item's spark burst finished. Returns the batch to commit now —
    /// every finished-but-waiting item — or nil while other sparks are still
    /// mid-flight (the batch stays held so the list doesn't reorder).
    mutating func finishBurst(_ id: ID) -> Set<ID>? {
        checking.remove(id)
        pending.insert(id)
        guard checking.isEmpty else { return nil }
        let batch = pending
        pending.removeAll()
        return batch
    }
}

/// The "Clear all" soft-delete/undo choreography: tapped items hide
/// immediately but the actual delete is deferred until an undo toast expires,
/// so a mis-tap is recoverable. Pure state machine — the view supplies the
/// timer and the actual model deletes.
///
/// A monotonic token invalidates any in-flight expiry that a newer "Clear
/// all" or an undo has superseded, so a stale timer can never delete the
/// wrong batch. `expire(token:)` deliberately does NOT empty the buffer
/// itself — the caller narrows it (via `narrow(stillPresent:)`) to ids still
/// present after the deletes, so items stay hidden through the one frame
/// where the underlying query hasn't refreshed yet (no delete→reappear
/// flicker).
struct ClearChoreography<ID: Hashable> {
    private(set) var hidden: Set<ID> = []
    private(set) var token: Int = 0

    /// The item is buffered for deletion: its row should stay hidden even
    /// though the model hasn't actually deleted it yet.
    func isHidden(_ id: ID) -> Bool {
        hidden.contains(id)
    }

    /// Buffer `ids` for deletion and bump the token, superseding any pending
    /// expiry. Returns the new token and the buffer's total size, or nil if
    /// every id was already buffered (nothing new to clear).
    mutating func beginClear(_ ids: some Collection<ID>) -> (token: Int, count: Int)? {
        let newIDs = Set(ids).subtracting(hidden)
        guard !newIDs.isEmpty else { return nil }
        hidden.formUnion(newIDs)
        token += 1
        return (token, hidden.count)
    }

    /// Drop the whole buffer and bump the token, invalidating any in-flight
    /// expiry. Returns false — changing nothing — if the buffer was already
    /// empty.
    mutating func undo() -> Bool {
        guard !hidden.isEmpty else { return false }
        hidden.removeAll()
        token += 1
        return true
    }

    /// The undo toast expired. Returns the ids to actually delete only when
    /// `expiredToken` is still current and the buffer is non-empty — a stale
    /// token (superseded by a later clear or an undo) or an already-emptied
    /// buffer is a no-op. Does not itself empty the buffer; see
    /// `narrow(stillPresent:)`.
    func expire(token expiredToken: Int) -> Set<ID>? {
        guard expiredToken == token, !hidden.isEmpty else { return nil }
        return hidden
    }

    /// Drop buffered ids the predicate rejects — called with "ids still
    /// present" right after the caller issues the deletes, so items stay
    /// hidden until the underlying query actually catches up.
    mutating func narrow(stillPresent: (ID) -> Bool) {
        hidden = hidden.filter(stillPresent)
    }
}
