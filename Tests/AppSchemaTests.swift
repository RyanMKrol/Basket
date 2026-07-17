import XCTest
import SwiftData
@testable import Basket

/// Pins `AppSchema` as the single source of truth for the model set: every
/// container flavor it can build must agree on exactly the same set of
/// entity names, so a model added to one flavor but not another (or to a
/// call site that bypasses the factory) fails loudly here instead of
/// silently splitting the app / intent / widget's view of the shared store.
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
}
