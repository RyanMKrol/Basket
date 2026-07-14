import Foundation

/// Accessibility identifier constants compiled into BOTH the app target and the
/// UI-test bundle (see project.yml, same mechanism as `SharedFixtures`) — a
/// rename in one place but not the other used to silently break the UI tests.
enum A11yID {
    enum AddBar {
        static let textField = "addBar.textField"
        static let addButton = "addBar.addButton"
        static let dismissKeyboard = "addBar.dismissKeyboard"
        static func suggestion(_ name: String) -> String { "addBar.suggestion.\(name)" }
    }

    enum ItemRow {
        static func row(_ name: String) -> String { "itemRow.\(name)" }
        static func check(_ name: String) -> String { "itemRow.check.\(name)" }
        static func nameLabel(_ name: String) -> String { "itemRow.name.\(name)" }
        static func renameField(_ name: String) -> String { "itemRow.renameField.\(name)" }
        /// Queryable so a rename can be asserted to have re-derived the emoji
        /// (to-get rows only — see `ItemRow`).
        static func emoji(_ name: String) -> String { "itemRow.emoji.\(name)" }
    }

    enum QuantityEditor {
        static let clear = "quantityEditor.clear"
        static let field = "quantityEditor.field"
        static let value = "quantityEditor.value"
        static let increase = "quantityEditor.increase"
        static let decrease = "quantityEditor.decrease"
        static func unit(_ symbol: String) -> String { "quantityEditor.unit.\(symbol)" }
    }

    enum Header {
        static let count = "header.count"
        static let aboutButton = "header.aboutButton"
    }

    enum GotSection {
        static let header = "gotSection.header"
        static let clearAll = "gotSection.clearAll"
    }

    /// The header's "N to get" copy — shared so a change to it can't silently
    /// break the UI tests, which assert on the same string.
    static func toGetCountText(_ count: Int) -> String {
        count == 1 ? "1 to get" : "\(count) to get"
    }
}
