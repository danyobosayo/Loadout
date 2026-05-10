import Foundation
import Testing
@testable import Loadout

struct MenuRepositoryTests {
    private let repository = BundledMenuRepository()

    @Test func chipotleLoadsAndDecodes() async throws {
        let chipotle = try await repository.loadRestaurant(id: "chipotle")
        #expect(chipotle.id == "chipotle")
        #expect(chipotle.name == "Chipotle")
        #expect(chipotle.schemaVersion == 1)
        #expect(!chipotle.categories.isEmpty)
    }

    @Test func availableRestaurantsIncludesChipotle() async throws {
        let restaurants = try await repository.availableRestaurants()
        #expect(restaurants.contains(where: { $0.id == "chipotle" }))
    }

    @Test func unknownRestaurantThrowsNotFound() async throws {
        await #expect(throws: MenuRepositoryError.notFound("no-such-place")) {
            _ = try await repository.loadRestaurant(id: "no-such-place")
        }
    }
}
