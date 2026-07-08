import Foundation
import Testing
@testable import Loadout

/// The tap-to-cycle state machines: splitBase (cycle + auto ½+½),
/// cappedScoops (capped increment), and freeAddOns (independent cycle).
/// Category ids are chosen so `portionPolicy` resolves to each behavior.
@MainActor
struct PortionPolicyTests {
    private static func item(_ id: String, _ name: String, cal: Double = 200) -> MenuItem {
        MenuItem(id: id, name: name, servingDescription: "1 portion",
                 macros: Macros(calories: cal, proteinGrams: 5, carbGrams: 30, fatGrams: 6))
    }

    // splitBase (id "mains")
    private static let chicken = item("r.mains.chicken", "Chicken")
    private static let lamb = item("r.mains.lamb", "Lamb")
    private static let falafel = item("r.mains.falafel", "Falafel")
    // cappedScoops max 2 (id "dressings")
    private static let tahini = item("r.dressings.tahini", "Tahini")
    private static let lemon = item("r.dressings.lemon", "Lemon")
    // freeAddOns (id "toppings")
    private static let olives = item("r.toppings.olives", "Olives")
    private static let feta = item("r.toppings.feta", "Feta")

    private static let mains = MenuCategory(id: "mains", name: "Mains", selectionRule: .selectMany, items: [chicken, lamb, falafel])
    private static let dressings = MenuCategory(id: "dressings", name: "Dressings", selectionRule: .selectMany, items: [tahini, lemon])
    private static let toppings = MenuCategory(id: "toppings", name: "Toppings", selectionRule: .selectMany, items: [olives, feta])

    private static let restaurant = Restaurant(
        id: "r", name: "R", categories: [mains, dressings, toppings],
        dataSource: DataSource(url: URL(string: "https://example.com/")!, fetchedAt: "2026-07-07", fetchedBy: "test", notes: nil),
        schemaVersion: 1)

    private func store() -> MealBuilderStore { MealBuilderStore(restaurant: Self.restaurant) }
    private func qty(_ s: MealBuilderStore, _ i: MenuItem) -> Double { s.quantity(forMenuItemId: i.id) }

    // MARK: policy assignment

    @Test func policyAssignment() {
        #expect(Self.mains.portionPolicy == .splitBase)
        #expect(Self.dressings.portionPolicy == .cappedScoops(max: 2))
        #expect(Self.toppings.portionPolicy == .freeAddOns)
        #expect(MenuCategory(id: "dips", name: "D", selectionRule: .selectMany, items: [Self.chicken]).portionPolicy == .cappedScoops(max: 3))
    }

    // MARK: splitBase

    @Test func splitBaseCyclesFullDoubleOff() {
        let s = store()
        s.applyPortionTap(Self.chicken, in: Self.mains)
        #expect(qty(s, Self.chicken) == 1)
        s.applyPortionTap(Self.chicken, in: Self.mains)
        #expect(qty(s, Self.chicken) == 2)          // ×2
        s.applyPortionTap(Self.chicken, in: Self.mains)
        #expect(qty(s, Self.chicken) == 0)          // off
        #expect(s.isEmpty)
    }

    @Test func splitBaseSecondPickSplitsHalfAndHalf() {
        let s = store()
        s.applyPortionTap(Self.chicken, in: Self.mains)     // chicken full
        s.applyPortionTap(Self.lamb, in: Self.mains)        // → ½ + ½
        #expect(qty(s, Self.chicken) == 0.5)
        #expect(qty(s, Self.lamb) == 0.5)
        #expect(s.totalLineItemCount == 2)
    }

    @Test func splitBaseTappingAHalfRestoresTheOther() {
        let s = store()
        s.applyPortionTap(Self.chicken, in: Self.mains)
        s.applyPortionTap(Self.lamb, in: Self.mains)        // ½ + ½
        s.applyPortionTap(Self.chicken, in: Self.mains)     // remove chicken half
        #expect(qty(s, Self.chicken) == 0)
        #expect(qty(s, Self.lamb) == 1)                     // lamb back to full
        #expect(s.totalLineItemCount == 1)
    }

    @Test func splitBaseRejectsAThirdWhenBaseIsFull() {
        let s = store()
        s.applyPortionTap(Self.chicken, in: Self.mains)
        s.applyPortionTap(Self.lamb, in: Self.mains)        // ½ + ½ (base full)
        let outcome = s.applyPortionTap(Self.falafel, in: Self.mains)
        #expect(outcome == .rejectedByLimit(max: 2))
        #expect(qty(s, Self.falafel) == 0)
        #expect(s.totalLineItemCount == 2)
    }

    // MARK: cappedScoops (max 2)

    @Test func scoopsIncrementToCapThenBlockNewItems() {
        let s = store()
        s.applyPortionTap(Self.tahini, in: Self.dressings)  // 1
        s.applyPortionTap(Self.tahini, in: Self.dressings)  // 2 (at cap)
        #expect(qty(s, Self.tahini) == 2)
        let outcome = s.applyPortionTap(Self.lemon, in: Self.dressings) // new @ cap
        #expect(outcome == .rejectedByLimit(max: 2))
        #expect(qty(s, Self.lemon) == 0)
    }

    @Test func scoopsRetappingAtCapZeroesTheItem() {
        let s = store()
        s.applyPortionTap(Self.tahini, in: Self.dressings)
        s.applyPortionTap(Self.lemon, in: Self.dressings)   // total 2 (at cap)
        s.applyPortionTap(Self.tahini, in: Self.dressings)  // at cap, chosen → 0
        #expect(qty(s, Self.tahini) == 0)
        #expect(qty(s, Self.lemon) == 1)
    }

    @Test func scoopsAllowUnevenSplitBelowCap() {
        let s = store()
        s.applyPortionTap(Self.tahini, in: Self.dressings)  // 1... but cap is 2
        // two of one is possible below/at cap
        s.applyPortionTap(Self.tahini, in: Self.dressings)  // 2
        #expect(qty(s, Self.tahini) == 2)
        #expect(s.totalQuantity(in: Self.dressings) == 2)
    }

    // MARK: freeAddOns

    @Test func freeAddOnsCycleIndependently() {
        let s = store()
        s.applyPortionTap(Self.olives, in: Self.toppings)   // 1
        s.applyPortionTap(Self.feta, in: Self.toppings)     // 1 (independent, no split)
        #expect(qty(s, Self.olives) == 1)
        #expect(qty(s, Self.feta) == 1)
        s.applyPortionTap(Self.olives, in: Self.toppings)   // olives ×2
        #expect(qty(s, Self.olives) == 2)
        #expect(qty(s, Self.feta) == 1)                     // feta unaffected
        s.applyPortionTap(Self.olives, in: Self.toppings)   // olives off
        #expect(qty(s, Self.olives) == 0)
        #expect(qty(s, Self.feta) == 1)
    }
}
