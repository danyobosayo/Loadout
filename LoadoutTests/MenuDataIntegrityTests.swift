import Foundation
import Testing
@testable import Loadout

struct MenuDataIntegrityTests {
    private static func loadAll() async throws -> [Restaurant] {
        try await BundledMenuRepository().availableRestaurants()
    }

    @Test func everyMacroIsNonNegative() async throws {
        for restaurant in try await Self.loadAll() {
            for category in restaurant.categories {
                for item in category.items {
                    #expect(item.macros.calories >= 0, "negative calories in \(item.id)")
                    #expect(item.macros.proteinGrams >= 0, "negative protein in \(item.id)")
                    #expect(item.macros.carbGrams >= 0, "negative carbs in \(item.id)")
                    #expect(item.macros.fatGrams >= 0, "negative fat in \(item.id)")
                }
            }
        }
    }

    @Test func everyItemIdIsUniqueWithinRestaurant() async throws {
        for restaurant in try await Self.loadAll() {
            let ids = restaurant.categories.flatMap { $0.items }.map(\.id)
            let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $1.count > 1 }.keys
            #expect(duplicates.isEmpty, "duplicate item ids in \(restaurant.id): \(Array(duplicates))")
        }
    }

    @Test func everyItemIdIsScopedToItsRestaurant() async throws {
        for restaurant in try await Self.loadAll() {
            let prefix = "\(restaurant.id)."
            for item in restaurant.categories.flatMap(\.items) {
                #expect(item.id.hasPrefix(prefix), "\(item.id) is not scoped under \(prefix)")
            }
        }
    }

    @Test func categoryIdsAreUniqueWithinRestaurant() async throws {
        for restaurant in try await Self.loadAll() {
            let ids = restaurant.categories.map(\.id)
            #expect(Set(ids).count == ids.count, "duplicate category ids in \(restaurant.id)")
        }
    }

    @Test func everyCategoryHasAtLeastOneItem() async throws {
        for restaurant in try await Self.loadAll() {
            for category in restaurant.categories {
                #expect(!category.items.isEmpty, "\(restaurant.id).\(category.id) has no items")
            }
        }
    }

    @Test func dataSourceIsDocumented() async throws {
        for restaurant in try await Self.loadAll() {
            #expect(!restaurant.dataSource.fetchedAt.isEmpty, "\(restaurant.id) is missing fetchedAt")
            #expect(!restaurant.dataSource.fetchedBy.isEmpty, "\(restaurant.id) is missing fetchedBy")
            #expect(restaurant.dataSource.url.host() != nil, "\(restaurant.id) source url has no host")
        }
    }
}
