import SwiftUI
import SwiftData
import CoreText
import os

@main
struct BasketApp: App {
    let container: ModelContainer
    /// The tip jar lives for the app's lifetime and is shared via the environment.
    @State private var tipJar = TipJar()
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ryankrol.basket", category: "persistence")

    init() {
        Self.registerFonts()
        // UI tests ask for deterministic rendering: no animations, so tests
        // wait on state changes rather than choreography (see TestHooks).
        if TestHooks.disableAnimations {
            UIView.setAnimationsEnabled(false)
        }
        // UI tests launch with `-uiTesting` so each run starts from a fresh,
        // isolated in-memory store instead of touching the real on-device
        // data; the persistence tests instead point at their own temp file.
        do {
            if let url = TestHooks.storeURL {
                let config = ModelConfiguration(url: url)
                container = try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
            } else if TestHooks.isUITesting {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
            } else {
                // Real store lives in the App Group container so the Siri intent
                // and widget can read the same list (see AppGroup). The test
                // paths above are untouched — they keep their in-memory / temp
                // stores.
                let config = ModelConfiguration(url: AppGroup.storeURL)
                container = try ModelContainer(for: GroceryItem.self, KnownItem.self, configurations: config)
            }
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        // `-uiTestingEmpty` opts a test out of the starter items, for flows that
        // need to start from the empty state.
        if !TestHooks.startEmpty {
            Self.seedIfEmpty(container.mainContext)
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ShoppingListView()
                .preferredColorScheme(.light)
                .environment(tipJar)
                // SwiftData's autosave is debounced, so a force-quit right
                // after a change can lose it — flush explicitly on the way
                // to the background, the last reliable moment we get.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        do {
                            try container.mainContext.save()
                        } catch {
                            Self.logger.error("Failed to save context on background: \(error)")
                        }
                    }
                }
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
    /// isn't empty the first time you open it. (Internal, not private, so the
    /// unit tests can exercise the seed against an in-memory container.)
    @MainActor
    static func seedIfEmpty(_ context: ModelContext) {
        let count: Int
        do {
            count = try context.fetchCount(FetchDescriptor<GroceryItem>())
        } catch {
            Self.logger.error("Failed to fetch item count: \(error)")
            count = 0
        }
        guard count == 0 else { return }
        let now = AppClock.now
        for (i, name) in SharedFixtures.starterItems.enumerated() {
            // Stagger createdAt so newest-first ordering is stable.
            context.insert(GroceryItem(name: name,
                                       createdAt: now.addingTimeInterval(Double(i))))
        }
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to save seeded items: \(error)")
        }
    }
}
