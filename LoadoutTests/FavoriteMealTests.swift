import Foundation
import SwiftData
import Testing
@testable import Loadout

@MainActor
struct FavoriteMealTests {
    private static func makeContainer() throws -> ModelContainer {
        // In-memory only — tests must not write to the user's real
        // Application Support directory.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: FavoriteMeal.self, configurations: config)
    }

    private static func makeLineItem(
        id: String,
        name: String,
        cal: Double,
        p: Double,
        c: Double,
        f: Double,
        quantity: Double = 1
    ) -> LineItem {
        LineItem(
            id: UUID(),
            menuItemId: id,
            displayName: name,
            servingDescription: "1 portion",
            macros: Macros(calories: cal, proteinGrams: p, carbGrams: c, fatGrams: f),
            quantity: quantity,
            iconName: nil
        )
    }

    @Test func insertAndFetchPreservesLineItemFields() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        let chicken = Self.makeLineItem(id: "cava.mains.grilled-chicken", name: "Grilled Chicken", cal: 250, p: 28, c: 3, f: 13, quantity: 2)
        let rice = Self.makeLineItem(id: "cava.bases.brown-rice", name: "Brown Rice", cal: 310, p: 7, c: 48, f: 10)

        let favorite = FavoriteMeal(
            name: "Usual CAVA",
            restaurantId: "cava",
            lineItems: [chicken, rice]
        )
        context.insert(favorite)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FavoriteMeal>())
        #expect(fetched.count == 1)
        let restored = try #require(fetched.first)
        #expect(restored.name == "Usual CAVA")
        #expect(restored.restaurantId == "cava")
        #expect(restored.lineItems.count == 2)

        let restoredChicken = try #require(restored.lineItems.first { $0.menuItemId == chicken.menuItemId })
        #expect(restoredChicken.displayName == "Grilled Chicken")
        #expect(restoredChicken.quantity == 2)
        #expect(restoredChicken.macros.calories == 250)
        #expect(restoredChicken.macros.proteinGrams == 28)
    }

    @Test func totalMacrosScaleByLineItemQuantity() {
        let chicken = Self.makeLineItem(id: "x.chicken", name: "Chicken", cal: 200, p: 30, c: 0, f: 8, quantity: 2)
        let rice = Self.makeLineItem(id: "x.rice", name: "Rice", cal: 300, p: 5, c: 50, f: 5, quantity: 1)
        let favorite = FavoriteMeal(
            name: "Test",
            restaurantId: "x",
            lineItems: [chicken, rice]
        )
        let total = favorite.totalMacros
        #expect(total.calories == 200 * 2 + 300)
        #expect(total.proteinGrams == 30 * 2 + 5)
        #expect(total.fatGrams == 8 * 2 + 5)
    }

    @Test func deleteRemovesFavoriteFromContext() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        let favorite = FavoriteMeal(
            name: "Disposable",
            restaurantId: "x",
            lineItems: [Self.makeLineItem(id: "x.a", name: "A", cal: 1, p: 1, c: 1, f: 1)]
        )
        context.insert(favorite)
        try context.save()

        context.delete(favorite)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<FavoriteMeal>())
        #expect(remaining.isEmpty)
    }

    @Test func fetchReturnsMostRecentFirstWhenSorted() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        let older = FavoriteMeal(
            id: UUID(),
            name: "Older",
            restaurantId: "x",
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            lineItems: [Self.makeLineItem(id: "x.a", name: "A", cal: 1, p: 1, c: 1, f: 1)]
        )
        let newer = FavoriteMeal(
            id: UUID(),
            name: "Newer",
            restaurantId: "x",
            createdAt: Date(timeIntervalSince1970: 2_000_000),
            lineItems: [Self.makeLineItem(id: "x.b", name: "B", cal: 1, p: 1, c: 1, f: 1)]
        )
        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<FavoriteMeal>(
            sortBy: [SortDescriptor(\FavoriteMeal.createdAt, order: .reverse)]
        )
        let fetched = try context.fetch(descriptor)
        #expect(fetched.map(\.name) == ["Newer", "Older"])
    }
}
