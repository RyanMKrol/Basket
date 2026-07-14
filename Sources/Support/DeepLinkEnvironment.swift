import SwiftUI

enum DeepLinkEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var shouldFocusAddBar: Bool {
        get { self[DeepLinkEnvironmentKey.self] }
        set { self[DeepLinkEnvironmentKey.self] = newValue }
    }
}
