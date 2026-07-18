import XCTest
import SwiftData
@testable import Basket

/// Drives `CheckOffItemIntent.perform()` end to end against a scratch
/// in-memory container (never the real App Group store, via
/// `containerOverride`) — this is the widget tap entry point, so it must
/// behave identically to the in-app check-off.
@MainActor
final class CheckOffItemIntentTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        try AppSchema.makeInMemoryContainer()
    }

    override func tearDown() {
        CheckOffItemIntent.containerOverride = nil
        WidgetReload.reloadTimelines = WidgetReload.defaultReloadTimelines
        super.tearDown()
    }

    /// A matching to-get item becomes isChecked==true with checkedAt set.
    func testPerformChecksOffMatchingToGetItem() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let item = GroceryItem(name: "Milk", isChecked: false)
        context.insert(item)
        try context.save()

        let intent = CheckOffItemIntent(itemName: "milk")
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.count, 1)
        let checked = try XCTUnwrap(items.first)
        XCTAssertTrue(checked.isChecked)
        XCTAssertNotNil(checked.checkedAt)
    }

    /// An already-checked item is handled gracefully: no crash, no duplicate.
    func testPerformHandlesAlreadyCheckedItemGracefully() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let checkedAt = Date(timeIntervalSince1970: 1_000)
        let item = GroceryItem(name: "Milk", isChecked: true, checkedAt: checkedAt)
        context.insert(item)
        try context.save()

        let intent = CheckOffItemIntent(itemName: "milk")
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.count, 1, "perform should not create a duplicate")
        let result = try XCTUnwrap(items.first)
        XCTAssertTrue(result.isChecked)
        XCTAssertEqual(result.checkedAt, checkedAt, "already-checked item should not be modified")
    }

    /// A missing item is handled gracefully: no crash, no insert.
    func testPerformHandlesMissingItemGracefully() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let intent = CheckOffItemIntent(itemName: "nonexistent")
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.count, 0, "perform should not create an item for a missing name")
    }

    /// perform() nudges WidgetReload.reloadTimelines exactly once.
    func testPerformNudgesWidgetReloadAfterCheckOff() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let item = GroceryItem(name: "Milk", isChecked: false)
        context.insert(item)
        try context.save()

        var reloadCount = 0
        WidgetReload.reloadTimelines = { reloadCount += 1 }

        let intent = CheckOffItemIntent(itemName: "milk")
        _ = try await intent.perform()

        XCTAssertEqual(reloadCount, 1)
    }

    /// perform() nudges the widget reload even if no matching item exists.
    func testPerformNudgesWidgetReloadEvenWhenItemNotFound() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container

        var reloadCount = 0
        WidgetReload.reloadTimelines = { reloadCount += 1 }

        let intent = CheckOffItemIntent(itemName: "nonexistent")
        _ = try await intent.perform()

        XCTAssertEqual(reloadCount, 1)
    }

    /// Item name matching is case-insensitive.
    func testPerformMatchesItemNameCaseInsensitively() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let item = GroceryItem(name: "Milk", isChecked: false)
        context.insert(item)
        try context.save()

        let intent = CheckOffItemIntent(itemName: "MILK")
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        let checked = try XCTUnwrap(items.first)
        XCTAssertTrue(checked.isChecked)
    }

    /// Whitespace is trimmed from the item name before matching.
    func testPerformTrimsWhitespaceFromItemName() async throws {
        let container = try makeContainer()
        CheckOffItemIntent.containerOverride = container
        let context = container.mainContext

        let item = GroceryItem(name: "Milk", isChecked: false)
        context.insert(item)
        try context.save()

        let intent = CheckOffItemIntent(itemName: "  milk  ")
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        let checked = try XCTUnwrap(items.first)
        XCTAssertTrue(checked.isChecked)
    }
}
