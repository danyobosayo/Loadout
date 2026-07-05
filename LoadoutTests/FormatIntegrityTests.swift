import Foundation
import Testing
@testable import Loadout

/// Every format references the live menu by id. These tests are the guard
/// rail that keeps `*.formats.json` honest — a typo'd or stale id fails
/// here instead of silently dropping a seed/prompt at runtime.
struct FormatIntegrityTests {
    private static let repository = BundledMenuRepository()
    private static let restaurantIds = ["chipotle", "cava", "panda-express", "sweetgreen", "subway"]

    private static func load(_ id: String) async throws -> (restaurant: Restaurant, formats: [OrderFormat]) {
        async let restaurant = repository.loadRestaurant(id: id)
        async let formats = repository.loadFormats(restaurantId: id)
        return try await (restaurant, formats)
    }

    @Test func everyRestaurantHasAtLeastOneFormat() async throws {
        for id in Self.restaurantIds {
            let formats = try await Self.repository.loadFormats(restaurantId: id)
            #expect(!formats.isEmpty, "\(id) has no formats")
        }
    }

    @Test func formatIdsAreUniqueWithinRestaurant() async throws {
        for id in Self.restaurantIds {
            let ids = try await Self.repository.loadFormats(restaurantId: id).map(\.id)
            #expect(Set(ids).count == ids.count, "duplicate format ids in \(id)")
        }
    }

    @Test func everyAutoAddResolves() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for seed in format.autoAdd {
                    #expect(restaurant.resolve(menuItemId: seed.menuItemId) != nil,
                            "\(id)/\(format.id): autoAdd \(seed.menuItemId) does not resolve")
                    #expect(seed.quantity > 0,
                            "\(id)/\(format.id): autoAdd \(seed.menuItemId) has non-positive quantity")
                }
            }
        }
    }

    @Test func everyPromptCategoryExists() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for prompt in format.prompts {
                    #expect(restaurant.category(id: prompt.categoryId) != nil,
                            "\(id)/\(format.id): prompt category '\(prompt.categoryId)' missing")
                }
            }
        }
    }

    @Test func everyOptionalCategoryExists() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for categoryId in format.optionalCategoryIds {
                    #expect(restaurant.category(id: categoryId) != nil,
                            "\(id)/\(format.id): optional category '\(categoryId)' missing")
                }
            }
        }
    }

    @Test func everySubsetItemExistsInItsCategory() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for prompt in format.prompts {
                    guard let subset = prompt.subsetItemIds else { continue }
                    #expect(!subset.isEmpty, "\(id)/\(format.id): empty subset on '\(prompt.categoryId)'")
                    let itemIds = Set(restaurant.category(id: prompt.categoryId)?.items.map(\.id) ?? [])
                    for itemId in subset {
                        #expect(itemIds.contains(itemId),
                                "\(id)/\(format.id): subset id '\(itemId)' not in category '\(prompt.categoryId)'")
                    }
                }
            }
        }
    }

    @Test func quantitiesArePositive() async throws {
        for id in Self.restaurantIds {
            let formats = try await Self.repository.loadFormats(restaurantId: id)
            for format in formats {
                #expect(format.portionMultiplier > 0,
                        "\(id)/\(format.id): portionMultiplier must be positive")
                for prompt in format.prompts {
                    #expect(prompt.quantityPerPick > 0,
                            "\(id)/\(format.id): quantityPerPick must be positive on '\(prompt.categoryId)'")
                }
            }
        }
    }

    @Test func missingFormatsFileReturnsEmpty() async throws {
        let formats = try await Self.repository.loadFormats(restaurantId: "no-such-place")
        #expect(formats.isEmpty)
    }
}
