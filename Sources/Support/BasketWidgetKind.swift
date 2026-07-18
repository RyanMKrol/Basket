import Foundation

/// The widget's stable kind identifier — shared between the app (which nudges
/// `WidgetCenter.shared.reloadTimelines(ofKind:)` after every write choke
/// point, see `WidgetReload`) and the extension itself
/// (`BasketWidget/BasketWidget.swift`'s `StaticConfiguration(kind:)`), so a
/// rename in one place can't silently desync from the other.
enum BasketWidgetIdentifiers {
    static let kind = "BasketWidget"
    static let addKind = "BasketAddWidget"
    static let combinedKind = "BasketCombinedWidget"
}
