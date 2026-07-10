import Foundation
import Testing
@testable import Loadout

struct MealSolverTests {
    private let repo = BundledMenuRepository()
    private static let restaurants = ["chipotle", "cava", "panda-express", "subway", "sweetgreen"]

    /// A suggestion must respect every category's portion policy AND its real
    /// selectionRule (the stricter of the two).
    private func assertValid(_ s: MealSolver.Suggestion, in restaurant: Restaurant, budgetCalories: Double) {
        let calCap = min(budgetCalories, 1100)
        #expect(s.macros.calories <= calCap + 0.001, "over calorie cap in \(restaurant.id)")

        let byCategory = Dictionary(grouping: s.picks, by: \.categoryId)
        for (categoryId, picks) in byCategory {
            guard let category = restaurant.categories.first(where: { $0.id == categoryId }) else {
                Issue.record("pick references unknown category \(categoryId)"); continue
            }
            let distinct = picks.count
            let total = picks.reduce(0) { $0 + $1.quantity }

            // selectionRule distinct cap.
            switch category.selectionRule {
            case .selectOne: #expect(distinct <= 1, "\(categoryId) selectOne but \(distinct) distinct")
            case .selectUpTo(let n): #expect(distinct <= n, "\(categoryId) selectUpTo(\(n)) but \(distinct)")
            case .selectMany: break
            }
            // policy caps.
            switch category.portionPolicy {
            case .splitBase:
                #expect(distinct <= 1, "\(categoryId) splitBase but \(distinct) distinct")
                #expect(picks.allSatisfy { $0.quantity <= 2 }, "\(categoryId) splitBase qty > 2")
            case .cappedScoops(let max):
                #expect(total <= Double(max), "\(categoryId) scoops \(total) > cap \(max)")
            case .freeAddOns:
                #expect(distinct <= 3, "\(categoryId) freeAddOns \(distinct) distinct > 3")
                #expect(picks.allSatisfy { $0.quantity <= 2 }, "\(categoryId) freeAddOns qty > 2")
            }
        }
    }

    @Test(arguments: MealSolverTests.restaurants)
    func buildsAValidProteinMealForEveryRestaurant(_ id: String) async throws {
        let restaurant = try await repo.loadRestaurant(id: id)
        let budget = Macros(calories: 700, proteinGrams: 50, carbGrams: 60, fatGrams: 25)
        let s = try #require(MealSolver.solve(restaurant: restaurant, budget: budget),
                             "should build for a 700-kcal budget at \(id)")
        #expect(!s.picks.isEmpty)
        assertValid(s, in: restaurant, budgetCalories: 700)
        // Proves a real protein source was chosen — critical for Panda, whose
        // protein (entrees) is freeAddOns, not splitBase.
        #expect(s.macros.proteinGrams >= 15, "\(id) build only reached \(s.macros.proteinGrams)g protein")
    }

    @Test func fullDayBudgetIsCappedToASingleMeal() async throws {
        let restaurant = try await repo.loadRestaurant(id: "chipotle")
        let wholeDay = Macros(calories: 2000, proteinGrams: 160, carbGrams: 200, fatGrams: 62)
        let s = try #require(MealSolver.solve(restaurant: restaurant, budget: wholeDay))
        #expect(s.macros.calories <= 1100.001, "meal ceiling should cap a full-day budget")
        assertValid(s, in: restaurant, budgetCalories: 2000)
    }

    @Test func deterministic() async throws {
        let restaurant = try await repo.loadRestaurant(id: "sweetgreen")
        let budget = Macros(calories: 650, proteinGrams: 45, carbGrams: 55, fatGrams: 20)
        let a = try #require(MealSolver.solve(restaurant: restaurant, budget: budget))
        let b = try #require(MealSolver.solve(restaurant: restaurant, budget: budget))
        #expect(a.picks == b.picks)
        #expect(a.macros == b.macros)
    }

    @Test func gatesTinyAndOverBudget() async throws {
        let restaurant = try await repo.loadRestaurant(id: "cava")
        #expect(!MealSolver.canBuild(budget: Macros(calories: 100, proteinGrams: 10, carbGrams: 10, fatGrams: 3)))
        #expect(MealSolver.solve(restaurant: restaurant, budget: Macros(calories: 100, proteinGrams: 10, carbGrams: 10, fatGrams: 3)) == nil)
        // Over budget (already ate over the day) → signed-negative remaining.
        #expect(!MealSolver.canBuild(budget: Macros(calories: -200, proteinGrams: -10, carbGrams: -20, fatGrams: -5)))
        #expect(MealSolver.solve(restaurant: restaurant, budget: Macros(calories: -200, proteinGrams: -10, carbGrams: -20, fatGrams: -5)) == nil)
    }
}
