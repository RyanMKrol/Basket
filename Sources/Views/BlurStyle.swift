import SwiftUI

/// Temporary debug enum for selecting blur intensity when the add bar is focused.
/// Three intensity levels so the owner can compare live and pick the best one.
/// This entire enum and its usage are temporary scaffolding; a follow-up task
/// will hardcode the chosen intensity and remove the switch.
enum BlurStyle: Int, CaseIterable {
    case light = 0
    case medium = 1
    case heavy = 2

    var blurRadius: CGFloat {
        switch self {
        case .light: 3
        case .medium: 8
        case .heavy: 16
        }
    }

    var label: String {
        switch self {
        case .light: "Light"
        case .medium: "Medium"
        case .heavy: "Heavy"
        }
    }
}
