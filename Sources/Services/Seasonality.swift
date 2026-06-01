import Foundation

/// Rough part of the day, for a gentle background tint.
enum TimeOfDay { case morning, afternoon, evening, night }

/// Calendar season (Northern-hemisphere assumption — a future `hemisphere`
/// parameter could flip it).
enum Season { case spring, summer, autumn, winter }

/// Pure, date-driven flourishes that make Basket feel a little alive — a
/// time-of-day tint, an occasional holiday accent, and a rotating empty-state
/// line. All functions take `now` (and an optional calendar) so they're fully
/// deterministic and unit-tested in tools/main.swift — no SwiftUI here.
enum Seasonality {
    static func timeOfDay(_ now: Date, calendar: Calendar = .current) -> TimeOfDay {
        switch calendar.component(.hour, from: now) {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }

    static func season(_ now: Date, calendar: Calendar = .current) -> Season {
        switch calendar.component(.month, from: now) {
        case 3...5:  return .spring
        case 6...8:  return .summer
        case 9...11: return .autumn
        default:     return .winter
        }
    }

    /// A subtle seasonal/holiday emoji accent, or nil on ordinary days (most of
    /// the year). Kept sparse on purpose.
    static func holidayAccent(_ now: Date, calendar: Calendar = .current) -> String? {
        let m = calendar.component(.month, from: now)
        let d = calendar.component(.day, from: now)
        switch (m, d) {
        case (10, 24...31):            return "🎃"   // Halloween week
        case (12, 1...26):             return "🎄"   // the run-up to Christmas
        case (12, 27...31), (1, 1):    return "🎉"   // New Year
        case (2, 14):                  return "💝"   // Valentine's
        case (4, 1...7):               return "🌸"   // early spring bloom
        default:                       return nil
        }
    }

    /// A friendly empty-state headline that rotates by day (stable within a day,
    /// so it doesn't flicker as the view redraws).
    static func emptyStateLine(_ now: Date, calendar: Calendar = .current) -> String {
        let lines = [
            "Your basket's empty",
            "Nothing on the list yet",
            "A fresh, empty basket",
            "Ready when you are",
            "What do you need today?",
        ]
        let day = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        return lines[day % lines.count]
    }
}
