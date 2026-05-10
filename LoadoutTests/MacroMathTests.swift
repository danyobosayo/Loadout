import Foundation
import Testing
@testable import Loadout

struct MacroMathTests {
    @Test func zeroIsAdditiveIdentity() {
        let m = Macros(calories: 320, proteinGrams: 28, carbGrams: 40, fatGrams: 9)
        #expect(m + .zero == m)
        #expect(.zero + m == m)
    }

    @Test func additionIsCommutative() {
        let a = Macros(calories: 100, proteinGrams: 5, carbGrams: 12, fatGrams: 3)
        let b = Macros(calories: 50, proteinGrams: 10, carbGrams: 4, fatGrams: 1)
        #expect(a + b == b + a)
    }

    @Test func additionSumsEachComponent() {
        let a = Macros(calories: 100, proteinGrams: 5, carbGrams: 12, fatGrams: 3)
        let b = Macros(calories: 50, proteinGrams: 10, carbGrams: 4, fatGrams: 1)
        let sum = a + b
        #expect(sum.calories == 150)
        #expect(sum.proteinGrams == 15)
        #expect(sum.carbGrams == 16)
        #expect(sum.fatGrams == 4)
    }

    @Test func scalarMultiplyScalesEachComponent() {
        let chicken = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7)
        let double = chicken * 2
        #expect(double.calories == 360)
        #expect(double.proteinGrams == 64)
        #expect(double.carbGrams == 0)
        #expect(double.fatGrams == 14)
    }

    @Test func scalarMultiplyByZeroProducesZero() {
        let chicken = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7)
        #expect(chicken * 0 == .zero)
    }

    @Test func scalarMultiplyByFractionalQuantity() {
        let m = Macros(calories: 200, proteinGrams: 10, carbGrams: 24, fatGrams: 8)
        let half = m * 0.5
        #expect(half.calories == 100)
        #expect(half.proteinGrams == 5)
        #expect(half.carbGrams == 12)
        #expect(half.fatGrams == 4)
    }

    @Test func builtMealTotalScalesByLineItemQuantity() {
        let chicken = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7)
        let rice = Macros(calories: 210, proteinGrams: 4, carbGrams: 40, fatGrams: 4)
        let meal = BuiltMeal(
            id: UUID(),
            restaurantId: "chipotle",
            name: "Test Bowl",
            lineItems: [
                LineItem(
                    id: UUID(),
                    menuItemId: "chipotle.protein.chicken",
                    displayName: "Chicken",
                    servingDescription: "4 oz",
                    macros: chicken,
                    quantity: 2
                ),
                LineItem(
                    id: UUID(),
                    menuItemId: "chipotle.rice.cilantro-lime-white",
                    displayName: "Cilantro-Lime White Rice",
                    servingDescription: "4 oz",
                    macros: rice,
                    quantity: 1
                )
            ],
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let total = meal.totalMacros
        #expect(total.calories == 180 * 2 + 210)
        #expect(total.proteinGrams == 32 * 2 + 4)
        #expect(total.carbGrams == 0 + 40)
        #expect(total.fatGrams == 7 * 2 + 4)
    }

    @Test func emptyMealTotalsToZero() {
        let meal = BuiltMeal(
            id: UUID(),
            restaurantId: "chipotle",
            name: nil,
            lineItems: [],
            createdAt: Date(timeIntervalSince1970: 0)
        )
        #expect(meal.totalMacros == .zero)
    }
}
