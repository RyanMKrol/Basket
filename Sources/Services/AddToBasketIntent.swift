import AppIntents
import SwiftData

/// A freeform grocery-item name spoken or typed into the "Add to Basket" App
/// Shortcut. The current AppIntents metadata validator only allows
/// `AppEntity`/`AppEnum` parameter types inside a static shortcut phrase (a
/// plain `String` parameter is rejected at build time), so this thin
/// `AppEntity` wraps the text — `BasketItemQuery.entities(matching:)` just
/// echoes back whatever was said/typed, letting any item name through rather
/// than restricting to a fixed list.
struct BasketItemEntity: AppEntity {
    let name: String

    var id: String { name }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
    static let defaultQuery = BasketItemQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct BasketItemQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [BasketItemEntity] {
        [BasketItemEntity(name: string)]
    }

    func entities(for identifiers: [String]) async throws -> [BasketItemEntity] {
        identifiers.map { BasketItemEntity(name: $0) }
    }

    func suggestedEntities() async throws -> [BasketItemEntity] {
        []
    }
}

/// "Add <item> to my Basket" — the headline hands-free feature. Registered
/// below as an `AppShortcut` so Siri and the Shortcuts app can add an item
/// without opening the app. Lives in the app target (App Shortcuts don't need
/// a separate extension) and writes through the shared App Group container
/// (see `AppGroup`) so it lands on the same list the app shows.
struct AddToBasketIntent: AppIntent {
    static let title: LocalizedStringResource = "Add to Basket"
    static let description = IntentDescription("Adds an item to your Basket shopping list.")

    @Parameter(title: "Item")
    var item: BasketItemEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$item) to Basket")
    }

    init() {}

    init(item: BasketItemEntity) {
        self.item = item
    }

    /// Test seam: unit tests point this at a scratch in-memory container
    /// instead of the real App Group store, so `perform()` stays testable
    /// without touching real on-device data. `nil` (the default) means "use
    /// the real shared store" — inert in production.
    /// `nonisolated(unsafe)`: a mutable static of non-`Sendable` `ModelContainer`, set only
    /// by unit tests (on the test main thread) and read only inside `@MainActor resolveContainer()`.
    nonisolated(unsafe) static var containerOverride: ModelContainer?

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try Self.resolveContainer()
        let context = container.mainContext
        AddItem.perform(item.name, context: context, now: AppClock.now)
        try context.save()
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

/// Exposes `AddToBasketIntent` to Siri/Shortcuts with the phrases that
/// trigger it, so "Hey Siri, add milk to my Basket" works without the app
/// ever launching.
struct BasketAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToBasketIntent(),
            phrases: [
                "Add \(\.$item) to my \(.applicationName)",
                "Add \(\.$item) to \(.applicationName)"
            ],
            shortTitle: "Add to Basket",
            systemImageName: "cart.badge.plus"
        )
    }
}
