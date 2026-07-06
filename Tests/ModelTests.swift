import XCTest
import SwiftData
@testable import Basket

/// SwiftData-level tests against an in-memory container — the layer between
/// the pure-logic tests and the full UI flows, covering the persistence
/// semantics the UI tests can only exercise end-to-end.
@MainActor
final class ModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
    }

    func testSeedIfEmptySeedsStartersNewestFirstAndOnlyOnce() throws {
        let container = try makeContainer()
        BasketApp.seedIfEmpty(container.mainContext)
        BasketApp.seedIfEmpty(container.mainContext)   // must be idempotent

        let items = try container.mainContext.fetch(
            FetchDescriptor<GroceryItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        XCTAssertEqual(items.map(\.name), SharedFixtures.starterItems.reversed(),
                       "staggered createdAt should give a stable newest-first order")
        XCTAssertTrue(items.allSatisfy { !$0.isChecked })
    }

    func testSeedIfEmptyLeavesExistingDataAlone() throws {
        let container = try makeContainer()
        container.mainContext.insert(GroceryItem(name: "Coffee"))
        try container.mainContext.save()

        BasketApp.seedIfEmpty(container.mainContext)

        let items = try container.mainContext.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.map(\.name), ["Coffee"])
    }

    func testRememberAddInsertsThenBumps() throws {
        let container = try makeContainer()
        let context = container.mainContext

        KnownItems.rememberAdd("Oat milk", context: context, now: now)
        KnownItems.rememberAdd("oat milk", context: context, now: now.addingTimeInterval(60))

        let known = try context.fetch(FetchDescriptor<KnownItem>())
        XCTAssertEqual(known.count, 1, "same name, different case → one upserted entry")
        XCTAssertEqual(known.first?.timesAdded, 2)
        XCTAssertEqual(known.first?.displayName, "oat milk", "display name follows the latest typing")
        XCTAssertEqual(known.first?.lastAddedAt, now.addingTimeInterval(60))
    }

    func testRememberAddKeepsDistinctItemsApart() throws {
        let container = try makeContainer()
        let context = container.mainContext

        KnownItems.rememberAdd("Milk", context: context, now: now)
        KnownItems.rememberAdd("Oat milk", context: context, now: now)

        let known = try context.fetch(FetchDescriptor<KnownItem>(sortBy: [SortDescriptor(\.key)]))
        XCTAssertEqual(known.map(\.key), ["milk", "oat milk"])
        XCTAssertTrue(known.allSatisfy { $0.timesAdded == 1 })
    }

    func testUnitAccessorRoundTripsThroughRawString() {
        let item = GroceryItem(name: "Milk")
        XCTAssertNil(item.unit)

        item.unit = .milliliter
        XCTAssertEqual(item.unitRaw, "milliliter")
        XCTAssertEqual(item.unit, .milliliter)

        // A raw value from a future/older schema shouldn't crash, just be nil.
        item.unitRaw = "furlongs"
        XCTAssertNil(item.unit)
    }
}
