import XCTest
@testable import Basket

final class MeasureTests: XCTestCase {
    func testTypeForKnownItems() {
        XCTAssertEqual(Measure.typeForName("Milk"), .volume)
        XCTAssertEqual(Measure.typeForName("Almond milk"), .volume)
        XCTAssertEqual(Measure.typeForName("Orange juice"), .volume)
        XCTAssertEqual(Measure.typeForName("Olive oil"), .volume)
        XCTAssertEqual(Measure.typeForName("Cordial"), .volume)
        XCTAssertEqual(Measure.typeForName("Chicken breast"), .weight)
        XCTAssertEqual(Measure.typeForName("Plain flour"), .weight)
        XCTAssertEqual(Measure.typeForName("Cheddar"), .weight)
        XCTAssertEqual(Measure.typeForName("Cream cheese"), .weight)
        XCTAssertEqual(Measure.typeForName("Potatoes"), .weight)
        XCTAssertEqual(Measure.typeForName("Fresh basil"), .weight)
        XCTAssertEqual(Measure.typeForName("Habanero pepper"), .weight)
        XCTAssertEqual(Measure.typeForName("Yoghurt drink"), .volume)
        XCTAssertEqual(Measure.typeForName("Eggs"), .count)
        XCTAssertEqual(Measure.typeForName("Toilet roll"), .count)
        XCTAssertEqual(Measure.typeForName("Sourdough bread"), .count)
    }

    func testTypeForUnrecognisedItems() {
        XCTAssertNil(Measure.typeForName("zzxqwflumph"))
    }

    func testDefaultUnits() {
        XCTAssertEqual(Measure.defaultUnit(for: "Milk"), .milliliter)
        XCTAssertEqual(Measure.defaultUnit(for: "Beef mince"), .gram)
        XCTAssertEqual(Measure.defaultUnit(for: "Eggs"), .count)
    }

    func testSteppingWithSmallIncrementsUnder1000() {
        XCTAssertEqual(Measure.step(500, unit: .milliliter, up: true), 550)
        XCTAssertEqual(Measure.step(50, unit: .gram, up: false), 50)
        XCTAssertEqual(Measure.step(1, unit: .count, up: false), 1)
    }

    func testSteppingWithLargerIncrementsAbove1000() {
        XCTAssertEqual(Measure.step(1000, unit: .gram, up: true), 1100)
        XCTAssertEqual(Measure.step(1001, unit: .gram, up: true), 1100)
        XCTAssertEqual(Measure.step(999, unit: .gram, up: true), 1000)
        XCTAssertEqual(Measure.step(1100, unit: .gram, up: false), 1000)
    }

    func testSteppingSnapsOffGridValuesToNearestBucket() {
        XCTAssertEqual(Measure.step(501, unit: .milliliter, up: true), 550)
        XCTAssertEqual(Measure.step(501, unit: .milliliter, up: false), 500)
        XCTAssertEqual(Measure.step(100, unit: .gram, up: true), 150)
        XCTAssertEqual(Measure.step(100, unit: .gram, up: false), 50)
    }

    func testSteppingWithKilogramAndLiterIncrements() {
        XCTAssertEqual(Measure.step(1.1, unit: .kilogram, up: true), 1.25)
        XCTAssertEqual(Measure.step(1.1, unit: .kilogram, up: false), 1.0)
        XCTAssertEqual(Measure.step(550, unit: .milliliter, up: false), 500)
    }

    func testUnitConversionWithinScalePairs() {
        // ml ↔ L
        XCTAssertEqual(Measure.changeUnit(500, from: .milliliter, to: .liter), 0.5)
        XCTAssertEqual(Measure.changeUnit(0.5, from: .liter, to: .milliliter), 500)
        // g ↔ kg (NEW — was missing from native harness)
        XCTAssertEqual(Measure.changeUnit(1000, from: .gram, to: .kilogram), 1.0)
        XCTAssertEqual(Measure.changeUnit(1.5, from: .kilogram, to: .gram), 1500)
    }

    func testUnitConversionAcrossKindResetsToDefault() {
        XCTAssertEqual(Measure.changeUnit(500, from: .milliliter, to: .count), 1)
        XCTAssertEqual(Measure.changeUnit(2, from: .count, to: .milliliter), 500)
    }

    func testUnitsForMeasureType() {
        XCTAssertEqual(Measure.units(for: .volume), [.milliliter, .liter, .count])
        XCTAssertEqual(Measure.units(for: .weight), [.gram, .kilogram, .count])
        XCTAssertEqual(Measure.units(for: .count), [.count])
        XCTAssertEqual(Measure.units(for: nil), [.milliliter, .liter, .gram, .kilogram, .count])
    }

    func testUnitsForRecognisedItem() {
        XCTAssertEqual(Measure.units(for: Measure.typeForName("Fresh basil")), [.gram, .kilogram, .count])
    }

    func testFormatting() {
        XCTAssertEqual(Measure.format(500, unit: .milliliter), "500 ml")
        XCTAssertEqual(Measure.format(1.5, unit: .kilogram), "1.5 kg")
        XCTAssertEqual(Measure.format(2, unit: .count), "2")
    }

    func testNumberString() {
        XCTAssertEqual(Measure.numberString(2), "2")
        XCTAssertEqual(Measure.numberString(0.5), "0.5")
    }

    func testParsing() {
        XCTAssertEqual(Measure.parse("750", unit: .milliliter), 750)
        XCTAssertEqual(Measure.parse("1.5", unit: .kilogram), 1.5)
        XCTAssertEqual(Measure.parse("1,5", unit: .liter), 1.5)
        XCTAssertEqual(Measure.parse("750 ml", unit: .milliliter), 750)
        XCTAssertEqual(Measure.parse("12", unit: .count), 12)
        XCTAssertEqual(Measure.parse("3.7", unit: .count), 4)
        XCTAssertNil(Measure.parse("0", unit: .gram))
        XCTAssertNil(Measure.parse("", unit: .gram))
        XCTAssertNil(Measure.parse("abc", unit: .gram))
        XCTAssertEqual(Measure.parse("999999", unit: .gram), 100_000)
    }

    func testParsingRejectsNegative() {
        XCTAssertNil(Measure.parse("-5", unit: .gram))
    }

    func testParsingFirstNumberOnly() {
        XCTAssertEqual(Measure.parse("2x500", unit: .gram), 2)
        XCTAssertEqual(Measure.parse("750 ml", unit: .milliliter), 750)
    }

    func testParsingDecimalVariants() {
        XCTAssertEqual(Measure.parse("1.5", unit: .gram), 1.5)
        XCTAssertEqual(Measure.parse("1,5", unit: .gram), 1.5)
    }

    func testParsingLeadingDecimal() {
        XCTAssertEqual(Measure.parse(".5", unit: .gram), 0.5)
    }

    func testParsingEmptyInput() {
        XCTAssertNil(Measure.parse("", unit: .gram))
    }
}
