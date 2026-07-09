import XCTest
import SnapshotTesting
import SwiftUI
@testable import Basket

/// Pixel-level regression coverage for the core presentational views. The
/// flow tests attach screenshots nobody diffs; these are actual assertions —
/// a layout or visual regression fails the build, instead of waiting for a
/// human to eyeball it.
///
/// References live in `Tests/__Snapshots__/` and were recorded on an
/// iOS 26.x simulator. On any other major OS version the tests skip rather
/// than fail: text rendering drifts between OS majors, and a diff there
/// would be reporting the OS, not a regression.
///
/// Even within 26.x, rendering can drift a hair between the exact Xcode/
/// simulator build that recorded a reference and the one verifying it (this
/// bit us once — CI's runner and a local machine both "26.x" but not
/// byte-identical). Since CI's runner is the environment that actually gates
/// merges and releases, re-record there rather than locally: trigger the
/// `ci.yml` workflow manually (`workflow_dispatch`) with "Record snapshots"
/// checked, which sets `BASKET_RECORD_SNAPSHOTS=1` and uploads the refreshed
/// `Tests/__Snapshots__/` as a workflow artifact to download and commit.
final class SnapshotTests: XCTestCase {
    /// Matches `BasketUITestCase.frozenDate` — an ordinary July morning, so
    /// the empty state renders without a holiday accent, forever.
    private let fixedNow = ISO8601DateFormatter().date(from: "2026-07-15T09:00:00Z")!

    override func setUpWithError() throws {
        continueAfterFailure = false
        if ProcessInfo.processInfo.environment["BASKET_RECORD_SNAPSHOTS"] == "1" {
            isRecording = true
        }
        let version = UIDevice.current.systemVersion
        guard version.hasPrefix("26.") else {
            throw XCTSkip("References recorded on iOS 26.x; \(version) diffs on OS text rendering, not regressions.")
        }
    }

    /// Renders a component at the app's content width on a paper-ish
    /// background, so a reference diff shows the component, not transparency.
    private func assertComponent(_ view: some View, height: CGFloat,
                                 file: StaticString = #filePath,
                                 testName: String = #function,
                                 line: UInt = #line) {
        assertSnapshot(
            of: view.padding(12).background(Color(red: 0.98, green: 0.96, blue: 0.93)),
            as: .image(perceptualPrecision: 0.98, layout: .fixed(width: 390, height: height)),
            file: file, testName: testName, line: line
        )
    }

    func testItemRowToGet() {
        assertComponent(ItemRow(name: "Milk", emoji: "🥛", isChecked: false,
                                showsQuantity: true, onToggle: {}),
                        height: 100)
    }

    func testItemRowWithQuantity() {
        assertComponent(ItemRow(name: "Milk", emoji: "🥛", isChecked: false,
                                quantityText: "500 ml", showsQuantity: true, onToggle: {}),
                        height: 100)
    }

    func testItemRowCheckedInGotSection() {
        assertComponent(ItemRow(name: "Milk", emoji: "🥛", isChecked: true, onToggle: {})
                            .opacity(0.5),
                        height: 100)
    }

    func testQuantityEditor() {
        assertComponent(QuantityEditor(value: 500, unit: .milliliter,
                                       units: [.milliliter, .liter, .count],
                                       onStep: { _ in }, onPickUnit: { _ in },
                                       onSetValue: { _ in }, onClear: {}),
                        height: 140)
    }

    func testEmptyState() {
        assertSnapshot(
            of: ZStack { BasketBackground(); EmptyStateView(now: fixedNow) },
            as: .image(perceptualPrecision: 0.98, layout: .fixed(width: 390, height: 700))
        )
    }
}
