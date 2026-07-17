import XCTest
import SwiftData
@testable import Basket

/// Drives `AddToBasketIntent.perform()` end to end against a scratch
/// in-memory container (never the real App Group store, via
/// `containerOverride`) — this is the Siri/Shortcuts entry point, so it must
/// behave identically to typing the same name into the add bar.
@MainActor
final class AddToBasketIntentTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        try AppSchema.makeInMemoryContainer()
    }

    override func tearDown() {
        AddToBasketIntent.containerOverride = nil
        super.tearDown()
    }

    func testPerformInsertsNewItemWithDerivedEmoji() async throws {
        let container = try makeContainer()
        AddToBasketIntent.containerOverride = container

        let intent = AddToBasketIntent(item: BasketItemEntity(name: "milk"))
        _ = try await intent.perform()

        let items = try container.mainContext.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item.name, "Milk")
        XCTAssertEqual(Emoji.forName(item.name), Emoji.forName("Milk"))
        XCTAssertFalse(Emoji.forName(item.name).isEmpty)

        let known = try container.mainContext.fetch(FetchDescriptor<KnownItem>())
        XCTAssertEqual(known.count, 1)
        XCTAssertEqual(known.first?.key, "milk")
        XCTAssertEqual(known.first?.timesAdded, 1)
    }

    func testPerformBumpsExistingItemInsteadOfDuplicating() async throws {
        let container = try makeContainer()
        AddToBasketIntent.containerOverride = container
        let context = container.mainContext

        let existing = GroceryItem(name: "Milk", isChecked: true, checkedAt: Date(timeIntervalSince1970: 1_000))
        context.insert(existing)
        try context.save()

        let intent = AddToBasketIntent(item: BasketItemEntity(name: "milk"))
        _ = try await intent.perform()

        let items = try context.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(items.count, 1, "re-adding an existing item should bump it, not duplicate it")
        let item = try XCTUnwrap(items.first)
        XCTAssertFalse(item.isChecked, "bumping should move it back onto the to-get list")
        XCTAssertNil(item.checkedAt)

        let known = try context.fetch(FetchDescriptor<KnownItem>())
        XCTAssertEqual(known.count, 1)
        XCTAssertEqual(known.first?.timesAdded, 1)
    }
}
