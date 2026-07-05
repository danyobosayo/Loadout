import Foundation
import Testing
@testable import Loadout

/// Slice 2 — the rule-override + subset-scope + seed-through-rules paths
/// that guided formats drive. Fixtures mirror CAVA's shared `bases`
/// station (grains + greens under one id) since that's the case the
/// scoping exists for.
@MainActor
struct RuleSafeStoreTests {
    private static func item(_ id: String, _ name: String) -> MenuItem {
        MenuItem(id: id, name: name, servingDescription: "1 portion",
                 macros: Macros(calories: 200, proteinGrams: 5, carbGrams: 30, fatGrams: 6))
    }

    private static let brownRice = item("cava.bases.brown-rice", "Brown Rice")
    private static let basmati = item("cava.bases.saffron-basmati", "Saffron Basmati")
    private static let superGreens = item("cava.bases.super-greens", "Super Greens")
    private static let arugula = item("cava.bases.arugula", "Arugula")
    private static let chicken = item("cava.mains.grilled-chicken", "Grilled Chicken")
    private static let falafel = item("cava.mains.falafel", "Falafel")
    private static let tahini = item("cava.dressings.tahini", "Tahini")
    private static let lemon = item("cava.dressings.lemon", "Lemon")

    private static let grainIds: Set<String> = ["cava.bases.brown-rice", "cava.bases.saffron-basmati"]
    private static let greensIds: Set<String> = ["cava.bases.super-greens", "cava.bases.arugula"]

    private static let bases = MenuCategory(
        id: "bases", name: "Bases", selectionRule: .selectMany,
        items: [brownRice, basmati, superGreens, arugula])
    private static let mains = MenuCategory(
        id: "mains", name: "Mains", selectionRule: .selectMany, items: [chicken, falafel])
    private static let dressings = MenuCategory(
        id: "dressings", name: "Dressings", selectionRule: .selectUpTo(1), items: [tahini, lemon])

    private static let restaurant = Restaurant(
        id: "cava", name: "CAVA", categories: [bases, mains, dressings],
        dataSource: DataSource(url: URL(string: "https://example.com/")!,
                               fetchedAt: "2026-05-09", fetchedBy: "test", notes: nil),
        schemaVersion: 1)

    private func makeStore(formatName: String? = nil) -> MealBuilderStore {
        MealBuilderStore(restaurant: Self.restaurant, formatName: formatName)
    }

    // MARK: Subset-scoped selectOne (the Greens+Grains split)

    @Test func scopedSelectOneKeepsTheOtherHalf() {
        let store = makeStore()
        store.add(Self.brownRice, in: Self.bases, quantity: 0.5, ruleOverride: .selectOne, within: Self.grainIds)
        store.add(Self.superGreens, in: Self.bases, quantity: 0.5, ruleOverride: .selectOne, within: Self.greensIds)
        #expect(store.totalLineItemCount == 2) // grain half + greens half coexist

        // Swapping the grain replaces only the grain half.
        let outcome = store.add(Self.basmati, in: Self.bases, quantity: 0.5, ruleOverride: .selectOne, within: Self.grainIds)
        #expect(outcome == .replaced(removedMenuItemId: Self.brownRice.id))
        #expect(store.totalLineItemCount == 2)
        #expect(store.quantity(forMenuItemId: Self.brownRice.id) == 0)
        #expect(store.quantity(forMenuItemId: Self.basmati.id) == 0.5)
        #expect(store.quantity(forMenuItemId: Self.superGreens.id) == 0.5)
    }

    @Test func unscopedSelectOneClobbersTheWholeCategory() {
        // Contrast: without a scope, the second base evicts the first —
        // which is exactly why the split needs scoping.
        let store = makeStore()
        store.add(Self.brownRice, in: Self.bases, ruleOverride: .selectOne)
        store.add(Self.superGreens, in: Self.bases, ruleOverride: .selectOne)
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.superGreens.id) == 1)
    }

    // MARK: Rule override tighten / loosen

    @Test func ruleOverrideTightensSelectManyToSelectOne() {
        let store = makeStore()
        store.add(Self.chicken, in: Self.mains, ruleOverride: .selectOne)
        let outcome = store.add(Self.falafel, in: Self.mains, ruleOverride: .selectOne)
        #expect(outcome == .replaced(removedMenuItemId: Self.chicken.id))
        #expect(store.totalLineItemCount == 1)
    }

    @Test func ruleOverrideLoosensSelectUpToOne() {
        // dressings is selectUpTo(1); a Tacos-style loosen lets two through.
        let store = makeStore()
        #expect(store.add(Self.tahini, in: Self.dressings, ruleOverride: .selectMany) == .added)
        #expect(store.add(Self.lemon, in: Self.dressings, ruleOverride: .selectMany) == .added)
        #expect(store.totalLineItemCount == 2)
    }

    @Test func withoutOverrideCategoryRuleStillApplies() {
        let store = makeStore()
        store.add(Self.tahini, in: Self.dressings)
        let outcome = store.add(Self.lemon, in: Self.dressings) // selectUpTo(1) rejects
        #expect(outcome == .rejectedByLimit(max: 1))
        #expect(store.totalLineItemCount == 1)
    }

    // MARK: Scoped totals

    @Test func totalQuantityRespectsScope() {
        let store = makeStore()
        store.add(Self.brownRice, in: Self.bases, quantity: 0.5, ruleOverride: .selectOne, within: Self.grainIds)
        store.add(Self.superGreens, in: Self.bases, quantity: 0.5, ruleOverride: .selectOne, within: Self.greensIds)
        #expect(store.totalQuantity(in: Self.bases, scope: Self.grainIds) == 0.5)
        #expect(store.totalQuantity(in: Self.bases, scope: Self.greensIds) == 0.5)
        #expect(store.totalQuantity(in: Self.bases) == 1.0)
    }

    // MARK: seedThroughRules

    @Test func seedThroughRulesResolvesAgainstMenuAndSkipsUnknown() {
        let store = makeStore()
        store.seedThroughRules([
            SeedItem(menuItemId: "cava.bases.brown-rice", quantity: 1),
            SeedItem(menuItemId: "cava.mains.grilled-chicken", quantity: 1),
            SeedItem(menuItemId: "cava.bogus.does-not-exist", quantity: 1),
        ])
        #expect(store.totalLineItemCount == 2)
        #expect(store.quantity(forMenuItemId: Self.brownRice.id) == 1)
        #expect(store.quantity(forMenuItemId: Self.chicken.id) == 1)
    }

    @Test func seedThroughRulesAppliesMultiplier() {
        let store = makeStore()
        store.seedThroughRules([SeedItem(menuItemId: "cava.bases.brown-rice", quantity: 1)], multiplier: 2)
        #expect(store.quantity(forMenuItemId: Self.brownRice.id) == 2)
    }

    @Test func seedThroughRulesDedupsRepeatedIds() {
        let store = makeStore()
        store.seedThroughRules([
            SeedItem(menuItemId: "cava.bases.brown-rice", quantity: 1),
            SeedItem(menuItemId: "cava.bases.brown-rice", quantity: 1),
        ])
        #expect(store.totalLineItemCount == 1)
        #expect(store.quantity(forMenuItemId: Self.brownRice.id) == 2)
    }

    // MARK: formatName

    @Test func formatNameIsExposedForNaming() {
        #expect(makeStore(formatName: "Grain Bowl").formatName == "Grain Bowl")
        #expect(makeStore().formatName == nil)
    }
}
