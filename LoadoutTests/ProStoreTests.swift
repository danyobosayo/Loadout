import Foundation
import Testing
import StoreKitTest
@testable import Loadout

/// Tests the entitlement logic, not StoreKit's own purchase UI (which needs a
/// window scene and hangs headless). `SKTestSession.buyProduct` simulates the
/// purchase; `ProStore` must reflect it.
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
        #expect(store.isPro == false)
        #expect(store.isLoading == false)
    }

    @Test func recognizesALifetimeEntitlement() async throws {
        let session = try freshSession()
        try await session.buyProduct(productIdentifier: ProStore.lifetimeID)
        let store = ProStore()
        await store.refresh()
        #expect(store.isPro == true)
    }

    @Test func recognizesASubscriptionEntitlement() async throws {
        let session = try freshSession()
        try await session.buyProduct(productIdentifier: ProStore.yearlyID)
        let store = ProStore()
        await store.refresh()
        #expect(store.isPro == true)
    }
}
