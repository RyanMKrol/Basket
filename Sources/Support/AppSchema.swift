import Foundation
import SwiftData
import os

/// V1 anchors the schema Basket shipped to the App Store with. Its `models`
/// reference the LIVE `GroceryItem`/`KnownItem` classes directly — the
/// current classes ARE the released schema, so V1 is an anchor for future
/// migrations, not a frozen copy. To make a real model change: snapshot the
/// current shape into a new `BasketSchemaV2: VersionedSchema` (a copy of the
/// model types as they exist today), evolve the live classes to the new
/// shape, and add a `.custom`/`.lightweight` stage from `BasketSchemaV1` to
/// `BasketSchemaV2` in `BasketMigrationPlan.stages`.
enum BasketSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { AppSchema.models }
}

/// One version so far — nothing to migrate between yet. Every container
/// flavor below passes this plan so a future V2 stage is picked up
/// everywhere the schema is opened, with no per-call-site changes needed.
enum BasketMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [BasketSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// The single source of truth for Basket's SwiftData model set. The app, the
/// "Add to Basket" App Intent, and (from T033) a widget extension all open
/// the SAME App Group store file from different processes — every one of
/// them must agree on the schema, so every container-creation site goes
/// through the factories below instead of hand-spelling the model list.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [GroceryItem.self, KnownItem.self]

    private static var schema: Schema { Schema(versionedSchema: BasketSchemaV1.self) }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ryankrol.basket",
                                        category: "persistence")

    /// A scratch container that never touches disk, for tests and previews.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, migrationPlan: BasketMigrationPlan.self, configurations: config)
    }

    /// A container backed by an explicit file URL (e.g. a temp file for the
    /// UI tests' persistence/relaunch flows).
    static func makeContainer(url: URL) throws -> ModelContainer {
        try makePersistentContainer(url: url)
    }

    /// The real, on-device container, backed by the App Group's shared store
    /// file — the flavor the app and `AddToBasketIntent` (and later the
    /// widget) all open together.
    static func makeSharedContainer() throws -> ModelContainer {
        try makePersistentContainer(url: AppGroup.storeURL)
    }

    /// A store that fails to open (corrupt bytes, a migration that can't
    /// complete) is unrecoverable in place — the user's next launch would
    /// hit the exact same failure forever, i.e. a permanent crash loop.
    /// Losing the grocery list beats bricking the app, so on a failed open
    /// we move the store (and its -wal/-shm sidecars, in case they're the
    /// corrupt part) aside and retry once against a fresh, empty store at
    /// the original URL. Only a second failure propagates.
    private static func makePersistentContainer(url: URL) throws -> ModelContainer {
        let config = ModelConfiguration(url: url)
        do {
            return try ModelContainer(for: schema, migrationPlan: BasketMigrationPlan.self, configurations: config)
        } catch {
            logger.error("Failed to open store at \(url.path, privacy: .public): \(String(describing: error), privacy: .public)")
            moveStoreAside(url: url)
            return try ModelContainer(for: schema, migrationPlan: BasketMigrationPlan.self, configurations: config)
        }
    }

    /// Renames the store file and any `-wal`/`-shm` sidecars that exist
    /// alongside it to `<name>.broken-<timestamp>`(-wal/-shm), clearing the
    /// original URL for a fresh container. Best-effort: a missing sidecar
    /// (there isn't always a `-wal`/`-shm`) is not an error.
    private static func moveStoreAside(url: URL) {
        let timestamp = brokenTimestampFormatter.string(from: AppClock.now)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: url.path + ".broken-\(timestamp)" + suffix)
            do {
                try FileManager.default.moveItem(at: source, to: destination)
            } catch {
                logger.error("Failed to move aside \(source.path, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }

    private static let brokenTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
