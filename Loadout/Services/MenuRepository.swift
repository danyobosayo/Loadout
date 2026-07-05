import Foundation
import SwiftUI

protocol MenuRepository: Sendable {
    func availableRestaurants() async throws -> [Restaurant]
    func loadRestaurant(id: String) async throws -> Restaurant
    /// The order formats for a restaurant (Burrito, Grain Bowl…). A
    /// missing formats file is not an error — it degrades to the
    /// build-your-own-only experience.
    func loadFormats(restaurantId: String) async throws -> [OrderFormat]
}

enum MenuRepositoryError: Error, Equatable {
    case notFound(String)
}

nonisolated struct BundledMenuRepository: MenuRepository {
    private let bundle: Bundle
    private let restaurantIds: [String]

    init(bundle: Bundle = .main, restaurantIds: [String] = ["chipotle", "cava", "panda-express", "sweetgreen", "subway"]) {
        self.bundle = bundle
        self.restaurantIds = restaurantIds
    }

    func availableRestaurants() async throws -> [Restaurant] {
        let restaurants = try restaurantIds.map { try loadFromBundle(id: $0) }
        // Alphabetical by display name per PROJECT.md §7.1. Recency-of-use
        // sort lands when History persistence ships and we know what's
        // recent — until then, alphabetical is the stable default.
        return restaurants.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func loadRestaurant(id: String) async throws -> Restaurant {
        try loadFromBundle(id: id)
    }

    func loadFormats(restaurantId: String) async throws -> [OrderFormat] {
        // No formats file → build-your-own only. Never throws on absence.
        guard let url = bundle.url(forResource: "\(restaurantId).formats", withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RestaurantFormats.self, from: data).formats
    }

    private func loadFromBundle(id: String) throws -> Restaurant {
        guard let url = bundle.url(forResource: id, withExtension: "json") else {
            throw MenuRepositoryError.notFound(id)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Restaurant.self, from: data)
    }
}

extension EnvironmentValues {
    @Entry var menuRepository: any MenuRepository = BundledMenuRepository()
}
