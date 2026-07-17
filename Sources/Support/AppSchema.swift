import Foundation
import SwiftData

/// The single source of truth for Basket's SwiftData model set. The app, the
/// "Add to Basket" App Intent, and (from T033) a widget extension all open
/// the SAME App Group store file from different processes — every one of
/// them must agree on the schema, so every container-creation site goes
/// through the factories below instead of hand-spelling the model list.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [GroceryItem.self, KnownItem.self]

    private static var schema: Schema { Schema(models) }

    /// A scratch container that never touches disk, for tests and previews.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    /// A container backed by an explicit file URL (e.g. a temp file for the
    /// UI tests' persistence/relaunch flows).
    static func makeContainer(url: URL) throws -> ModelContainer {
        let config = ModelConfiguration(url: url)
        return try ModelContainer(for: schema, configurations: config)
    }

    /// The real, on-device container, backed by the App Group's shared store
    /// file — the flavor the app and `AddToBasketIntent` (and later the
    /// widget) all open together.
    static func makeSharedContainer() throws -> ModelContainer {
        let config = ModelConfiguration(url: AppGroup.storeURL)
        return try ModelContainer(for: schema, configurations: config)
    }
}
