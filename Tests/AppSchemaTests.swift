import XCTest
import SwiftData
@testable import Basket

/// Pins `AppSchema` as the single source of truth for the model set: every
/// container flavor it can build must agree on exactly the same set of
/// entity names, so a model added to one flavor but not another (or to a
/// call site that bypasses the factory) fails loudly here instead of
/// silently splitting the app / intent / widget's view of the shared store.
@MainActor
final class AppSchemaTests: XCTestCase {
    private var expectedEntityNames: Set<String> {
        Set(Schema(AppSchema.models).entities.map(\.name))
    }

    func testInMemoryContainerMatchesAppSchemaModels() throws {
        let container = try AppSchema.makeInMemoryContainer()
        let entityNames = Set(container.schema.entities.map(\.name))

        XCTAssertEqual(entityNames, ["GroceryItem", "KnownItem"])
        XCTAssertEqual(entityNames, expectedEntityNames)
    }

    func testURLContainerMatchesAppSchemaModels() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppSchemaTests-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try AppSchema.makeContainer(url: url)
        let entityNames = Set(container.schema.entities.map(\.name))

        XCTAssertEqual(entityNames, ["GroceryItem", "KnownItem"])
        XCTAssertEqual(entityNames, expectedEntityNames)
    }

    /// Pins the V1 anchor: a store written by the released schema — built
    /// straight from `Schema(versionedSchema: BasketSchemaV1.self)`, with NO
    /// migration plan attached, since that's what the shipped app wrote —
    /// must reopen intact through the factory (which attaches
    /// `BasketMigrationPlan`). The fixture is produced here, not checked in,
    /// so this test doesn't rot as the live models evolve underneath V1.
    func testFactoryReopensAStoreWrittenByTheReleasedSchema() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppSchemaTests-released-\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
        }

        try {
            let releasedSchema = Schema(versionedSchema: BasketSchemaV1.self)
            let config = ModelConfiguration(url: url)
            let container = try ModelContainer(for: releasedSchema, configurations: config)
            let context = container.mainContext
            context.insert(GroceryItem(name: "Oat milk"))
            context.insert(KnownItem(key: "oat milk", displayName: "Oat milk"))
            try context.save()
        }() // scope exit releases the container/context so file handles close

        let reopened = try AppSchema.makeContainer(url: url)
        let groceryItems = try reopened.mainContext.fetch(FetchDescriptor<GroceryItem>())
        let knownItems = try reopened.mainContext.fetch(FetchDescriptor<KnownItem>())

        XCTAssertEqual(groceryItems.map(\.name), ["Oat milk"])
        XCTAssertEqual(knownItems.map(\.key), ["oat milk"])
    }

    /// A store that can't open (corrupt bytes standing in for a failed
    /// migration) must not crash-loop: the factory should move the bad file
    /// aside and hand back a working, fresh container at the same URL.
    func testFactoryRecoversFromAnUnopenableStore() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppSchemaTests-corrupt-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        try Data("not a valid SwiftData store".utf8).write(to: url)

        let container = try AppSchema.makeContainer(url: url)
        let context = container.mainContext
        context.insert(GroceryItem(name: "Bread"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<GroceryItem>())
        XCTAssertEqual(fetched.map(\.name), ["Bread"])

        let siblings = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)
        XCTAssertTrue(siblings.contains { $0.hasPrefix(url.lastPathComponent) && $0.contains(".broken-") },
                      "expected a .broken- sibling next to \(url.lastPathComponent), found: \(siblings)")
    }
}
