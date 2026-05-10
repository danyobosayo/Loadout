import Foundation
import SwiftData
import Testing
@testable import Loadout

@MainActor
struct LoggedMealTests {
    private static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: LoggedMeal.self, configurations: config)
    }

    private static func makeLineItem() -> LineItem {
        LineItem(
            id: UUID(),
            menuItemId: "x.a",
            displayName: "A",
            servingDescription: "1 portion",
            macros: Macros(calories: 100, proteinGrams: 10, carbGrams: 10, fatGrams: 5),
            quantity: 1,
            iconName: nil
        )
    }

    @Test func insertAndFetchPreservesFields() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let logged = LoggedMeal(
            restaurantId: "cava",
            lineItems: [Self.makeLineItem()]
        )
        context.insert(logged)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<LoggedMeal>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.restaurantId == "cava")
        #expect(fetched.first?.lineItems.count == 1)
    }

    @Test func enforceLimitDeletesOldestWhenOverCap() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        // Insert 53 logs at evenly-spaced timestamps so the oldest 3
        // should be evicted by `enforceLimit` against the cap of 50.
        for i in 0..<53 {
            let log = LoggedMeal(
                id: UUID(),
                restaurantId: "x",
                loggedAt: Date(timeIntervalSince1970: TimeInterval(i)),
                lineItems: [Self.makeLineItem()]
            )
            context.insert(log)
        }
        try context.save()
        try LoggedMealRetention.enforceLimit(in: context)
        try context.save()

        let remaining = try context.fetch(
            FetchDescriptor<LoggedMeal>(
                sortBy: [SortDescriptor(\LoggedMeal.loggedAt, order: .forward)]
            )
        )
        #expect(remaining.count == LoggedMealRetention.limit)
        // Oldest survivor should be the entry at i=3 (i=0..2 evicted).
        #expect(remaining.first?.loggedAt == Date(timeIntervalSince1970: 3))
        #expect(remaining.last?.loggedAt == Date(timeIntervalSince1970: 52))
    }

    @Test func enforceLimitNoOpUnderCap() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        for _ in 0..<10 {
            context.insert(LoggedMeal(restaurantId: "x", lineItems: [Self.makeLineItem()]))
        }
        try context.save()
        try LoggedMealRetention.enforceLimit(in: context)

        let count = try context.fetchCount(FetchDescriptor<LoggedMeal>())
        #expect(count == 10)
    }

    @Test func fetchReturnsMostRecentFirstWhenSorted() throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let earlier = LoggedMeal(
            id: UUID(),
            restaurantId: "x",
            loggedAt: Date(timeIntervalSince1970: 1_000),
            lineItems: [Self.makeLineItem()]
        )
        let later = LoggedMeal(
            id: UUID(),
            restaurantId: "y",
            loggedAt: Date(timeIntervalSince1970: 2_000),
            lineItems: [Self.makeLineItem()]
        )
        context.insert(earlier)
        context.insert(later)
        try context.save()

        let fetched = try context.fetch(
            FetchDescriptor<LoggedMeal>(
                sortBy: [SortDescriptor(\LoggedMeal.loggedAt, order: .reverse)]
            )
        )
        #expect(fetched.map(\.restaurantId) == ["y", "x"])
    }
}
