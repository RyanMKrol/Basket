import Foundation

/// A lightweight value for a suggestion row (decoupled from SwiftData/SwiftUI so
/// it's easy to preview and unit-test).
struct Suggestion: Identifiable, Equatable {
    let id: String       // the lower-cased name, stable identity
    let name: String     // display name
    let emoji: String

    init(name: String, emoji: String) {
        self.id = name.lowercased()
        self.name = name
        self.emoji = emoji
    }
}
