import Foundation
import Testing
@testable import Loadout

/// The rule this whole file defends: **the published total is authoritative.**
/// A Box Combo reads 1290 because Cane's says 1290, and configuring it can only
/// subtract a sourced component from that figure. Nothing here may recompute a
/// total by summing parts — that is how a menu drifts off the board.
@MainActor
struct ItemConfigurationTests {
    private func canes() async throws -> Restaurant {
        try await BundledMenuRepository().loadRestaurant(id: "raising-canes")
    }

    private func item(_ restaurant: Restaurant, _ id: String) throws -> MenuItem {
        try #require(restaurant.resolve(menuItemId: id)?.item)
    }

    @Test func canesIsConfiguredTopDownNotAssembled() async throws {
        #expect(try await canes().orderingModel == .configuration)
    }

    /// An untouched combo reads exactly what the menu board reads.
    @Test(arguments: [
        ("raising-canes.combos.box-combo", 1290.0),
        ("raising-canes.combos.3-finger-combo", 1050.0),
        ("raising-canes.combos.caniac-combo", 1840.0),
        ("raising-canes.combos.sandwich-combo", 1140.0),
        ("raising-canes.combos.kids-combo", 650.0),
    ])
    func anUnchangedComboMatchesThePublishedTotal(id: String, calories: Double) async throws {
        let restaurant = try await canes()
        let combo = try item(restaurant, id)
        #expect(combo.isConfigurable)
        #expect(combo.macros(with: .unchanged, in: restaurant).calories == calories)
    }

    /// Swapping the slaw for fries — the single most common Cane's modification.
    @Test func droppingASideSubtractsExactlyThatSide() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        let slaw = try item(restaurant, "raising-canes.sides.coleslaw")

        let without = box.macros(
            with: ItemConfiguration(removed: ["raising-canes.sides.coleslaw"]),
            in: restaurant
        )
        #expect(without.calories == 1290 - slaw.macros.calories)
        #expect(without.fatGrams == 72 - slaw.macros.fatGrams)
    }

    /// A quantity-2 component subtracts twice — the Caniac ships two sauces.
    @Test func removingAMultiQuantityComponentSubtractsAllOfIt() async throws {
        let restaurant = try await canes()
        let caniac = try item(restaurant, "raising-canes.combos.caniac-combo")
        let sauce = try item(restaurant, "raising-canes.dips.canes-sauce")

        let dry = caniac.macros(
            with: ItemConfiguration(removed: ["raising-canes.dips.canes-sauce"]),
            in: restaurant
        )
        #expect(dry.calories == 1840 - sauce.macros.calories * 2)
    }

    /// The fingers ARE the combo. Removing them would leave a side order, so the
    /// component is marked unremovable and a configuration naming it is ignored.
    @Test func anUnremovableComponentCannotBeSubtracted() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        let attempt = box.macros(
            with: ItemConfiguration(removed: ["raising-canes.entrees.chicken-finger"]),
            in: restaurant
        )
        #expect(attempt.calories == 1290)
    }

    /// …and it isn't shown either, per the call to hide rather than grey out.
    @Test func unremovableDefaultsAreHiddenFromTheSheet() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        #expect(!box.removableDefaults.contains { $0.menuItemId.hasSuffix("chicken-finger") })
        #expect(box.removableDefaults.count == 4)  // fries, toast, slaw, sauce
    }

    /// Extras are off until tapped, and adding one adds a real sourced item.
    @Test func addingAnExtraAddsThatItemsMacros() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        let sauce = try item(restaurant, "raising-canes.dips.canes-sauce")

        #expect(box.availableExtras.contains { $0.menuItemId == sauce.id })
        let extra = box.macros(
            with: ItemConfiguration(added: [ItemComponent(menuItemId: sauce.id, isDefault: false)]),
            in: restaurant
        )
        #expect(extra.calories == 1290 + sauce.macros.calories)
    }

    /// An extra listed but never switched on must not be subtractable — it was
    /// never in the total to begin with.
    @Test func removingAnExtraThatWasNeverAddedChangesNothing() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        let attempt = box.macros(
            with: ItemConfiguration(removed: ["raising-canes.dips.ketchup"]),
            in: restaurant
        )
        #expect(attempt.calories == 1290)
    }

    @Test func theTraySummaryReadsBackTheOrder() async throws {
        let restaurant = try await canes()
        let box = try item(restaurant, "raising-canes.combos.box-combo")
        let summary = box.configurationSummary(
            ItemConfiguration(
                removed: ["raising-canes.sides.coleslaw"],
                added: [ItemComponent(menuItemId: "raising-canes.dips.canes-sauce", isDefault: false)]
            ),
            in: restaurant
        )
        #expect(summary == "no coleslaw · extra cane's sauce")
        #expect(box.configurationSummary(.unchanged, in: restaurant) == nil)
    }

    /// Combo-portion fries are a real part of a Box Combo but not something you
    /// can walk up and order, so they resolve without ever being listed.
    @Test func pantryItemsResolveButAreNeverOrderable() async throws {
        let restaurant = try await canes()
        #expect(restaurant.resolve(menuItemId: "raising-canes.pantry.fries-combo") != nil)
        #expect(!restaurant.orderableCategories.contains { $0.id == "pantry" })
        #expect(restaurant.categories.contains { $0.id == "pantry" })
    }

    // MARK: Chick-fil-A — as-served totals

    private func cfa() async throws -> Restaurant {
        try await BundledMenuRepository().loadRestaurant(id: "chick-fil-a")
    }

    /// The salads used to be stored dressing-free — a Cobb read 520 when the
    /// board says 830, undercounting by a whole 310-cal dressing. Every salad
    /// must now read as served.
    @Test(arguments: [
        ("chick-fil-a.mains.cobb-salad-base", 830.0),
        ("chick-fil-a.mains.market-salad-base", 550.0),
        ("chick-fil-a.mains.spicy-southwest-salad", 680.0),
        ("chick-fil-a.sides.side-salad", 470.0),
    ])
    func saladsCarryTheirDressing(id: String, calories: Double) async throws {
        let restaurant = try await cfa()
        let salad = try item(restaurant, id)
        #expect(salad.macros.calories == calories)
        #expect(salad.isConfigurable, "a salad must expose its dressing so it can be declined")
    }

    /// The live double-count: the Cool Wrap's 660 already contains Avocado Lime
    /// Ranch. Taking it off must land on the derived undressed figure exactly —
    /// all four macros, not just calories.
    @Test func removingTheCoolWrapsBuiltInDressingLandsOnTheUndressedFigure() async throws {
        let restaurant = try await cfa()
        let wrap = try item(restaurant, "chick-fil-a.entrees.chick-fil-a-cool-wrap")
        #expect(wrap.macros.calories == 660)

        let undressed = wrap.macros(
            with: ItemConfiguration(removed: ["chick-fil-a.dressings.avocado-lime-ranch-dressing"]),
            in: restaurant
        )
        #expect(undressed.calories == 350)
        #expect(undressed.proteinGrams == 42)
        #expect(undressed.carbGrams == 29)
        #expect(undressed.fatGrams == 13)
    }

    /// Swapping a dressing must cost the difference between the two, not add a
    /// whole second dressing on top of the one already in the total.
    @Test func swappingADressingIsADifferenceNotAnAddition() async throws {
        let restaurant = try await cfa()
        let cobb = try item(restaurant, "chick-fil-a.mains.cobb-salad-base")
        let italian = try item(restaurant, "chick-fil-a.dressings.light-italian-dressing")

        let swapped = cobb.macros(
            with: ItemConfiguration(
                removed: ["chick-fil-a.dressings.avocado-lime-ranch-dressing"],
                added: [ItemComponent(menuItemId: italian.id, isDefault: false)]
            ),
            in: restaurant
        )
        // 830 − 310 (avocado ranch) + 25 (light italian)
        #expect(swapped.calories == 545)
    }

    /// The grilled bun and filet can't be separated — the a la carte parts leave
    /// a 60-cal residual against the board figure — so they ship fused, and
    /// fused means hidden.
    @Test func theGrilledBunAndFiletShipFusedAndHidden() async throws {
        let restaurant = try await cfa()
        let grilled = try item(restaurant, "chick-fil-a.entrees.grilled-chicken-sandwich")
        #expect(grilled.macros.calories == 390)
        #expect(!grilled.removableDefaults.contains { $0.menuItemId.contains("bun") })
        // Lettuce and tomato on top of that block are exact, so they stay editable.
        #expect(grilled.removableDefaults.contains { $0.menuItemId.hasSuffix("green-leaf-lettuce") })
    }

    /// Stripping every removable default must never drive a total below zero —
    /// that would mean a component is bigger than the item it belongs to.
    @Test func noConfiguredItemCanBeStrippedBelowZero() async throws {
        for id in ["chick-fil-a", "raising-canes"] {
            let restaurant = try await BundledMenuRepository().loadRestaurant(id: id)
            for category in restaurant.categories {
                for menuItem in category.items where menuItem.isConfigurable {
                    let stripped = menuItem.macros(
                        with: ItemConfiguration(removed: Set(menuItem.removableDefaults.map(\.menuItemId))),
                        in: restaurant
                    )
                    #expect(stripped.calories >= 0, "\(menuItem.id) strips negative")
                    #expect(stripped.proteinGrams >= 0, "\(menuItem.id) strips negative protein")
                }
            }
        }
    }

    // MARK: Chick-fil-A — treats and breakfast

    /// The salads carry their dressing now, so a name promising otherwise is a
    /// lie about an 830-calorie bowl. This broke once, when the totals were
    /// restored and the names weren't.
    @Test func noItemClaimsToBeDresslessWhileCarryingDressing() async throws {
        for restaurant in try await BundledMenuRepository().availableRestaurants() {
            for item in restaurant.categories.flatMap(\.items) {
                #expect(!item.name.lowercased().contains("no dressing"),
                        "\(item.id) is named as dressing-free")
            }
        }
    }

    /// Chick-fil-A lists a "6 pack Chocolate Chunk Cookie" but publishes it PER
    /// COOKIE — same 78 g serving, same 370 cal as a single. Shipping it as a
    /// "6 ct" size would read as six cookies for 370 calories. It stays out;
    /// six cookies is a quantity, not a size.
    @Test func theSixPackCookieIsNotShippedAsASize() async throws {
        let restaurant = try await cfa()
        let cookies = restaurant.categories
            .flatMap(\.items)
            .filter { $0.name.localizedCaseInsensitiveContains("chocolate chunk cookie") }
        #expect(cookies.count == 1, "only the single cookie should ship")
        #expect(cookies.first?.sizeGroup == nil)
        #expect(cookies.first?.macros.calories == 370)
    }

    /// Nothing on the Treats menu is meat, pork, honey or alcohol — and `[]`
    /// means "checked", not "not looked at", so this is a real claim to hold.
    @Test func treatsAreFreeOfEveryDietaryMarker() async throws {
        let restaurant = try await cfa()
        let treats = try #require(restaurant.category(id: "treats"))
        #expect(treats.items.count > 15, "the whole Treats menu should be there")
        for treat in treats.items {
            #expect(treat.dietaryMarkers == [], "\(treat.id) carries \(treat.dietaryMarkers ?? [])")
            #expect(treat.macros.calories > 0)
        }
    }

    /// Breakfast muffins follow the biscuits: bacon and sausage are pork.
    @Test(arguments: [
        ("chick-fil-a.breakfast.chicken-egg-cheese-muffin", 410.0, false),
        ("chick-fil-a.breakfast.bacon-egg-cheese-muffin", 300.0, true),
        ("chick-fil-a.breakfast.sausage-egg-cheese-muffin", 490.0, true),
    ])
    func breakfastMuffinsCarryTheirMeatFlags(id: String, calories: Double, isPork: Bool) async throws {
        let muffin = try item(try await cfa(), id)
        #expect(muffin.macros.calories == calories)
        #expect(muffin.dietaryMarkers?.contains(.meat) == true)
        #expect(muffin.dietaryMarkers?.contains(.pork) == isPork)
    }

    /// Menus that predate components must decode and behave exactly as before.
    @Test(arguments: ["chipotle", "panda-express"])
    func uncuratedMenusCarryNoComponentsAndStayAssembly(_ id: String) async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: id)
        #expect(restaurant.orderingModel == .assembly)
        for category in restaurant.categories {
            #expect(category.items.allSatisfy { !$0.isConfigurable })
        }
    }

    // MARK: Starbucks — source-derived recipes, standard nutrition

    @Test func starbucksIsARecipeRestaurantWithSizeSpecificDefaults() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "starbucks")
        #expect(restaurant.orderingModel == .recipe)
        let latte = try item(restaurant, "starbucks.hot-coffee.caffe-latte")
        let recipe = try #require(restaurant.drinkRecipe(for: latte))
        let defaults = recipe.defaults(for: "Grande")

        #expect(defaults.quantities["starbucks.recipe.choice.82.add"] == 2)
        #expect(
            defaults.selections["starbucks.recipe.group.milk-options"]
                == "starbucks.recipe.choice.63.add"
        )
    }

    @Test func starbucksCustomizationRecordsTheOrderWithoutInventingMacros() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "starbucks")
        let latte = try item(restaurant, "starbucks.hot-coffee.caffe-latte")
        let configuration = ItemConfiguration(
            recipeSelections: [
                "starbucks.recipe.group.milk-options": "starbucks.recipe.choice.61.add",
            ],
            recipeSelectionChanges: ["starbucks.recipe.group.milk-options"],
            recipeQuantities: ["starbucks.recipe.choice.82.add": 1]
        )

        #expect(latte.macros(with: configuration, in: restaurant) == latte.macros)
        let summary = try #require(latte.configurationSummary(configuration, in: restaurant))
        #expect(summary.contains("nonfat milk"))
        #expect(summary.contains("1 espresso shot"))
        #expect(summary.hasSuffix("standard recipe macros"))
    }

    @Test func everyStarbucksRecipeReferenceAndSizeDefaultResolves() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "starbucks")
        let recipeIds = Set(restaurant.drinkRecipes.map(\.id))
        #expect(recipeIds.count == restaurant.drinkRecipes.count)

        for item in restaurant.categories.flatMap(\.items) {
            guard let recipeId = item.recipeId else { continue }
            #expect(recipeIds.contains(recipeId), "\(item.id) references missing \(recipeId)")
            let recipe = try #require(restaurant.drinkRecipe(for: item))
            if let size = item.sizeLabel {
                #expect(recipe.defaultsBySize[size] != nil,
                        "\(item.id) has no official recipe defaults for \(size)")
            }
        }

        for recipe in restaurant.drinkRecipes {
            let groupIds = Set(recipe.groups.map(\.id))
            let choiceIds = Set(recipe.groups.flatMap(\.choices).map(\.id))
            #expect(groupIds.count == recipe.groups.count)
            #expect(choiceIds.count == recipe.groups.flatMap(\.choices).count)
            for defaults in recipe.defaultsBySize.values {
                #expect(Set(defaults.selections.keys).isSubset(of: groupIds))
                #expect(Set(defaults.selections.values).isSubset(of: choiceIds))
                #expect(Set(defaults.quantities.keys).isSubset(of: choiceIds))
                #expect(defaults.quantities.values.allSatisfy { $0 >= 0 && $0 <= 12 })
            }
        }
    }

    @Test func starbucksCatalogKeepsDistinctiveDrinksAndDropsGenericPackagedDrinks() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "starbucks")
        let names = Set(restaurant.categories.flatMap(\.items).map(\.name))
        #expect(names.contains { $0.contains("Energy Refresher") })
        #expect(names.contains { $0.contains("Protein Cream Shaken Espresso") })
        for excluded in ["Koia", "Horizon Organic", "Cold Milk", "Steamed Milk", "Blue Coconut"] {
            #expect(!names.contains { $0.localizedCaseInsensitiveContains(excluded) },
                    "generic or retired drink remains: \(excluded)")
        }
    }

    /// Estimates are allowed when they improve a common ordering flow, but none
    /// may lose the durable explanation behind the concise customer label.
    @Test func everyEstimateIsLabelledAndDocumented() async throws {
        let estimated = try await BundledMenuRepository().availableRestaurants()
            .flatMap(\.categories)
            .flatMap(\.items)
            .filter(\.isEstimated)
        #expect(estimated.contains { $0.id == "raising-canes.entrees.naked-bird" })
        #expect(estimated.allSatisfy { $0.notes?.isEmpty == false },
                "every estimate must retain its source, method and assumptions")

        let naked = try item(try await canes(), "raising-canes.entrees.naked-bird")
        // Protein is unchanged from a breaded finger; the breading is the delta.
        #expect(naked.macros.proteinGrams == 13)
        #expect(naked.macros.carbGrams == 0)
    }
}
