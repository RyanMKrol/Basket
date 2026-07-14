import Foundation

// MARK: - Types

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

// MARK: - Measure

/// Smart-units helper: guesses how an item is measured from its name and owns
/// the pure stepping/formatting logic the quantity editor leans on. All of this
/// is deterministic and unit-tested (no UI, no SwiftData) in tools/main.swift.
enum Measure {
    // We classify an item by the emoji the app already gives it — the glyph
    // encodes *what the thing is*, and reusing the emoji cascade means we get
    // its careful collision handling (eggplant≠egg) and offline semantic
    // fallback for free, instead of a parallel keyword table.
    //
    // Liquids you pour are volume; loose / weighed goods (produce, meat, fish,
    // cheese, grains, nuts) are weight; everything else the app recognises
    // (eggs, bread, packaged goods, household items…) is counted.
    private static let volumeGlyphs: Set<String> = [
        "🥛", "🧃", "🥤", "🍷", "🥂", "🍾", "🥃", "🍸", "🍹", "💧", "🧋", "🍶",
    ]
    private static let weightGlyphs: Set<String> = [
        // produce, fungi, herbs, nuts
        "🍎", "🍏", "🍐", "🍊", "🍋", "🍌", "🍓", "🫐", "🍒", "🍇", "🍑", "🍈", "🍉",
        "🥭", "🍍", "🥝", "🥥", "🥑", "🫒", "🍅", "🥔", "🥕", "🧅", "🧄", "🥬", "🥦",
        "🎃", "🥒", "🍆", "🫑", "🌶️", "🫛", "🫘", "🌽", "🍄", "🌿", "🌰", "🥜",
        // meat, fish, seafood
        "🥩", "🍖", "🥓", "🍗", "🐟", "🐠", "🐡", "🦐", "🦀", "🦞", "🦪", "🦑", "🦴",
        // dairy solids, grains, sugar
        "🧀", "🧈", "🥣", "🍚", "🍝", "🍜", "🍬",
    ]
    // Liquids whose emoji is an ambiguous container glyph (oils & vinegars map to
    // 🥫 / 🫒), so catch them by keyword before the glyph lookup.
    private static let liquidWords: Set<String> = ["oil", "vinegar"]

    /// The item's measure type, or nil when we don't recognise it at all — then
    /// every unit is offered, since we can't be sure what it is.
    static func typeForName(_ name: String) -> MeasureType? {
        let words = name.lowercased().split { !$0.isLetter }.map(String.init)
        if words.contains(where: { w in liquidWords.contains(where: { w.hasPrefix($0) }) }) {
            return .volume
        }
        let glyph = Emoji.forName(name)
        if glyph == Emoji.fallback { return nil }
        if volumeGlyphs.contains(glyph) { return .volume }
        if weightGlyphs.contains(glyph) { return .weight }
        return .count
    }

    /// The unit an item starts in the first time its quantity is set.
    static func defaultUnit(for name: String) -> MeasureUnit {
        switch typeForName(name) {
        case .volume:      return .milliliter
        case .weight:      return .gram
        case .count, nil:  return .count
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

    /// Step a value up or down to the next/previous bucket boundary, with
    /// unit-appropriate increments and a floor so it never reaches zero. Snapping
    /// onto the grid (rather than just adding the delta) keeps an off-grid amount
    /// tidy: a typed 501 steps up to a round 550 — not 551 — and down to 500.
    static func step(_ value: Double, unit: MeasureUnit, up: Bool) -> Double {
        let delta: Double
        switch unit {
        case .count:               delta = 1
        case .gram, .milliliter:   delta = value >= 1000 ? 100 : 50
        case .kilogram, .liter:    delta = 0.25
        }
        let buckets = value / delta
        let target = up ? (floor(buckets) + 1) * delta    // next bucket above
                        : (ceil(buckets) - 1) * delta      // first bucket below
        let minimum: Double = (unit == .count) ? 1 : delta
        return max(minimum, target)
    }

    /// The units a user can pick from for an item. Every item can be counted in
    /// plain "units"; a recognised liquid/solid also offers its scale pair; and
    /// an unrecognised item offers everything, since we can't be sure what they
    /// mean ("300 ml of milk" vs "1 bottle").
    static func units(for type: MeasureType?) -> [MeasureUnit] {
        switch type {
        case .volume: return [.milliliter, .liter, .count]
        case .weight: return [.gram, .kilogram, .count]
        case .count:  return [.count]
        case nil:     return [.milliliter, .liter, .gram, .kilogram, .count]   // unknown → offer all
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

    /// Parse a free-typed amount (from the editor's keyboard entry) into a clean
    /// value in `unit`, or nil when there's no sensible number to use so the
    /// existing quantity is kept. The unit's letters and stray spaces are ignored
    /// ("750 ml" → 750), both "." and "," work as the decimal point, counts round
    /// to whole numbers, anything zero-or-negative is rejected (a quantity can
    /// never be typed down to nothing), and a generous ceiling guards runaway
    /// input. Pairs with `numberString` (which seeds the field).
    static func parse(_ text: String, unit: MeasureUnit) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let normalised = trimmed.replacingOccurrences(of: ",", with: ".")
        var numberString = ""
        var seenDecimal = false

        for char in normalised {
            if char == "-" {
                return nil
            } else if char.isNumber {
                numberString.append(char)
            } else if char == "." && !seenDecimal {
                numberString.append(char)
                seenDecimal = true
            } else {
                break
            }
        }

        guard let raw = Double(numberString), raw > 0 else { return nil }
        let capped = min(raw, 100_000)
        return unit == .count ? max(1, capped.rounded()) : capped
    }

    /// "500 ml", "1.5 kg", "2".
    static func format(_ value: Double, unit: MeasureUnit) -> String {
        let n = numberString(value)
        return unit.symbol.isEmpty ? n : "\(n) \(unit.symbol)"
    }

    /// Just the number, trailing zeros trimmed: 2.0 → "2", 0.5 → "0.5", 1.25 →
    /// "1.25". Used both inside `format` and to seed the editable field.
    static func numberString(_ v: Double) -> String {
        let r = (v * 100).rounded() / 100
        if r == r.rounded() { return String(Int(r)) }
        var s = String(format: "%.2f", r)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }
}
