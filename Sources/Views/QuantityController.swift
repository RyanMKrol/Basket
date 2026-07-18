import SwiftUI
import SwiftData

/// Wires the quantity editor's five actions (toggle/step/pick-unit/set/clear)
/// onto a `GroceryItem`. Holds the bindings `ShoppingListView` threads through
/// (the expanded-row id, and the add bar's draft/focus so opening an editor
/// can drop them) so the row handlers stay small, testable free functions
/// instead of methods scattered across the root view.
/// `@MainActor`: it holds SwiftUI `@Binding`/`FocusState` bindings, mutates SwiftData
/// model objects, and calls the main-actor `Haptics` — every method is invoked from the
/// main-actor view layer (`ShoppingListView`).
@MainActor
struct QuantityController {
    @Binding var expandedID: PersistentIdentifier?
    @Binding var draft: String
    var addBarFocused: FocusState<Bool>.Binding

    /// Open/close a row's quantity editor. Opening for the first time seeds a
    /// smart default (e.g. milk → 500 ml) inferred from the item name.
    func toggle(_ item: GroceryItem) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if expandedID == item.persistentModelID {
                expandedID = nil
            } else {
                // Clear any half-typed add-bar entry and drop its keyboard so the
                // leftover text + suggestion stack don't linger behind the
                // quantity editor.
                draft = ""
                addBarFocused.wrappedValue = false
                if item.quantity == nil || item.unit == nil {
                    let u = Measure.defaultUnit(for: item.name)
                    item.unit = u
                    item.quantity = Measure.defaultValue(for: u)
                }
                expandedID = item.persistentModelID
            }
        }
        Haptics.soft()
    }

    func step(_ item: GroceryItem, up: Bool) {
        guard let u = item.unit else { return }
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = Measure.step(item.quantity ?? Measure.defaultValue(for: u), unit: u, up: up)
        }
        Haptics.soft()
    }

    func pickUnit(_ item: GroceryItem, _ newUnit: MeasureUnit) {
        guard let u = item.unit else { return }
        let newValue = Measure.changeUnit(item.quantity ?? Measure.defaultValue(for: u),
                                          from: u, to: newUnit)
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = newValue
            item.unit = newUnit
        }
        Haptics.soft()
    }

    /// Apply an exact amount typed straight into the editor's value field — the
    /// keyboard shortcut past tapping +/- many times for a large quantity. The
    /// field only hands back values that already parsed sanely (see Measure.parse).
    func setValue(_ item: GroceryItem, _ value: Double) {
        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            item.quantity = value
        }
        Haptics.soft()
    }

    func clear(_ item: GroceryItem) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            item.quantity = nil
            item.unitRaw = nil
            expandedID = nil
        }
        Haptics.soft()
    }
}
