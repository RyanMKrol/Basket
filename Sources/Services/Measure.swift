import Foundation

/// How an item is measured. Drives the default unit and the stepper increments.
enum MeasureType { case count, weight, volume }

/// A concrete unit a quantity can be expressed in. Stored on `GroceryItem` as a
/// raw string so the schema is migration-proof.
enum MeasureUnit: String, CaseIterable {
    case count, gram, kilogram, milliliter, liter

    /// Short suffix shown after the number ("" for plain counts).
    var symbol: String {
        switch self {
        case .count:      return ""
        case .gram:       return "g"
        case .kilogram:   return "kg"
        case .milliliter: return "ml"
        case .liter:      return "L"
        }
    }

    var type: MeasureType {
        switch self {
        case .count:                return .count
        case .gram, .kilogram:      return .weight
        case .milliliter, .liter:   return .volume
        }
    }
}

/// Smart-units helper: guesses how an item is measured from its name and owns
/// the pure stepping/formatting logic the quantity editor leans on. All of this
/// is deterministic and unit-tested (no UI, no SwiftData) in tools/main.swift.
enum Measure {
    /// Best-guess measure type for an item name. Falls back to `.count` — the
    /// least-surprising default, and the user can change the unit anyway.
    static func typeForName(_ name: String) -> MeasureType {
        MeasureTable.match(name) ?? .count
    }

    /// The unit an item starts in the first time its quantity is set.
    static func defaultUnit(for name: String) -> MeasureUnit {
        switch typeForName(name) {
        case .count:  return .count
        case .weight: return .gram
        case .volume: return .milliliter
        }
    }

    /// A friendly starting amount for a freshly-set quantity.
    static func defaultValue(for unit: MeasureUnit) -> Double {
        switch unit {
        case .count:               return 1
        case .gram, .milliliter:   return 500
        case .kilogram, .liter:    return 1
        }
    }

    /// Step a value up or down with unit-appropriate increments and a floor so
    /// it never goes to zero or negative.
    static func step(_ value: Double, unit: MeasureUnit, up: Bool) -> Double {
        let delta: Double
        switch unit {
        case .count:               delta = 1
        case .gram, .milliliter:   delta = value >= 1000 ? 100 : 50
        case .kilogram, .liter:    delta = 0.25
        }
        let floor: Double = (unit == .count) ? 1 : delta
        return max(floor, value + (up ? delta : -delta))
    }

    /// Whether this unit has a larger/smaller sibling to toggle to (g↔kg, ml↔L).
    static func hasAlternateScale(_ unit: MeasureUnit) -> Bool { unit != .count }

    /// Toggle to the sibling scale, preserving the real amount (500 ml → 0.5 L).
    static func toggleScale(_ value: Double, unit: MeasureUnit) -> (Double, MeasureUnit) {
        switch unit {
        case .gram:       return (value / 1000, .kilogram)
        case .kilogram:   return (value * 1000, .gram)
        case .milliliter: return (value / 1000, .liter)
        case .liter:      return (value * 1000, .milliliter)
        case .count:      return (value, .count)
        }
    }

    /// "500 ml", "1.5 kg", "2".
    static func format(_ value: Double, unit: MeasureUnit) -> String {
        let n = number(value)
        return unit.symbol.isEmpty ? n : "\(n) \(unit.symbol)"
    }

    /// Trim trailing zeros: 2.0 → "2", 0.5 → "0.5", 1.25 → "1.25".
    private static func number(_ v: Double) -> String {
        let r = (v * 100).rounded() / 100
        if r == r.rounded() { return String(Int(r)) }
        var s = String(format: "%.2f", r)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }
}
