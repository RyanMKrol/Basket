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

    enum TipStatus: Equatable {
        case idle
        case purchasing
        case pendingApproval
        case failed(message: String)
        case thanked
    }

    enum TipOutcome {
        case success
        case cancelled
        case pending
        case failure(message: String)
    }

    private(set) var products: [Product] = []
    private(set) var state: LoadState = .idle
    /// The tip currently being purchased (drives the inline spinner).
    var purchasingID: Product.ID?
    /// Status of the tip purchase flow.
    private(set) var status: TipStatus = .idle
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
                    self?.transactionUpdateArrived()
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
                Self.logger.error(
                    "Product.products(for:) returned zero products for ids: \(TipJar.ids.joined(separator: ", "), privacy: .public)"
                )
            } else if fetched.count < TipJar.ids.count {
                let missing = Set(TipJar.ids).subtracting(fetched.map(\.id))
                Self.logger.error(
                    "Product.products(for:) returned only \(fetched.count, privacy: .public)/\(TipJar.ids.count, privacy: .public) products; missing: \(missing.joined(separator: ", "), privacy: .public)"
                )
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
        beginTip()
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let txn) = verification {
                    await txn.finish()
                    resolve(.success)
                }
            case .userCancelled:
                resolve(.cancelled)
            case .pending:
                resolve(.pending)
            @unknown default:
                break
            }
        } catch {
            resolve(.failure(message: "Couldn't reach the App Store. Please try again later."))
        }
    }

    func beginTip() {
        status = .purchasing
    }

    func resolve(_ outcome: TipOutcome) {
        switch outcome {
        case .success:
            markTipped()
            status = .thanked
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.status = .idle
            }
        case .cancelled:
            status = .idle
        case .pending:
            status = .pendingApproval
        case .failure(let message):
            status = .failed(message: message)
        }
    }

    func transactionUpdateArrived() {
        if status == .pendingApproval {
            markTipped()
            status = .thanked
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.status = .idle
            }
        } else {
            markTipped()
        }
    }

    private func markTipped() {
        hasTipped = true
        UserDefaults.standard.set(true, forKey: TipJar.tippedKey)
    }
}
