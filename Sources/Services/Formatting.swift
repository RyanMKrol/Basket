import Foundation

extension String {
    /// Capitalises the first letter, leaving the rest as typed.
    /// "olive oil" -> "Olive oil", "BBQ sauce" -> "BBQ sauce".
    var capitalisedFirstLetter: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
