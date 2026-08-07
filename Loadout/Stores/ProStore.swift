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

    /// **Launch switch.** The Pro products aren't live in App Store Connect yet,
    /// so every Pro surface ships unlocked for everyone. Flip to `false` once
    /// the products are configured and every gate re-arms — each one reads
    /// `isPro` and nothing else has to change. The paywall, the entitlement
    /// listener, and the purchase/restore paths all stay wired underneath.
    static let unlockedForEveryone = true

    private(set) var products: [Product] = []
    /// The real StoreKit entitlement, tracked independently of the launch
    /// switch so flipping the switch back is a true re-gate, not a reset.
    private(set) var hasProEntitlement = false
    /// True until the first entitlement check completes — the UI shouldn't flash
    /// a paywall before we know.
    private(set) var isLoading = true

    /// What every Pro gate reads.
    var isPro: Bool { isUnlockedForEveryone || hasProEntitlement }

    /// DEBUG-only inverse of the launch switch, so `PaywallUITests` can still
    /// exercise the gating + paywall UI while Pro ships unlocked.
    private let gatingForced: Bool

    private var isUnlockedForEveryone: Bool { !gatingForced && Self.unlockedForEveryone }

    // Held so the listener lives for the app's lifetime (this is a single
    // root-level store; it never deallocates during a session).
    private var updatesTask: Task<Void, Never>?

    init() {
        #if DEBUG
        gatingForced = UserDefaults.standard.bool(forKey: "loadout.debug.forceGating")
        // Test hook: `-loadout.debug.forcePro YES` unlocks Pro without StoreKit,
        // so UI tests can exercise the Pro surfaces. Never set in production.
        if UserDefaults.standard.bool(forKey: "loadout.debug.forcePro") {
            hasProEntitlement = true
            isLoading = false
            return
        }
        #else
        gatingForced = false
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
            return hasProEntitlement
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
        hasProEntitlement = entitled
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
