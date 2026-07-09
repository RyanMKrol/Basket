import Foundation
import StoreKit
import Observation
import os

/// A small consumable "tip jar" over StoreKit 2 — three coffee-themed tips.
/// Tipping is entirely optional and never unlocks anything; we just remember
/// that you've tipped so the About sheet can say a quiet thank you.
///
/// Note: not part of the native logic harness (it imports the iOS-only StoreKit);
/// real purchases are exercised in Xcode (StoreKit config) or App Store Connect
/// sandbox, not via build_run.sh.
@MainActor
@Observable
final class TipJar {
    /// Product ids — must match App Store Connect and StoreKit/Basket.storekit.
    /// Listed cheapest-first; `load()` re-sorts by price defensively.
    static let ids = [
        "com.ryankrol.basket.tip.coffee",
        "com.ryankrol.basket.tip.lunch",
        "com.ryankrol.basket.tip.feast",
    ]

    enum LoadState { case idle, loading, loaded, unavailable }

    private(set) var products: [Product] = []
    private(set) var state: LoadState = .idle
    /// The tip currently being purchased (drives the inline spinner).
    var purchasingID: Product.ID?
    /// True briefly right after a successful tip (drives the "Thank you!" line).
    var thanked = false
    /// Persisted: the user has tipped at least once.
    private(set) var hasTipped = UserDefaults.standard.bool(forKey: TipJar.tippedKey)

    private static let tippedKey = "basket.hasTipped"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ryankrol.basket", category: "TipJar")
    private var updatesTask: Task<Void, Never>?

    init() {
        // Finish transactions that arrive outside a direct purchase (e.g. an
        // Ask-to-Buy approval), so StoreKit doesn't keep re-delivering them.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let txn) = update {
                    await txn.finish()
                    self?.markTipped()
                }
            }
        }
    }

    /// Emoji + label for a tip product id.
    static func badge(for id: Product.ID) -> (emoji: String, label: String) {
        if id == ids[1] { return ("🥪", "Lunch") }
        if id == ids[2] { return ("🎁", "Feast") }
        return ("☕", "Coffee")
    }

    func load() async {
        guard state != .loaded else { return }
        state = .loading
        do {
            let fetched = try await Product.products(for: TipJar.ids).sorted { $0.price < $1.price }
            if fetched.isEmpty {
                // StoreKit reached Apple's servers fine and returned zero products for
                // known ids — this is an App Store Connect config/approval issue
                // (products not "Approved", or Agreements/Tax/Banking incomplete),
                // not a network or client-side problem. Logged distinctly from the
                // catch below so Console.app can tell the two apart.
                Self.logger.error("Product.products(for:) returned zero products for ids: \(TipJar.ids.joined(separator: ", "), privacy: .public)")
            } else if fetched.count < TipJar.ids.count {
                let missing = Set(TipJar.ids).subtracting(fetched.map(\.id))
                Self.logger.error("Product.products(for:) returned only \(fetched.count, privacy: .public)/\(TipJar.ids.count, privacy: .public) products; missing: \(missing.joined(separator: ", "), privacy: .public)")
            }
            products = fetched
            state = fetched.isEmpty ? .unavailable : .loaded
        } catch {
            Self.logger.error("Product.products(for:) threw: \(error.localizedDescription, privacy: .public)")
            state = .unavailable
        }
    }

    func tip(_ product: Product) async {
        purchasingID = product.id
        defer { purchasingID = nil }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let txn) = verification {
                    await txn.finish()          // consumable → finish immediately
                    markTipped()
                    thanked = true
                    Task { @MainActor [weak self] in   // momentary "Thank you!"
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        self?.thanked = false
                    }
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // A failed tip shouldn't shout at the user — quietly do nothing.
        }
    }

    private func markTipped() {
        hasTipped = true
        UserDefaults.standard.set(true, forKey: TipJar.tippedKey)
    }
}
