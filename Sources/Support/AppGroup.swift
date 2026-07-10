import Foundation

/// The App Group shared between the app, its Siri App Intent, and the widget
/// extension. The SwiftData store lives in this container so all three read and
/// write the same list.
///
/// The identifier must match the `com.apple.security.application-groups`
/// entitlement declared for every target that touches the store (see
/// `project.yml`). Change it in both places or the container lookup fails.
enum AppGroup {
    static let identifier = "group.com.ryankrol.basket"

    /// On-disk location of the shared SwiftData store, inside the App Group
    /// container. Traps if the container is unavailable — which only happens
    /// when the App Groups entitlement is missing, a build-configuration error
    /// rather than a runtime one worth recovering from (mirrors the existing
    /// `fatalError` on a failed `ModelContainer` init in `BasketApp`).
    static var storeURL: URL {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group container \(identifier) unavailable — is the App Groups entitlement present?")
        }
        return container.appendingPathComponent("Basket.store")
    }
}
