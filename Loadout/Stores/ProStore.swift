import Foundation
import StoreKit
import Observation

/// Loadout Pro entitlement via native StoreKit 2 — no third-party dependency.
/// `isPro` gates the targeting layer (daily targets, Budget Mode, Apple Health,
/// Fit my macros). The purchase surface is deliberately thin so a RevenueCat
/// layer could slot in later without touching the gates.
@MainActor
@Observable
final class ProStore {
    /// Ordered for display: lifetime hero, then yearly, then monthly.
    static let lifetimeID = "danielsungsukim.Loadout.pro.lifetime"
    static let yearlyID = "danielsungsukim.Loadout.pro.yearly"
    static let monthlyID = "danielsungsukim.Loadout.pro.monthly"
    static let productIDs = [lifetimeID, yearlyID, monthlyID]

    private(set) var products: [Product] = []
    private(set) var isPro = false
    /// True until the first entitlement check completes — the UI shouldn't flash
    /// a paywall before we know.
    private(set) var isLoading = true

    // Held so the listener lives for the app's lifetime (this is a single
    // root-level store; it never deallocates during a session).
    private var updatesTask: Task<Void, Never>?

    init() {
        #if DEBUG
        // Test hook: `-loadout.debug.forcePro YES` unlocks Pro without StoreKit,
        // so UI tests can exercise the Pro surfaces. Never set in production.
        if UserDefaults.standard.bool(forKey: "loadout.debug.forcePro") {
            isPro = true
            isLoading = false
            return
        }
        #endif
        updatesTask = listenForTransactions()
        Task { await refresh() }
    }

    /// Reload products + entitlement (call on launch / when the paywall opens).
    func refresh() async {
        await loadProducts()
        await updateEntitlement()
        isLoading = false
    }

    func loadProducts() async {
        let loaded = (try? await Product.products(for: Self.productIDs)) ?? []
        // Stable display order: lifetime, yearly, monthly.
        let order = Dictionary(uniqueKeysWithValues: Self.productIDs.enumerated().map { ($1, $0) })
        products = loaded.sorted { (order[$0.id] ?? 99) < (order[$1.id] ?? 99) }
    }

    /// Returns true when the purchase completed and Pro is unlocked.
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await updateEntitlement()
            return isPro
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await updateEntitlement()
    }

    // MARK: - Entitlement

    private func updateEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            entitled = true
        }
        isPro = entitled
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.updateEntitlement()
            }
        }
    }
}
