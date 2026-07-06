import Foundation
import SwiftData

/// Upserts into the long-term `KnownItem` memory that powers typing
/// suggestions — extracted from `ShoppingListView` so the bump-vs-insert
/// semantics are unit-testable against an in-memory container.
enum KnownItems {
    static func rememberAdd(_ name: String, context: ModelContext, now: Date) {
        let key = name.lowercased()
        let descriptor = FetchDescriptor<KnownItem>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.timesAdded += 1
            existing.lastAddedAt = now
            existing.displayName = name
        } else {
            context.insert(KnownItem(key: key, displayName: name, lastAddedAt: now))
        }
    }
}
