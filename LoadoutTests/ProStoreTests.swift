import Foundation
import Testing
import StoreKitTest
@testable import Loadout

/// Tests the entitlement logic, not StoreKit's own purchase UI (which needs a
/// window scene and hangs headless). `SKTestSession.buyProduct` simulates the
/// purchase; `ProStore` must reflect it.
///
/// These assert on `hasProEntitlement`, not `isPro`: Pro currently ships
/// unlocked for everyone (`ProStore.unlockedForEveryone`), so `isPro` is true
/// regardless. The entitlement has to keep working underneath for the day that
/// switch flips — `unlockSwitchOverridesTheEntitlement` covers the switch itself.
// Serialized: each test drives a process-wide SKTestSession, so they can't run
// in parallel without clobbering each other's StoreKit state.
@MainActor
@Suite(.serialized)
struct ProStoreTests {
    private func freshSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Loadout")
        session.disableDialogs = true
        session.resetToDefaultState()
        try session.clearTransactions()
        return session
    }

    @Test func loadsThreeProductsInDisplayOrder() async throws {
        _ = try freshSession()
        let store = ProStore()
        await store.refresh()
        #expect(store.products.map(\.id) == ProStore.productIDs)   // lifetime, yearly, monthly
        #expect(store.hasProEntitlement == false)
        #expect(store.isLoading == false)
    }

    @Test func recognizesALifetimeEntitlement() async throws {
        let session = try freshSession()
        try await session.buyProduct(productIdentifier: ProStore.lifetimeID)
        let store = ProStore()
        await store.refresh()
        #expect(store.hasProEntitlement == true)
        #expect(store.isPro == true)
    }

    @Test func recognizesASubscriptionEntitlement() async throws {
        let session = try freshSession()
        try await session.buyProduct(productIdentifier: ProStore.yearlyID)
        let store = ProStore()
        await store.refresh()
        #expect(store.hasProEntitlement == true)
        #expect(store.isPro == true)
    }

    /// While Pro ships unlocked, every gate must read open even with no
    /// purchase behind it. Flipping `unlockedForEveryone` to false makes this
    /// assert the opposite — which is exactly the re-gate signal we want.
    @Test func unlockSwitchOverridesTheEntitlement() async throws {
        _ = try freshSession()
        let store = ProStore()
        await store.refresh()
        #expect(store.hasProEntitlement == false)
        #expect(store.isPro == ProStore.unlockedForEveryone)
    }
}
