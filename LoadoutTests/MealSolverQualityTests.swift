import Foundation
import Testing
@testable import Loadout

/// The existing solver tests check that a suggestion is *valid* — rules obeyed,
/// under the cap, non-empty. Every one of them passed while the solver was
/// returning bacon and three breads, so validity clearly isn't the bar.
///
/// These check that a suggestion is *good*: it has a base, it doesn't pad
/// itself out with filler when the day is wide open, and each focus actually
/// moves the meal in its own direction.
@MainActor
struct MealSolverQualityTests {
    private let repository = BundledMenuRepository()

    /// A whole day untouched — the "first meal of the day" case, where every
    /// macro is in excess and the meal ceiling, not the budget, is the limit.
    private let wholeDay = Macros(calories: 2200, proteinGrams: 180, carbGrams: 200, fatGrams: 60)
    /// Little left — here spending the remaining budget *is* the right answer.
    private let nearlySpent = Macros(calories: 600, proteinGrams: 50, carbGrams: 50, fatGrams: 20)

    nonisolated static let restaurants = [
        "chipotle", "cava", "sweetgreen", "subway", "panda-express",
        "qdoba", "moes", "jersey-mikes", "chick-fil-a",
    ]

    private func solve(
        _ id: String, _ budget: Macros, _ focus: AutoBuildFocus = .balanced,
        exclusions: Set<AutoBuildExclusion> = []
    ) async throws -> (Restaurant, MealSolver.Suggestion) {
        let restaurant = try await repository.loadRestaurant(id: id)
        let suggestion = try #require(
            MealSolver.solve(
                restaurant: restaurant,
                budget: budget,
                preferences: AutoBuildPreferences(focus: focus, exclusions: exclusions)
            ),
            "\(id) produced no suggestion"
        )
        return (restaurant, suggestion)
    }

    private static let baseCategories: Set<String> = ["bases", "rice", "crusts", "breads"]

    /// A meal has to sit on something. Chipotle used to come back as beans,
    /// meat and a tortilla with no rice at all.
    ///
    /// "Something" is a base station OR a whole dish — picking a named Subway sub
    /// satisfies this exactly as picking a bread and building on it would, and
    /// the solver is right to prefer it. What must never come back is a pile of
    /// fillings with no foundation at all.
    @Test(arguments: restaurants)
    func suggestionSitsOnABaseOrAWholeDish(_ id: String) async throws {
        let (restaurant, suggestion) = try await solve(id, wholeDay)
        let menuHasBase = restaurant.categories.contains { Self.baseCategories.contains($0.id) }
        guard menuHasBase else { return }        // Cane's, Halal Guys-style menus

        let completeMealCategories = Set(
            restaurant.categories.filter(\.isCompleteMeal).map(\.id)
        )
        let foundation = suggestion.picks.contains {
            Self.baseCategories.contains($0.categoryId) || completeMealCategories.contains($0.categoryId)
        }
        #expect(foundation, "\(id) built a meal with no base: \(suggestion.picks.map(\.item.name))")
    }

    /// The base should read first, the way the counter is laid out — that's how
    /// you can tell at a glance what the meal is built on.
    @Test func theBaseComesFirstInTheSuggestion() async throws {
        let (_, suggestion) = try await solve("chipotle", wholeDay)
        let firstBase = try #require(
            suggestion.picks.firstIndex { Self.baseCategories.contains($0.categoryId) }
        )
        let protein = suggestion.picks.firstIndex { $0.categoryId == "protein" }
        if let protein { #expect(firstBase < protein, "the base should precede the protein") }
    }

    /// Auto-build must never put a drink in the tray.
    ///
    /// The moment drinks were curated, the solver started closing carb gaps with
    /// a large lemonade — CAVA's is 360 cal — because a drink is just cheap carbs
    /// to an optimiser. What you drink is a decision the person makes; the solver
    /// fits the food around it.
    @Test(arguments: restaurants)
    func neverSuggestsADrink(_ id: String) async throws {
        let (restaurant, suggestion) = try await solve(id, wholeDay)
        guard restaurant.category(id: "drinks") != nil else { return }
        #expect(
            !suggestion.picks.contains { $0.categoryId == "drinks" },
            "\(id) auto-build put a drink in the tray"
        )
    }

    /// With the whole day open, the solver must not spend the entire meal
    /// ceiling just because it's available. This is the bug that produced a
    /// 1100-kcal meal of bacon and bread.
    @Test(arguments: restaurants)
    func doesNotSpendTheWholeCeilingWhenTheDayIsOpen(_ id: String) async throws {
        let (_, suggestion) = try await solve(id, wholeDay)
        #expect(
            suggestion.macros.calories <= 1050,
            "\(id) padded out to \(Int(suggestion.macros.calories)) kcal on an open budget"
        )
    }

    /// The whole point of the request: an open budget should buy protein, not
    /// calories. Measured as protein density so it holds across menus.
    @Test(arguments: ["chipotle", "cava", "sweetgreen", "qdoba", "moes"])
    func openBudgetsBuyProteinNotCalories(_ id: String) async throws {
        let (_, suggestion) = try await solve(id, wholeDay, .protein)
        let density = suggestion.macros.proteinGrams / max(suggestion.macros.calories, 1) * 100
        // A floor for "did the focus actually do anything", not a nutrition
        // target. Menus differ: Chipotle reaches 9.6 and Sweetgreen 14, while
        // Qdoba's rice-and-bean-heavy menu tops out around 7.4.
        #expect(density >= 7.0, "\(id) only reached \(String(format: "%.1f", density))g protein per 100 kcal")
    }

    /// High-protein focus must be *lean* protein, not merely calorie-cheap
    /// protein — otherwise it just finds cured meat and hard cheese.
    ///
    /// Measured as absolute fat and protein-per-calorie, deliberately not as
    /// fat's *share* of calories: a protein-focused meal is low-carb, so its
    /// fat share reads high even while it carries fewer grams of fat than the
    /// bigger, carb-padded fat-focused meal.
    @Test(arguments: ["chipotle", "cava", "sweetgreen"])
    func proteinFocusIsLeanerThanFatFocus(_ id: String) async throws {
        let (_, lean) = try await solve(id, wholeDay, .protein)
        let (_, fatty) = try await solve(id, wholeDay, .fat)
        #expect(lean.macros.fatGrams <= fatty.macros.fatGrams + 0.001,
                "\(id): protein focus carried more fat (\(lean.macros.fatGrams)g) than fat focus (\(fatty.macros.fatGrams)g)")

        func density(_ s: MealSolver.Suggestion) -> Double {
            s.macros.proteinGrams / max(s.macros.calories, 1)
        }
        #expect(density(lean) >= density(fatty) - 0.0001,
                "\(id): protein focus wasn't more protein-dense than fat focus")
    }

    @Test(arguments: ["chipotle", "qdoba", "moes", "sweetgreen"])
    func carbFocusBuysMoreCarbsThanProteinFocus(_ id: String) async throws {
        let (_, carby) = try await solve(id, wholeDay, .carbs)
        let (_, lean) = try await solve(id, wholeDay, .protein)
        #expect(carby.macros.carbGrams > lean.macros.carbGrams,
                "\(id): carb focus didn't produce more carbs than protein focus")
    }

    @Test(arguments: ["chipotle", "cava", "qdoba"])
    func vegetableFocusPutsMoreVegetablesOnThePlate(_ id: String) async throws {
        let vegetable: Set<String> = ["veggies", "toppings", "ingredients", "salsa"]
        let (_, veg) = try await solve(id, wholeDay, .vegetables)
        let (_, plain) = try await solve(id, wholeDay, .protein)
        func servings(_ s: MealSolver.Suggestion) -> Double {
            s.picks.filter { vegetable.contains($0.categoryId) }.reduce(0) { $0 + $1.quantity }
        }
        #expect(servings(veg) > servings(plain), "\(id): veg focus added no extra vegetables")
    }

    /// Exclusions stack onto any focus and are absolute — this is the mechanism
    /// dietary restrictions will reuse, so it has to be a hard filter, not a
    /// scoring nudge.
    @Test(arguments: restaurants)
    func sauceExclusionIsAbsolute(_ id: String) async throws {
        for focus in AutoBuildFocus.allCases {
            let (_, suggestion) = try await solve(id, wholeDay, focus, exclusions: [.sauces])
            let banned = AutoBuildExclusion.sauces.excludedCategoryIds
            #expect(
                !suggestion.picks.contains { banned.contains($0.categoryId) },
                "\(id)/\(focus.rawValue) included a sauce despite the exclusion"
            )
        }
    }

    /// When the remaining budget really is the constraint, using it up is
    /// correct — the leanness preference must not starve a late-day meal.
    @Test(arguments: ["chipotle", "cava", "sweetgreen"])
    func aNearlySpentBudgetStillGetsAFullMeal(_ id: String) async throws {
        let (_, suggestion) = try await solve(id, nearlySpent)
        #expect(suggestion.macros.calories >= nearlySpent.calories * 0.75,
                "\(id) under-filled a tight budget: \(Int(suggestion.macros.calories)) of \(Int(nearlySpent.calories))")
        #expect(suggestion.macros.calories <= nearlySpent.calories)
    }

    /// Preferences must not break determinism — same inputs, same meal.
    @Test func stillDeterministicUnderEveryFocus() async throws {
        let restaurant = try await repository.loadRestaurant(id: "chipotle")
        for focus in AutoBuildFocus.allCases {
            let prefs = AutoBuildPreferences(focus: focus, exclusions: [.sauces])
            let a = MealSolver.solve(restaurant: restaurant, budget: wholeDay, preferences: prefs)
            let b = MealSolver.solve(restaurant: restaurant, budget: wholeDay, preferences: prefs)
            #expect(a?.picks.map(\.item.id) == b?.picks.map(\.item.id), "\(focus.rawValue) wasn't deterministic")
        }
    }
}
