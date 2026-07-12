import XCTest
@testable import Basket

final class SeasonalityTests: XCTestCase {
    var utc: Calendar!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        utc = cal
    }

    func seasonDate(_ y: Int, _ m: Int, _ day: Int, _ h: Int = 12) -> Date {
        utc.date(from: DateComponents(year: y, month: m, day: day, hour: h))!
    }

    func testTimeOfDay() {
        XCTAssertEqual(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 8), calendar: utc), .morning)
        XCTAssertEqual(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 19), calendar: utc), .evening)
        XCTAssertEqual(Seasonality.timeOfDay(seasonDate(2026, 6, 1, 2), calendar: utc), .night)
    }

    func testHolidayAccentHalloween() {
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 10, 31), calendar: utc), "🎃")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 10, 24), calendar: utc), "🎃")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 10, 23), calendar: utc), nil)
    }

    func testHolidayAccentChristmas() {
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 12, 20), calendar: utc), "🎄")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 12, 1), calendar: utc), "🎄")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 12, 25), calendar: utc), "🎄")
    }

    func testHolidayAccentNewYearBoundary() {
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 12, 27), calendar: utc), "🎉")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 12, 31), calendar: utc), "🎉")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 1, 1), calendar: utc), "🎉")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 1, 2), calendar: utc), nil)
    }

    func testHolidayAccentValentines() {
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 2, 14), calendar: utc), "💝")
    }

    func testHolidayAccentSpringBloom() {
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 4, 1), calendar: utc), "🌸")
        XCTAssertEqual(Seasonality.holidayAccent(seasonDate(2026, 4, 7), calendar: utc), "🌸")
    }

    func testHolidayAccentOrdinaryDay() {
        XCTAssertNil(Seasonality.holidayAccent(seasonDate(2026, 7, 4), calendar: utc))
    }

    func testEmptyStateLineStableWithinDay() {
        XCTAssertEqual(
            Seasonality.emptyStateLine(seasonDate(2026, 3, 10, 8), calendar: utc),
            Seasonality.emptyStateLine(seasonDate(2026, 3, 10, 22), calendar: utc)
        )
    }

    func testEmptyStateLineRotatesAcrossDays() {
        let day1Line = Seasonality.emptyStateLine(seasonDate(2026, 3, 1), calendar: utc)
        let day2Line = Seasonality.emptyStateLine(seasonDate(2026, 3, 2), calendar: utc)
        let day3Line = Seasonality.emptyStateLine(seasonDate(2026, 3, 3), calendar: utc)

        XCTAssertNotEqual(day1Line, day2Line)
        XCTAssertNotEqual(day2Line, day3Line)
    }
}
