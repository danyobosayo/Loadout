import Foundation
import Testing
@testable import Loadout

@MainActor
struct MealBuilderStoreTests {
    // MARK: Fixtures

    private static let chicken = MenuItem(
        id: "test.protein.chicken",
        name: "Chicken",
        servingDescription: "4 oz",
        macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
        allergens: nil,
        notes: nil
    )

    private static let steak = MenuItem(
        id: "test.protein.steak",
        name: "Steak",
        servingDescription: "4 oz",
        macros: Macros(calories: 150, proteinGrams: 21, carbGrams: 1, fatGrams: 6),
        allergens: nil,
        notes: nil
    )

    private static let whiteRice = MenuItem(
        id: "test.rice.white",
        name: "White Rice",
        servingDescription: "4 oz",
        macros: Macros(calories: 210, proteinGrams: 4, carbGrams: 40, fatGrams: 4),
        allergens: nil,
        notes: nil
    )

    private static let mildSalsa = MenuItem(
        id: "test.salsa.mild",
        name: "Mild Salsa",
        servingDescription: "2 oz",
        macros: Macros(calories: 25, proteinGrams: 1, carbGrams: 4, fatGrams: 0),
        allergens: nil,
        notes: nil
    )

    private static let medSalsa = MenuItem(
        id: "test.salsa.medium",
        name: "Medium Salsa",
        servingDescription: "2 oz",
        macros: Macros(calories: 15, proteinGrams: 0, carbGrams: 3, fatGrams: 0),
        allergens: nil,
        notes: nil
    )

    private static let hotSalsa = MenuItem(
        id: "test.salsa.hot",
        name: "Hot Salsa",
        servingDescription: "2 oz",
        macros: Macros(calories: 10, proteinGrams: 0, carbGrams: 2, fatGrams: 0),
        allergens: nil,
        notes: nil
    )

    private static let cheese = MenuItem(
        id: "test.toppings.cheese",
        name: "Cheese",
        servingDescription: "1 oz",
        macros: Macros(calories: 110, proteinGrams: 6, carbGrams: 1, fatGrams: 8),
        allergens: [.milk],
        notes: nil
    )

    private static let lettuce = MenuItem(
        id: "test.toppings.lettuce",
        name: "Lettuce",
        servingDescription: "1 oz",
        macros: Macros(calories: 5, proteinGrams: 0, carbGrams: 1, fatGrams: 0),
        allergens: nil,
        notes: nil
    )

    private static let proteinCategory = MenuCategory(
        id: "protein",
        name: "Protein",
        selectionRule: .selectOne,
        items: [chicken, steak]
    )

    private static let riceCategory = MenuCategory(
        id: "rice",
        name: "Rice",
        selectionRule: .selectOne,
        items: [whiteRice]
    )

    private static let salsaCategory = MenuCategory(
        id: "salsa",
        name: "Salsa",
        selectionRule: .selectUpTo(2),
        items: [mildSalsa, medSalsa, hotSalsa]
    )

    private static let toppingsCategory = MenuCategory(
        id: "toppings",
        name: "Toppings",
        selectionRule: .selectMany,
        items: [cheese, lettuce]
    )

    private static let restaurant = Restaurant(
        id: "test",
        name: "Test Spot",
        categories: [proteinCategory, riceCategory, salsaCategory, toppingsCategory],
        dataSource: DataSource(
            url: URL(string: "https://example.com/")!,
            fetchedAt: "2026-05-09",
            fetchedBy: "test",
            notes: nil
        ),
        schemaVersion: 1
    )

    private func makeStore() -> MealBuilderStore {
        MealBuilderStore(restaurant: Self.restaurant)
    }

    // MARK: Initial state

    @Test func newStoreIsEmpty() {
        let store = makeStore()
        #expect(store.isEmpty)
        #expect(store.totalMacros == .zero)
        #expect(store.totalLineItemCount == 0)
    }

    // MARK: selectMany

    @Test func selectManyAppendsDistinctItems() {
        let store = makeStore()
        #expect(store.add(Self.cheese, in: Self.toppingsCategory) == .added)
        #expect(store.add(Self.lettuce, in: Self.toppingsCategory) == .added)
        #expect(store.totalLineItemCount == 2)
    }

    // MARK: selectOne

    @Test func selectOneFirstAddJustAppends() {
        let store = makeStore()
        let outcome = store.add(Self.chicken, in: Self.proteinCategory)
        #expect(outcome == .added)
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 1)
    }

    @Test func selectOneSecondDistinctReplacesFirst() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        let outcome = store.add(Self.steak, in: Self.proteinCategory)
        #expect(outcome == .replaced(removedMenuItemId: Self.chicken.id))
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 0)
        #expect(store.quantity(forMenuItemId: Self.steak.id) == 1)
    }

    @Test func selectOneSameItemTappedAgainIncrementsQuantity() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        let outcome = store.add(Self.chicken, in: Self.proteinCategory)
        #expect(outcome == .incremented)
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 2)
    }

    // MARK: selectUpTo

    @Test func selectUpToAcceptsItemsBelowLimit() {
        let store = makeStore()
        #expect(store.add(Self.mildSalsa, in: Self.salsaCategory) == .added)
        #expect(store.add(Self.medSalsa, in: Self.salsaCategory) == .added)
    }

    @Test func selectUpToRejectsItemsAtLimit() {
        let store = makeStore()
        store.add(Self.mildSalsa, in: Self.salsaCategory)
        store.add(Self.medSalsa, in: Self.salsaCategory)
        let outcome = store.add(Self.hotSalsa, in: Self.salsaCategory)
        #expect(outcome == .rejectedByLimit(max: 2))
        #expect(store.totalLineItemCount == 2)
        #expect(store.quantity(forMenuItemId: Self.hotSalsa.id) == 0)
    }

    @Test func selectUpToStillIncrementsExistingItemEvenAtLimit() {
        let store = makeStore()
        store.add(Self.mildSalsa, in: Self.salsaCategory)
        store.add(Self.medSalsa, in: Self.salsaCategory)
        let outcome = store.add(Self.mildSalsa, in: Self.salsaCategory)
        #expect(outcome == .incremented)
        #expect(store.quantity(forMenuItemId: Self.mildSalsa.id) == 2)
        #expect(store.totalLineItemCount == 2)
    }

    // MARK: Quantity & remove

    @Test func setQuantityUpdatesLineItem() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        let id = store.lineItems[0].id
        store.setQuantity(lineItemId: id, to: 3)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 3)
    }

    @Test func setQuantityToZeroRemovesLineItem() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        let id = store.lineItems[0].id
        store.setQuantity(lineItemId: id, to: 0)
        #expect(store.isEmpty)
    }

    @Test func removeDropsLineItem() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        store.add(Self.cheese, in: Self.toppingsCategory)
        let chickenId = store.lineItems.first(where: { $0.menuItemId == Self.chicken.id })!.id
        store.remove(lineItemId: chickenId)
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 0)
        #expect(store.quantity(forMenuItemId: Self.cheese.id) == 1)
    }

    // MARK: Totals

    @Test func totalsScaleByQuantity() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        store.add(Self.chicken, in: Self.proteinCategory) // qty 2
        store.add(Self.whiteRice, in: Self.riceCategory)
        let total = store.totalMacros
        #expect(total.calories == Self.chicken.macros.calories * 2 + Self.whiteRice.macros.calories)
        #expect(total.proteinGrams == Self.chicken.macros.proteinGrams * 2 + Self.whiteRice.macros.proteinGrams)
    }

    // MARK: Clear

    @Test func clearEmptiesTheBuilder() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        store.add(Self.cheese, in: Self.toppingsCategory)
        store.clear()
        #expect(store.isEmpty)
        #expect(store.totalMacros == .zero)
    }

    // MARK: Save

    @Test func saveReturnsSnapshotAndClearsBuilder() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.proteinCategory)
        store.add(Self.whiteRice, in: Self.riceCategory)
        let expected = store.totalMacros

        let meal = store.save()

        #expect(meal.restaurantId == Self.restaurant.id)
        #expect(meal.lineItems.count == 2)
        #expect(meal.totalMacros == expected)
        #expect(store.isEmpty)
    }
}
