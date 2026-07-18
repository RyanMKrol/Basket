import UIKit

/// Haptic feedback via pre-allocated generators to avoid per-call allocation.
/// No-ops harmlessly on the simulator. Suppressed under UI testing.
/// `@MainActor` because `UIFeedbackGenerator` is main-actor-isolated UIKit; every
/// call site (`soft()`/`success()`/`restore()`) already runs on the main thread.
@MainActor
enum Haptics {
    private static let softGen = UIImpactFeedbackGenerator(style: .soft)
    private static let impactGen = UIImpactFeedbackGenerator(style: .light)
    private static let successGen = UINotificationFeedbackGenerator()

    static func soft() {
        guard !TestHooks.isUITesting else { return }
        softGen.impactOccurred()
    }

    static func success() {
        guard !TestHooks.isUITesting else { return }
        successGen.notificationOccurred(.success)
    }

    static func restore() {
        guard !TestHooks.isUITesting else { return }
        impactGen.impactOccurred()
    }
}
