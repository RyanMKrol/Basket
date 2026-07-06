import Foundation

/// Fixture constants compiled into BOTH the app target and the UI-test
/// bundle (see project.yml) — the UI tests drive flows against the starter
/// items, and a rename in one place but not the other used to be possible.
enum SharedFixtures {
    /// The friendly starter items seeded on a brand-new install
    /// (`BasketApp.seedIfEmpty`, which staggers createdAt so the list shows
    /// them in reverse order, newest first).
    static let starterItems = ["Milk", "Sourdough bread", "Eggs", "Tomatoes"]
}
