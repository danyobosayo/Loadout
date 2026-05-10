import Foundation
import Testing
@testable import Loadout

struct ModelCodableTests {
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    private let decoder = JSONDecoder()

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try encoder.encode(value)
        return try decoder.decode(T.self, from: data)
    }

    @Test func macros() throws {
        let m = Macros(calories: 320, proteinGrams: 28, carbGrams: 40, fatGrams: 9)
        #expect(try roundTrip(m) == m)
    }

    @Test func dataSource() throws {
        let ds = DataSource(
            url: URL(string: "https://www.chipotle.com/nutrition-calculator")!,
            fetchedAt: "2026-05-09",
            fetchedBy: "manual",
            notes: "White rice = 1 serving (4 oz)."
        )
        #expect(try roundTrip(ds) == ds)
    }

    @Test func selectionRuleAllCases() throws {
        for rule in [SelectionRule.selectOne, .selectMany, .selectUpTo(3)] {
            #expect(try roundTrip(rule) == rule)
        }
    }

    @Test func selectionRuleEncodesUniformShape() throws {
        let one = try encoder.encode(SelectionRule.selectOne)
        let many = try encoder.encode(SelectionRule.selectMany)
        let upTo = try encoder.encode(SelectionRule.selectUpTo(3))
        #expect(String(data: one, encoding: .utf8) == #"{"kind":"selectOne"}"#)
        #expect(String(data: many, encoding: .utf8) == #"{"kind":"selectMany"}"#)
        #expect(String(data: upTo, encoding: .utf8) == #"{"kind":"selectUpTo","max":3}"#)
    }

    @Test func allergens() throws {
        for a in Allergen.allCases {
            #expect(try roundTrip(a) == a)
        }
    }

    @Test func menuItem() throws {
        let item = MenuItem(
            id: "chipotle.protein.chicken",
            name: "Chicken",
            servingDescription: "4 oz",
            macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
            allergens: nil,
            notes: nil
        )
        #expect(try roundTrip(item) == item)
    }

    @Test func menuItemWithAllergensAndNotes() throws {
        let item = MenuItem(
            id: "chipotle.toppings.cheese",
            name: "Cheese",
            servingDescription: "1 oz",
            macros: Macros(calories: 110, proteinGrams: 6, carbGrams: 1, fatGrams: 8),
            allergens: [.milk],
            notes: "Contains dairy"
        )
        #expect(try roundTrip(item) == item)
    }

    @Test func menuCategory() throws {
        let cat = MenuCategory(
            id: "protein",
            name: "Protein",
            selectionRule: .selectOne,
            items: [
                MenuItem(
                    id: "chipotle.protein.chicken",
                    name: "Chicken",
                    servingDescription: "4 oz",
                    macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
                    allergens: nil,
                    notes: nil
                )
            ]
        )
        #expect(try roundTrip(cat) == cat)
    }

    @Test func restaurant() throws {
        let r = Restaurant(
            id: "chipotle",
            name: "Chipotle",
            categories: [
                MenuCategory(
                    id: "protein",
                    name: "Protein",
                    selectionRule: .selectOne,
                    items: [
                        MenuItem(
                            id: "chipotle.protein.chicken",
                            name: "Chicken",
                            servingDescription: "4 oz",
                            macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
                            allergens: nil,
                            notes: "Limited time"
                        )
                    ]
                )
            ],
            dataSource: DataSource(
                url: URL(string: "https://www.chipotle.com/nutrition-calculator")!,
                fetchedAt: "2026-05-09",
                fetchedBy: "manual",
                notes: nil
            ),
            schemaVersion: 1
        )
        #expect(try roundTrip(r) == r)
    }

    @Test func builtMeal() throws {
        let meal = BuiltMeal(
            id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!,
            restaurantId: "chipotle",
            name: "Usual Bowl",
            lineItems: [
                LineItem(
                    id: UUID(uuidString: "12345678-1234-1234-1234-123456781234")!,
                    menuItemId: "chipotle.protein.chicken",
                    displayName: "Chicken",
                    servingDescription: "4 oz",
                    macros: Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
                    quantity: 2
                )
            ],
            createdAt: Date(timeIntervalSinceReferenceDate: 0)
        )
        let restored = try roundTrip(meal)
        #expect(restored == meal)
        #expect(restored.totalMacros == meal.totalMacros)
    }
}
