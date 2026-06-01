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

    /// The units a user can pick from for an item. Every item can be counted in
    /// plain "units"; a recognised liquid/solid also offers its scale pair; and
    /// an unrecognised item offers everything, since we can't be sure what they
    /// mean ("300 ml of milk" vs "1 bottle").
    static func units(for type: MeasureType) -> [MeasureUnit] {
        switch type {
        case .volume: return [.milliliter, .liter, .count]
        case .weight: return [.gram, .kilogram, .count]
        case .count:  return [.milliliter, .liter, .gram, .kilogram, .count]
        }
    }

    /// Convert a value when the user picks a different unit. Within a scale pair
    /// (ml↔L, g↔kg) the real amount is preserved (500 ml → 0.5 L); switching to a
    /// different *kind* of unit resets to that unit's sensible default, so the
    /// number can never carry over wrongly (500 ml → "units" starts at 1).
    static func changeUnit(_ value: Double, from: MeasureUnit, to: MeasureUnit) -> Double {
        if from == to { return value }
        switch (from, to) {
        case (.milliliter, .liter), (.gram, .kilogram):   return value / 1000
        case (.liter, .milliliter), (.kilogram, .gram):   return value * 1000
        default:                                          return defaultValue(for: to)
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
