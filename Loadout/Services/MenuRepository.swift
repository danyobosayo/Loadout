import Foundation
import SwiftUI

protocol MenuRepository: Sendable {
    func availableRestaurants() async throws -> [Restaurant]
    func loadRestaurant(id: String) async throws -> Restaurant
}

enum MenuRepositoryError: Error, Equatable {
    case notFound(String)
}

nonisolated struct BundledMenuRepository: MenuRepository {
    private let bundle: Bundle
    private let restaurantIds: [String]

    init(bundle: Bundle = .main, restaurantIds: [String] = ["chipotle", "cava"]) {
        self.bundle = bundle
        self.restaurantIds = restaurantIds
    }

    func availableRestaurants() async throws -> [Restaurant] {
        try restaurantIds.map { try loadFromBundle(id: $0) }
    }

    func loadRestaurant(id: String) async throws -> Restaurant {
        try loadFromBundle(id: id)
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
