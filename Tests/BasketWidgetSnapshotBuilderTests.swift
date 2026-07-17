import XCTest
import SwiftData
@testable import Basket

/// Hermetic coverage for `BasketWidgetSnapshotBuilder.entry(from:date:)` —
/// pure logic, no rendering — pinning the widget's timeline entry
/// computation (count, top-N items with emoji, and the empty state) against
/// items fetched from a scratch in-memory container.
@MainActor
final class BasketWidgetSnapshotBuilderTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        try AppSchema.makeInMemoryContainer()
    }

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testEmptyStoreProducesEmptyEntry() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let entry = BasketWidgetSnapshotBuilder.entry(from: try context.fetch(FetchDescriptor<GroceryItem>()),
                                                        date: fixedDate)

        XCTAssertTrue(entry.isEmpty)
        XCTAssertEqual(entry.toGetCount, 0)
        XCTAssertEqual(entry.topItems, [])
        XCTAssertEqual(entry.date, fixedDate)
    }

    func testCountsOnlyToGetItemsAndCarriesDerivedEmoji() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(GroceryItem(name: "Milk", createdAt: fixedDate))
        context.insert(GroceryItem(name: "Bread", isChecked: true, createdAt: fixedDate, checkedAt: fixedDate))
        try context.save()

        let entry = BasketWidgetSnapshotBuilder.entry(from: try context.fetch(FetchDescriptor<GroceryItem>()),
                                                        date: fixedDate)

        XCTAssertFalse(entry.isEmpty)
        XCTAssertEqual(entry.toGetCount, 1, "a checked-off item shouldn't count toward 'to get'")
        XCTAssertEqual(entry.topItems.map(\.name), ["Milk"])
        XCTAssertEqual(entry.topItems.first?.emoji, Emoji.forName("Milk"))
    }

    func testTopItemsAreCappedAtMaxTopItemsNewestFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let names = ["Milk", "Bread", "Eggs", "Butter", "Cheese", "Yogurt", "Apples", "Bananas"]
        for (i, name) in names.enumerated() {
            // Newer createdAt for later names, matching the app's
            // newest-first query order.
            context.insert(GroceryItem(name: name, createdAt: fixedDate.addingTimeInterval(Double(i))))
        }
        try context.save()

        let descriptor = FetchDescriptor<GroceryItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let entry = BasketWidgetSnapshotBuilder.entry(from: try context.fetch(descriptor), date: fixedDate)

        XCTAssertEqual(entry.toGetCount, names.count)
        XCTAssertEqual(entry.topItems.count, BasketWidgetSnapshotBuilder.maxTopItems)
        XCTAssertEqual(entry.topItems.map(\.name), Array(names.reversed().prefix(BasketWidgetSnapshotBuilder.maxTopItems)))
    }
}
