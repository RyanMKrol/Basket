import Foundation
import SwiftData
import os

/// Upserts into the long-term `KnownItem` memory that powers typing
/// suggestions — extracted from `ShoppingListView` so the bump-vs-insert
/// semantics are unit-testable against an in-memory container.
enum KnownItems {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ryankrol.basket", category: "persistence")

    static func rememberAdd(_ name: String, context: ModelContext, now: Date) {
        let key = name.lowercased()
        let descriptor = FetchDescriptor<KnownItem>(predicate: #Predicate { $0.key == key })
        let existing: KnownItem?
        do {
            existing = try context.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch known item for key \(key): \(error)")
            existing = nil
        }
        if let existing = existing {
            existing.timesAdded += 1
            existing.lastAddedAt = now
            existing.displayName = name
        } else {
            context.insert(KnownItem(key: key, displayName: name, lastAddedAt: now))
        }
    }
}
