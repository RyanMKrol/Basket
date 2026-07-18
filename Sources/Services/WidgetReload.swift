import WidgetKit

/// A widget process never sees the app process's SwiftData writes on its
/// own — WidgetKit only refreshes a timeline when nudged, so every write
/// choke point in the app process must call through here after it saves (see
/// `BasketApp`'s scenePhase `.background` flush and
/// `AddToBasketIntent.perform()`). A test seam over
/// `WidgetCenter.shared.reloadTimelines(ofKind:)`, swapped out in unit tests
/// to assert the nudge fires without touching real WidgetKit.
enum WidgetReload {
    /// A unit-test host (BasketTests) launches the app for real but isn't a
    /// genuine widget-capable install — on a freshly (re)built simulator the
    /// widget kind isn't registered with the system yet, and calling the
    /// real WidgetKit API in that state traps. Mirrors `BasketApp.init`'s
    /// `TestHooks.isHostedByXCTest` bypass for the real App Group store.
    /// Tests that override `reloadTimelines` restore it via this constant
    /// (not a hand-written closure) so the guard can't be reintroduced stale.
    /// `nonisolated(unsafe)`: a non-`Sendable` closure constant, only ever invoked from
    /// already-`@MainActor` write choke points (see the type doc). Immutable after init.
    nonisolated(unsafe) static let defaultReloadTimelines: () -> Void = {
        guard !TestHooks.isHostedByXCTest else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: BasketWidgetIdentifiers.kind)
    }

    /// `nonisolated(unsafe)`: a mutable static holding a non-`Sendable` closure. It is
    /// reassigned only by unit tests (on the test's main thread) and invoked only from
    /// already-`@MainActor` write choke points, so access is effectively serialised.
    /// Revisit if a background writer ever needs to nudge the widget.
    nonisolated(unsafe) static var reloadTimelines: () -> Void = defaultReloadTimelines
}
