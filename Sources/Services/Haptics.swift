import UIKit

/// Tiny wrapper for the gentle haptic feedback used on add / check-off.
/// No-ops harmlessly on the simulator.
enum Haptics {
    static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}
