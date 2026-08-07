import Foundation
import Testing
@testable import Loadout

/// Presets assert "this is a real thing you can order," so the bar is higher
/// than for other bundled data: every line must resolve against the live menu,
/// and the totals we print on the card must equal the restaurant's own
/// published totals for that named item. A preset that silently drops a line
/// would undercount the meal — the worst possible failure for a macro app.
@MainActor
struct MealPresetTests {
    private let repository = BundledMenuRepository(bundle: .main)

    // Restaurants that publish named composed meals. Panda sells combos of
    // entrées rather than named dishes, so it ships no presets — that's the
    // graceful-degradation case, covered separately below.
    // `nonisolated` so the `@Test(arguments:)` macro can read it off the actor.
    nonisolated static let restaurantsWithPresets = ["sweetgreen", "chipotle"]

    @Test(arguments: restaurantsWithPresets)
    func everyPresetLineResolvesAgainstTheMenu(restaurantId: String) async throws {
        let restaurant = try await repository.loadRestaurant(id: restaurantId)
        let presets = try await repository.loadPresets(restaurantId: restaurantId)
        #expect(!presets.isEmpty, "\(restaurantId) should ship presets")

        for preset in presets {
            for seed in preset.items {
                #expect(
                    restaurant.resolve(menuItemId: seed.menuItemId) != nil,
                    "\(preset.id) references unknown item \(seed.menuItemId)"
                )
            }
            #expect(preset.isComplete(in: restaurant), "\(preset.id) has unresolved lines")
            #expect(preset.lineItems(in: restaurant).count == preset.items.count)
        }
    }

    @Test(arguments: restaurantsWithPresets)
    func presetIdsAreUniqueAndNamespaced(restaurantId: String) async throws {
        let presets = try await repository.loadPresets(restaurantId: restaurantId)
        #expect(Set(presets.map(\.id)).count == presets.count, "duplicate preset id")
        for preset in presets {
            #expect(preset.id.hasPrefix("\(restaurantId).presets."), "\(preset.id) is not namespaced")
            #expect(!preset.name.isEmpty)
            #expect(!preset.blurb.isEmpty)
            #expect(preset.sourceNote?.isEmpty == false, "\(preset.id) must record where its composition came from")
            #expect(preset.items.allSatisfy { $0.quantity > 0 })
        }
    }

    /// Spot-check against each restaurant's own published totals for the named
    /// meal. If a menu refresh changes a per-item value, these break loudly
    /// rather than quietly shifting what the card claims a Harvest Bowl costs.
    @Test(arguments: [
        ("sweetgreen", "sweetgreen.presets.harvest-bowl", 760.0, 40.0),
        ("sweetgreen", "sweetgreen.presets.kale-caesar", 510.0, 41.0),
        ("sweetgreen", "sweetgreen.presets.crispy-rice-bowl", 680.0, 33.0),
        // The Protein Plates serve a double grain base — this is the case that
        // would silently undercount if the quantities were ever reset to 1.
        ("sweetgreen", "sweetgreen.presets.plate-caramelized-garlic-steak", 770.0, 34.0),
        ("sweetgreen", "sweetgreen.presets.plate-hot-honey-chicken", 845.0, 49.0),
        // Chipotle's "light rice" half portion and "extra lettuce" double.
        ("chipotle", "chipotle.presets.double-high-protein", 760.0, 81.0),
    ])
    func macrosMatchThePublishedTotals(
        restaurantId: String, id: String, calories: Double, protein: Double
    ) async throws {
        let restaurant = try await repository.loadRestaurant(id: restaurantId)
        let presets = try await repository.loadPresets(restaurantId: restaurantId)
        let preset = try #require(presets.first { $0.id == id }, "missing preset \(id)")
        let macros = preset.macros(in: restaurant)

        // Restaurants publish rounded per-item values, so a composed total can
        // drift a gram from the composed figure they publish.
        #expect(abs(macros.calories - calories) <= 5)
        #expect(abs(macros.proteinGrams - protein) <= 1)
    }

    /// Chipotle publishes protein for the two bowls whose calories it omits —
    /// that's the only figure available to check them against.
    @Test(arguments: [
        ("chipotle.presets.high-protein-low-calorie", 36.0),
        ("chipotle.presets.high-protein-high-fiber", 46.0),
    ])
    func chipotleProteinOnlyBowlsMatchTheirPublishedProtein(id: String, protein: Double) async throws {
        let restaurant = try await repository.loadRestaurant(id: "chipotle")
        let presets = try await repository.loadPresets(restaurantId: "chipotle")
        let preset = try #require(presets.first { $0.id == id }, "missing preset \(id)")
        #expect(abs(preset.macros(in: restaurant).proteinGrams - protein) <= 1)
    }

    /// A restaurant with no presets file is normal, not an error.
    @Test func missingPresetsFileReturnsEmpty() async throws {
        #expect(try await repository.loadPresets(restaurantId: "panda-express").isEmpty)
        #expect(try await repository.loadPresets(restaurantId: "not-a-restaurant").isEmpty)
    }

    /// A preset that outlives a menu change shows fewer items than it promises —
    /// `isComplete` is what keeps that off the picker.
    @Test func aPresetWithAnUnknownLineIsIncomplete() async throws {
        let restaurant = try await repository.loadRestaurant(id: "sweetgreen")
        let preset = MealPreset(
            id: "sweetgreen.presets.test",
            name: "Test",
            blurb: "Test",
            items: [
                SeedItem(menuItemId: "sweetgreen.proteins.roasted-chicken", quantity: 1),
                SeedItem(menuItemId: "sweetgreen.bases.pulled-from-the-menu", quantity: 1),
            ]
        )
        #expect(preset.isComplete(in: restaurant) == false)
        #expect(preset.lineItems(in: restaurant).count == 1)   // drops, never fakes
    }

    /// Quantities scale the totals — the double-base plates depend on this.
    @Test func quantityScalesTheTotals() async throws {
        let restaurant = try await repository.loadRestaurant(id: "sweetgreen")
        let single = MealPreset(id: "a", name: "A", blurb: "A", items: [
            SeedItem(menuItemId: "sweetgreen.bases.white-rice", quantity: 1),
        ])
        let double = MealPreset(id: "b", name: "B", blurb: "B", items: [
            SeedItem(menuItemId: "sweetgreen.bases.white-rice", quantity: 2),
        ])
        #expect(double.macros(in: restaurant).calories == single.macros(in: restaurant).calories * 2)
    }
}
