import AppIntents
import SwiftData

/// Checks off a to-get item by name from the widget (iOS 17+), moving it to
/// the "Got it" section. Targets the item by name (matching AddItem's dedupe
/// strategy) and handles the idempotent case gracefully: if the item is already
/// checked or missing, no-op without crashing.
struct CheckOffItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Off Item"
    static var description = IntentDescription("Marks an item as gotten on your Basket shopping list.")

    @Parameter(title: "Item Name")
    var itemName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Check off \(\.$itemName)")
    }

    init() {
        self.itemName = ""
    }

    init(itemName: String) {
        self.itemName = itemName
    }

    /// Test seam: unit tests point this at a scratch in-memory container
    /// instead of the real App Group store, so `perform()` stays testable
    /// without touching real on-device data. `nil` (the default) means "use
    /// the real shared store" — inert in production.
    static var containerOverride: ModelContainer?

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try Self.resolveContainer()
        let context = container.mainContext

        let targetName = itemName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !targetName.isEmpty else {
            WidgetReload.reloadTimelines()
            return .result()
        }

        var descriptor = FetchDescriptor<GroceryItem>()
        descriptor.predicate = #Predicate { item in
            !item.isChecked
        }

        let matches = try context.fetch(descriptor)
        if let item = matches.first(where: { $0.name.lowercased() == targetName }) {
            item.isChecked = true
            item.checkedAt = AppClock.now
            try context.save()
        }

        // Nudge the widget timeline regardless of whether we found and checked
        // an item, so the widget refreshes (e.g., to reflect the new count if
        // an item was checked, or stay current if the item was already gone).
        WidgetReload.reloadTimelines()
        return .result()
    }

    @MainActor
    private static func resolveContainer() throws -> ModelContainer {
        if let containerOverride {
            return containerOverride
        }
        return try AppSchema.makeSharedContainer()
    }
}
