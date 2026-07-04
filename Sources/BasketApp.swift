import SwiftUI
import SwiftData
import CoreText

@main
struct BasketApp: App {
    let container: ModelContainer
    /// The tip jar lives for the app's lifetime and is shared via the environment.
    @State private var tipJar = TipJar()

    init() {
        Self.registerFonts()
        // Pick a theme: BASKET_THEME env var (soft | pixel | dive | cozy | arcade).
        Theme.select(id: ProcessInfo.processInfo.environment["BASKET_THEME"])
        // UI tests launch with `-uiTesting` so each run starts from a fresh,
        // isolated in-memory store instead of touching the real on-device data.
        let arguments = ProcessInfo.processInfo.arguments
        do {
            if arguments.contains("-uiTesting") {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
            } else {
                container = try ModelContainer(for: GroceryItem.self, KnownItem.self)
            }
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        // `-uiTestingEmpty` opts a test out of the starter items, for flows that
        // need to start from the empty state.
        if !arguments.contains("-uiTestingEmpty") {
            Self.seedIfEmpty(container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            ShoppingListView()
                .preferredColorScheme(Theme.current.isDark ? .dark : .light)
                .environment(tipJar)
        }
        .modelContainer(container)
    }

    /// Register the bundled pixel fonts so `Font.custom` can find them.
    private static func registerFonts() {
        for name in ["VT323-Regular", "PressStart2P-Regular", "Silkscreen-Regular"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
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
