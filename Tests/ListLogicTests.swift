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
}
