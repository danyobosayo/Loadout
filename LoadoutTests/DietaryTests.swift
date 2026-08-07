import Foundation
import Testing
@testable import Loadout

/// Restrictions are *derived* from what an item contains, never stored per item.
/// The property that matters most is the one about missing data: an unflagged
/// item must read as unknown, never as safe.
@MainActor
struct DietaryTests {
    private let repository = BundledMenuRepository()

    nonisolated static let restaurants = [
        "chipotle", "cava", "panda-express", "sweetgreen", "subway",
        "chick-fil-a", "starbucks", "panera", "qdoba", "moes",
        "jersey-mikes", "halal-guys", "mod-pizza", "raising-canes",
    ]

    // MARK: Derivation

    @Test func unflaggedItemsAreUnknownNotSafe() {
        let item = MenuItem(id: "x", name: "Mystery", servingDescription: "1", macros: .zero)
        #expect(item.hasDietaryData == false)
        for restriction in DietaryRestriction.allCases {
            #expect(item.verdict(for: restriction) == .unknown,
                    "\(restriction) must not clear an unflagged item")
        }
        #expect(item.verdict(for: [.vegan]) == .unknown)
    }

    /// Checked-and-clean is a different state from never-checked.
    @Test func anEmptyFlagListMeansVerifiedClean() {
        let rice = MenuItem(id: "x", name: "Rice", servingDescription: "1", macros: .zero,
                            allergens: [], dietaryMarkers: [])
        #expect(rice.hasDietaryData)
        for restriction in DietaryRestriction.allCases {
            #expect(rice.verdict(for: restriction) == .allowed)
        }
    }

    @Test func vegetarianAllowsFishButVeganDoesNot() {
        // Fish is deliberately not a `meat` marker — pescatarians need that.
        let salmon = MenuItem(id: "x", name: "Salmon", servingDescription: "1", macros: .zero,
                              allergens: [.fish], dietaryMarkers: [])
        #expect(salmon.verdict(for: .vegetarian) == .excluded)
        #expect(salmon.verdict(for: .vegan) == .excluded)

        let cheese = MenuItem(id: "y", name: "Feta", servingDescription: "1", macros: .zero,
                              allergens: [.milk], dietaryMarkers: [])
        #expect(cheese.verdict(for: .vegetarian) == .allowed)
        #expect(cheese.verdict(for: .vegan) == .excluded)
        #expect(cheese.verdict(for: .dairyFree) == .excluded)
    }

    @Test func honeyBlocksVeganOnly() {
        let honey = MenuItem(id: "x", name: "Hot Honey", servingDescription: "1", macros: .zero,
                             allergens: [], dietaryMarkers: [.honey])
        #expect(honey.verdict(for: .vegan) == .excluded)
        #expect(honey.verdict(for: .vegetarian) == .allowed)
    }

    @Test func porkIsSeparableFromMeat() {
        let bacon = MenuItem(id: "x", name: "Bacon", servingDescription: "1", macros: .zero,
                             allergens: [], dietaryMarkers: [.meat, .pork])
        let chicken = MenuItem(id: "y", name: "Chicken", servingDescription: "1", macros: .zero,
                               allergens: [], dietaryMarkers: [.meat])
        #expect(bacon.verdict(for: .porkFree) == .excluded)
        #expect(chicken.verdict(for: .porkFree) == .allowed)
        #expect(chicken.verdict(for: .vegetarian) == .excluded)
    }

    @Test func combinedRestrictionsExcludeIfAnyOneRejects() {
        let cheese = MenuItem(id: "x", name: "Feta", servingDescription: "1", macros: .zero,
                              allergens: [.milk], dietaryMarkers: [])
        #expect(cheese.verdict(for: [.vegetarian]) == .allowed)
        #expect(cheese.verdict(for: [.vegetarian, .dairyFree]) == .excluded)
        #expect(cheese.verdict(for: []) == .allowed)      // no restrictions → everything passes
    }

    // MARK: Shipped data

    @Test(arguments: restaurants)
    func everyItemIsFlagged(_ id: String) async throws {
        let restaurant = try await repository.loadRestaurant(id: id)
        let unflagged = restaurant.categories
            .flatMap(\.items)
            .filter { !$0.hasDietaryData }
        // One item is deliberately unknown: Sweetgreen's pesto vinaigrette,
        // where the researched flags and the keyword audit disagreed and no
        // official allergen chart settled it. Failing safe is the point.
        #expect(unflagged.count <= 1,
                "\(id) has \(unflagged.count) unflagged items: \(unflagged.map(\.name).prefix(5))")
    }

    /// Pork must always carry `meat` too, or "vegetarian" would clear bacon.
    @Test(arguments: restaurants)
    func porkAlwaysImpliesMeat(_ id: String) async throws {
        let restaurant = try await repository.loadRestaurant(id: id)
        for item in restaurant.categories.flatMap(\.items) {
            guard let markers = item.dietaryMarkers, markers.contains(.pork) else { continue }
            #expect(markers.contains(.meat), "\(item.id) is pork but not meat")
        }
    }

    // MARK: Auto-build honours restrictions

    /// The whole point of flagging: auto-build must never hand you something
    /// your restriction rules out. Unknown items are excluded too — nobody is
    /// reading a label on your behalf here.
    @Test(arguments: [
        DietaryRestriction.vegetarian, .vegan, .porkFree, .glutenFree, .dairyFree,
    ])
    func autoBuildNeverSuggestsARestrictedItem(_ restriction: DietaryRestriction) async throws {
        let budget = Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60)
        for id in Self.restaurants {
            let restaurant = try await repository.loadRestaurant(id: id)
            let prefs = AutoBuildPreferences(focus: .balanced, restrictions: [restriction])
            guard let suggestion = MealSolver.solve(
                restaurant: restaurant, budget: budget, preferences: prefs
            ) else { continue }   // no compliant meal is a valid outcome
            for pick in suggestion.picks {
                #expect(
                    pick.item.verdict(for: restriction) == .allowed,
                    "\(id)/\(restriction.rawValue) suggested \(pick.item.name)"
                )
            }
        }
    }

    /// Restrictions stack with each other and with the station exclusions.
    @Test func restrictionsStackWithSauceExclusion() async throws {
        let restaurant = try await repository.loadRestaurant(id: "sweetgreen")
        let budget = Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60)
        let prefs = AutoBuildPreferences(
            focus: .protein, exclusions: [.sauces], restrictions: [.vegan, .glutenFree]
        )
        let suggestion = try #require(MealSolver.solve(restaurant: restaurant, budget: budget, preferences: prefs))
        for pick in suggestion.picks {
            #expect(!AutoBuildExclusion.sauces.excludedCategoryIds.contains(pick.categoryId))
            #expect(pick.item.verdict(for: .vegan) == .allowed, "\(pick.item.name) isn't vegan")
            #expect(pick.item.verdict(for: .glutenFree) == .allowed, "\(pick.item.name) has gluten")
        }
    }

    /// Vegan at a chicken-finger shop has no valid answer, and returning
    /// nothing beats returning something wrong.
    @Test func impossibleRestrictionsYieldNoSuggestionRatherThanABadOne() async throws {
        let restaurant = try await repository.loadRestaurant(id: "raising-canes")
        let budget = Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60)
        let prefs = AutoBuildPreferences(restrictions: [.vegan])
        let suggestion = MealSolver.solve(restaurant: restaurant, budget: budget, preferences: prefs)
        if let suggestion {
            for pick in suggestion.picks {
                #expect(pick.item.verdict(for: .vegan) == .allowed, "\(pick.item.name) isn't vegan")
            }
        }
    }

    /// A spot-check that the shipped data actually says what it should — if a
    /// menu refresh wipes the flags, these fail rather than silently clearing
    /// every restriction.
    @Test func knownItemsCarryTheirExpectedFlags() async throws {
        let chipotle = try await repository.loadRestaurant(id: "chipotle")
        let carnitas = try #require(chipotle.resolve(menuItemId: "chipotle.protein.carnitas")?.item)
        #expect(carnitas.verdict(for: .porkFree) == .excluded)
        #expect(carnitas.verdict(for: .vegetarian) == .excluded)

        let cheese = try #require(chipotle.resolve(menuItemId: "chipotle.toppings.cheese")?.item)
        #expect(cheese.verdict(for: .dairyFree) == .excluded)
        #expect(cheese.verdict(for: .vegetarian) == .allowed)

        let rice = try #require(chipotle.resolve(menuItemId: "chipotle.rice.cilantro-lime-white")?.item)
        #expect(rice.verdict(for: .vegan) == .allowed)
        #expect(rice.verdict(for: .glutenFree) == .allowed)

        let tortilla = try #require(chipotle.resolve(menuItemId: "chipotle.tortilla.flour-burrito")?.item)
        #expect(tortilla.verdict(for: .glutenFree) == .excluded)
    }
}
