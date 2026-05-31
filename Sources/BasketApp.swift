import SwiftUI
import SwiftData

@main
struct BasketApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GroceryItem.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        Self.seedIfEmpty(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ShoppingListView()
        }
        .modelContainer(container)
    }

    /// On a brand-new install, drop in a few friendly starter items so the list
    /// isn't empty the first time you open it.
    @MainActor
    private static func seedIfEmpty(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<GroceryItem>())) ?? 0
        guard count == 0 else { return }
        let starters = ["Milk", "Sourdough bread", "Eggs", "Tomatoes"]
        let now = Date.now
        for (i, name) in starters.enumerated() {
            // Stagger createdAt so newest-first ordering is stable.
            context.insert(GroceryItem(name: name,
                                       createdAt: now.addingTimeInterval(Double(i))))
        }
        try? context.save()
    }
}
