import Foundation
import Testing
@testable import Loadout

@MainActor
struct HalfPortionTests {
    private static let white = MenuItem(
        id: "test.rice.white", name: "White Rice", servingDescription: "4 oz",
        macros: Macros(calories: 210, proteinGrams: 4, carbGrams: 40, fatGrams: 4)
    )
    private static let brown = MenuItem(
        id: "test.rice.brown", name: "Brown Rice", servingDescription: "4 oz",
        macros: Macros(calories: 220, proteinGrams: 5, carbGrams: 38, fatGrams: 6)
    )
    private static let rice = MenuCategory(
        id: "rice", name: "Rice", selectionRule: .selectMany, items: [white, brown]
    )
    private static let restaurant = Restaurant(
        id: "test",
        name: "Test",
        categories: [rice],
        dataSource: DataSource(
            url: URL(string: "https://example.com")!,
            fetchedAt: "2026-07-02", fetchedBy: "test", notes: nil
        ),
        schemaVersion: 1
    )

    private func store() -> MealBuilderStore {
        MealBuilderStore(restaurant: Self.restaurant)
    }

    @Test func addAtHalfQuantityCreatesHalfLine() {
        let s = store()
        s.add(Self.white, in: Self.rice, quantity: 0.5)
        #expect(s.quantity(forMenuItemId: Self.white.id) == 0.5)
        #expect(s.totalMacros.calories == 105)
    }

    @Test func incrementRespectsQuantityParameter() {
        let s = store()
        s.add(Self.white, in: Self.rice, quantity: 0.5)
        let outcome = s.add(Self.white, in: Self.rice, quantity: 0.5)
        #expect(outcome == .incremented)
        #expect(s.quantity(forMenuItemId: Self.white.id) == 1.0)
    }

    @Test func totalQuantitySumsAcrossStation() {
        let s = store()
        s.add(Self.white, in: Self.rice, quantity: 0.5)
        s.add(Self.brown, in: Self.rice, quantity: 0.5)
        #expect(s.totalQuantity(in: Self.rice) == 1.0)
        // Half white + half brown: macros average out.
        #expect(s.totalMacros.calories == 215)
    }

    @Test func halveSnapsToQuarterGridWithFloor() {
        let s = store()
        s.add(Self.white, in: Self.rice) // 1
        let line = s.lineItems[0]
        s.halve(lineItemId: line.id)
        #expect(s.quantity(forMenuItemId: Self.white.id) == 0.5)
        s.halve(lineItemId: line.id)
        #expect(s.quantity(forMenuItemId: Self.white.id) == 0.25)
        s.halve(lineItemId: line.id) // floor: never strands a zero line
        #expect(s.quantity(forMenuItemId: Self.white.id) == 0.25)
    }

    @Test func defaultAddIsStillOneFullPortion() {
        let s = store()
        s.add(Self.white, in: Self.rice)
        #expect(s.quantity(forMenuItemId: Self.white.id) == 1)
    }
}
