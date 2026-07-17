import XCTest
@testable import Basket

/// Unit coverage for the section-partitioning and check-off choreography
/// logic that used to live untestably inside `ShoppingListView`.
final class ListLogicTests: XCTestCase {
    private struct Entry: ListEntry, Equatable {
        let name: String
        var isChecked: Bool = false
        var checkedAt: Date? = nil
    }

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let ttl: TimeInterval = 60 * 60

    func testToGetKeepsSourceOrderAndSkipsChecked() {
        let items = [
            Entry(name: "A"),
            Entry(name: "B", isChecked: true, checkedAt: now),
            Entry(name: "C"),
        ]
        XCTAssertEqual(ListLogic.toGet(items).map(\.name), ["A", "C"])
    }

    func testRecentlyGotSortsMostRecentFirst() {
        let items = [
            Entry(name: "older", isChecked: true, checkedAt: now.addingTimeInterval(-120)),
            Entry(name: "newest", isChecked: true, checkedAt: now.addingTimeInterval(-10)),
            Entry(name: "unchecked"),
        ]
        XCTAssertEqual(ListLogic.recentlyGot(items, now: now, ttl: ttl).map(\.name),
                       ["newest", "older"])
    }

    func testTTLBoundaryIsExclusive() {
        // Checked exactly TTL ago sits on the cutoff: expired, not recent.
        let onCutoff = Entry(name: "cutoff", isChecked: true, checkedAt: now.addingTimeInterval(-ttl))
        let justInside = Entry(name: "inside", isChecked: true, checkedAt: now.addingTimeInterval(-ttl + 1))
        let items = [onCutoff, justInside]

        XCTAssertEqual(ListLogic.recentlyGot(items, now: now, ttl: ttl).map(\.name), ["inside"])
        XCTAssertEqual(ListLogic.expired(items, now: now, ttl: ttl).map(\.name), ["cutoff"])
    }

    func testTickerNeededIffRecentlyGotIsNonEmpty() {
        XCTAssertFalse(ListLogic.tickerNeeded(0), "ticker not needed when recentlyGot is empty")
        XCTAssertTrue(ListLogic.tickerNeeded(1), "ticker needed when recentlyGot has items")
        XCTAssertTrue(ListLogic.tickerNeeded(42), "ticker needed regardless of how many items")
    }

    func testCheckedWithoutTimestampCountsAsExpired() {
        // Defensive: a checked item with no checkedAt should never linger.
        let items = [Entry(name: "stray", isChecked: true, checkedAt: nil)]
        XCTAssertTrue(ListLogic.recentlyGot(items, now: now, ttl: ttl).isEmpty)
        XCTAssertEqual(ListLogic.expired(items, now: now, ttl: ttl).map(\.name), ["stray"])
    }

    // MARK: - CheckOffChoreography

    func testSingleCheckCommitsItselfAfterBurst() {
        var choreo = CheckOffChoreography<Int>()
        XCTAssertTrue(choreo.beginCheck(1))
        XCTAssertTrue(choreo.isInFlight(1))
        XCTAssertEqual(choreo.finishBurst(1), [1])
        XCTAssertFalse(choreo.isInFlight(1))
    }

    func testReEntrantCheckIsSwallowedWhileInFlight() {
        var choreo = CheckOffChoreography<Int>()
        XCTAssertTrue(choreo.beginCheck(1))
        XCTAssertFalse(choreo.beginCheck(1), "sparking item must not re-begin")

        _ = choreo.beginCheck(2)
        XCTAssertNil(choreo.finishBurst(1), "batch held while 2 still sparks")
        XCTAssertFalse(choreo.beginCheck(1), "pending item must not re-begin either")
    }

    func testOverlappingChecksCommitAsOneBatch() {
        var choreo = CheckOffChoreography<Int>()
        _ = choreo.beginCheck(1)
        _ = choreo.beginCheck(2)

        XCTAssertNil(choreo.finishBurst(1), "1 waits for 2's spark to finish")
        XCTAssertTrue(choreo.isInFlight(1), "held item still renders checked")
        XCTAssertEqual(choreo.finishBurst(2), [1, 2], "both commit together")
    }

    func testChoreographyIsReusableAfterCommit() {
        var choreo = CheckOffChoreography<Int>()
        _ = choreo.beginCheck(1)
        _ = choreo.finishBurst(1)
        XCTAssertTrue(choreo.beginCheck(1), "committed item can be checked again")
    }

    // MARK: - ClearChoreography

    func testExpireAfterUndoIsNoOp() {
        var choreo = ClearChoreography<Int>()
        let begun = choreo.beginClear([1, 2])
        XCTAssertNotNil(begun)
        let oldToken = begun!.token

        XCTAssertTrue(choreo.undo())
        XCTAssertNil(choreo.expire(token: oldToken), "undo must invalidate the pending expiry")
        XCTAssertFalse(choreo.isHidden(1))
        XCTAssertFalse(choreo.isHidden(2))
    }

    func testDoubleClearSupersedesPendingExpiry() {
        var choreo = ClearChoreography<Int>()
        let first = choreo.beginClear([1, 2])!
        let second = choreo.beginClear([3])!

        XCTAssertNil(choreo.expire(token: first.token), "batch 1's token is stale once batch 2 begins")
        XCTAssertEqual(choreo.expire(token: second.token), [1, 2, 3],
                       "current token returns the FULL buffer, since batch 1 was never deleted")
    }

    func testUndoAfterExpiryIsNoOp() {
        var choreo = ClearChoreography<Int>()
        let begun = choreo.beginClear([1, 2])!

        let toDelete = choreo.expire(token: begun.token)
        XCTAssertEqual(toDelete, [1, 2])
        // "Deleted" — narrow to what's still present (none of them).
        choreo.narrow { _ in false }

        XCTAssertFalse(choreo.undo(), "buffer is already empty after narrowing away the deleted ids")
        XCTAssertFalse(choreo.isHidden(1))
        XCTAssertFalse(choreo.isHidden(2))
    }

    func testStaleTokenNeverReturnsIDsToDelete() {
        var choreo = ClearChoreography<Int>()
        let begun = choreo.beginClear([1])!
        _ = choreo.beginClear([2]) // bumps the token again

        XCTAssertNil(choreo.expire(token: begun.token - 1), "never-issued token")
        XCTAssertNil(choreo.expire(token: begun.token), "superseded token")
    }

    func testNarrowPreservesNoFlickerSemantics() {
        var choreo = ClearChoreography<Int>()
        let begun = choreo.beginClear([1, 2])!

        let toDelete = choreo.expire(token: begun.token)
        XCTAssertEqual(toDelete, [1, 2])
        // Still hidden until narrow runs — the frame where the query hasn't
        // refreshed yet must not flicker the deleted rows back into view.
        XCTAssertTrue(choreo.isHidden(1))
        XCTAssertTrue(choreo.isHidden(2))

        // 1 deleted (no longer present), 2 still present (predicate accepts it).
        choreo.narrow { $0 != 1 }
        XCTAssertFalse(choreo.isHidden(1), "narrow drops ids the predicate rejects")
        XCTAssertTrue(choreo.isHidden(2), "narrow keeps ids the predicate still accepts")
    }
}
