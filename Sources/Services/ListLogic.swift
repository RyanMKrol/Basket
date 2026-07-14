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
