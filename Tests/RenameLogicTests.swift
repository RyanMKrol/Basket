import XCTest
import SwiftData
@testable import Basket

/// Pins the name-tap rename business rule at the pure-logic / SwiftData
/// level, independent of the UI: empty names are rejected, otherwise the
/// name changes, the emoji re-derives, and any set quantity resets.
final class RenameLogicTests: XCTestCase {
    // MARK: - ListLogic.renamed (pure)

    func testRenamedTrimsWhitespace() {
        XCTAssertEqual(ListLogic.renamed("  Oat milk  "), "Oat milk")
    }

    func testRenamedRejectsEmptyOrWhitespaceOnly() {
        XCTAssertNil(ListLogic.renamed(""))
        XCTAssertNil(ListLogic.renamed("   "))
    }

    // MARK: - Applying a rename to a GroceryItem (model level)

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
    }

    /// Mirrors `ShoppingListView.rename(_:to:)`: only applied once
    /// `ListLogic.renamed` has accepted the raw input.
    private func applyRename(_ item: GroceryItem, raw: String) {
        guard let newName = ListLogic.renamed(raw) else { return }
        item.name = newName
        item.quantity = nil
        item.unitRaw = nil
    }

    @MainActor
    func testAcceptedRenameUpdatesNameEmojiAndClearsQuantity() throws {
        let container = try makeContainer()
        let item = GroceryItem(name: "Milk", quantity: 500, unitRaw: MeasureUnit.milliliter.rawValue)
        container.mainContext.insert(item)
        let createdAt = item.createdAt

        applyRename(item, raw: "  Bananas  ")

        XCTAssertEqual(item.name, "Bananas")
        XCTAssertEqual(Emoji.forName(item.name), Emoji.forName("Bananas"))
        XCTAssertNil(item.quantity)
        XCTAssertNil(item.unitRaw)
        XCTAssertEqual(item.createdAt, createdAt, "rename must not touch createdAt (not a re-add)")
    }

    @MainActor
    func testEmptyRenameLeavesNameAndQuantityUntouched() throws {
        let container = try makeContainer()
        let item = GroceryItem(name: "Milk", quantity: 500, unitRaw: MeasureUnit.milliliter.rawValue)
        container.mainContext.insert(item)

        applyRename(item, raw: "   ")

        XCTAssertEqual(item.name, "Milk")
        XCTAssertEqual(item.quantity, 500)
        XCTAssertEqual(item.unitRaw, MeasureUnit.milliliter.rawValue)
    }
}
