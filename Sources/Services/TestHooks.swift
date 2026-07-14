import SwiftUI

/// Central switchboard for the launch arguments / environment variables the
/// UI tests pass in (see `UITests/BasketUITestCase.swift`). Every hook is
/// inert in a normal launch, so production behaviour is untouched.
enum TestHooks {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// A UI test is driving the app: use a fresh in-memory store, skip the
    /// launch flourish.
    static let isUITesting = arguments.contains("-uiTesting")

    /// Skip the starter items so tests can begin from the empty state.
    static let startEmpty = arguments.contains("-uiTestingEmpty")

    /// Make every run render instantly and identically: SwiftUI/UIKit
    /// animations are dropped and the check-off commit delay shrinks, so
    /// tests wait on state, not on choreography.
    static let disableAnimations = arguments.contains("-uiTestingDisableAnimations")

    /// How long a just-checked row shows its spark burst before gliding into
    /// "Got it". The 0.55s is deliberate product behaviour; tests shrink it
    /// so flows don't spend most of their wall-clock inside this pause.
    static var checkCommitDelay: TimeInterval { disableAnimations ? 0.05 : 0.55 }

    /// How long the full-list "All done!" celebration stays up before it
    /// auto-dismisses. Production plays it for 1.6s; under UI testing we
    /// return nil to suppress the auto-dismiss entirely, so the overlay stays
    /// put for the test to observe. Otherwise the celebration is a transient
    /// 1.6s-of-real-time flourish that can appear and vanish in the gap before
    /// a slow/contended runner's first accessibility poll even lands — the
    /// overlay renders correctly (it's in the screenshot) yet every
    /// `waitForExistence` snapshot misses it. A relaunched, fresh-store app
    /// per test means a lingering overlay can't leak into another test, and
    /// it's `allowsHitTesting(false)` so it never blocks a later tap.
    static var celebrationDuration: TimeInterval? { isUITesting ? nil : 1.6 }

    /// How long the "Cleared N items — Undo" toast stays up before the
    /// buffered items are actually deleted. Production gives ~5s to react;
    /// under UI testing it shrinks to 3s — short enough to keep the
    /// let-it-expire flow fast, but long enough to survive XCUITest's own
    /// accessibility-tree synchronization overhead (each `waitFor…`/tap can
    /// itself cost the better part of a second) before the undo-in-time flow
    /// gets to check for the button.
    static var clearToastDuration: TimeInterval { disableAnimations ? 3.0 : 5.0 }

    /// The frozen wall-clock instant (ISO-8601, e.g. "2026-07-15T10:00:00Z")
    /// from the UITEST_FROZEN_DATE environment variable — so TTL cutoffs,
    /// seasonal flourishes, and the day-rotating empty-state line render the
    /// same on every run, any day of the year.
    static let frozenNow: Date? = ProcessInfo.processInfo
        .environment["UITEST_FROZEN_DATE"]
        .flatMap { ISO8601DateFormatter().date(from: $0) }

    /// UITEST_STORE_URL points the SwiftData store at a caller-owned temp
    /// file instead of the usual in-memory test store, so a relaunch test
    /// can verify data actually survives a cold start.
    static let storeURL: URL? = ProcessInfo.processInfo
        .environment["UITEST_STORE_URL"]
        .map { URL(fileURLWithPath: $0) }
}

/// The app's single source of "what time is it" — `Date.now` in production,
/// the frozen test instant under UI testing. Anything that renders or stores
/// the current time must come through here, or it escapes test control.
enum AppClock {
    static var now: Date { TestHooks.frozenNow ?? Date() }
}

/// `withAnimation`, minus the animation when a test asked for determinism.
func withAppAnimation<Result>(_ animation: Animation?, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(TestHooks.disableAnimations ? nil : animation, body)
}

extension Animation {
    /// For `.animation(_:value:)` modifiers: the animation as given, or nil
    /// (instant) when tests disable animations.
    var unlessUITesting: Animation? {
        TestHooks.disableAnimations ? nil : self
    }
}
