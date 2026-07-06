import XCTest
import StoreKit
import StoreKitTest
@testable import Basket

/// Drives the tip jar against a local `SKTestSession` on the same
/// `StoreKit/Basket.storekit` config the Xcode run scheme uses — purchases
/// were previously only testable by hand (build_run.sh bypasses the scheme's
/// StoreKit config; see CLAUDE.md).
///
/// Scope note — product *loading* only, empirically the limit of what this
/// environment supports:
/// - `product.purchase()` cannot run headless in a unit test: StoreKit 2
///   needs a UI anchor for the confirmation sheet and hangs forever without
///   one ("Could not find a UI anchor for … purchase").
/// - `session.buyProduct` (transaction injection) fails too — `notEntitled`
///   from the async API, `SKInternalErrorDomain Code=3` from the SK1-era
///   one — because SKTestSession's transaction *writes* need the StoreKit
///   configuration attached to the test run itself (an .xctestplan-level
///   setting; this project generates its scheme without test plans).
///   Product *reads* work fine against the programmatic session.
/// Purchase flows therefore stay a run-from-Xcode / sandbox concern (see
/// CLAUDE.md); adopting a test plan to unlock injected transactions is a
/// possible follow-up.
@MainActor
final class TipJarTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Basket")
        session.disableDialogs = true
        session.clearTransactions()
        UserDefaults.standard.removeObject(forKey: "basket.hasTipped")
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        UserDefaults.standard.removeObject(forKey: "basket.hasTipped")
    }

    func testLoadFetchesAllTipsCheapestFirst() async {
        let jar = TipJar()
        await jar.load()

        XCTAssertEqual(jar.state, .loaded)
        XCTAssertEqual(jar.products.count, TipJar.ids.count)
        XCTAssertEqual(jar.products.map(\.price), jar.products.map(\.price).sorted())
        XCTAssertEqual(Set(jar.products.map(\.id)), Set(TipJar.ids))
    }

    func testBadgesCoverEveryProduct() {
        for id in TipJar.ids {
            let badge = TipJar.badge(for: id)
            XCTAssertFalse(badge.emoji.isEmpty)
            XCTAssertFalse(badge.label.isEmpty)
        }
    }
}
