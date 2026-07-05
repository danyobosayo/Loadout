import Foundation
import Observation

@MainActor
@Observable
final class MealBuilderStore {
    let restaurant: Restaurant
    private(set) var lineItems: [LineItem] = []
    /// The order format this build started from, if any ("Burrito",
    /// "Grain Bowl"). Nil for build-your-own and reopened meals. Drives
    /// the default recipe/export name; does not affect building.
    let formatName: String?

    init(restaurant: Restaurant, lineItems: [LineItem] = [], formatName: String? = nil) {
        self.restaurant = restaurant
        self.lineItems = lineItems
        self.formatName = formatName
    }

    enum AddOutcome: Equatable {
        case added
        case incremented
        case replaced(removedMenuItemId: String)
        case rejectedByLimit(max: Int)
    }

    var totalMacros: Macros {
        lineItems.reduce(.zero) { $0 + $1.macros * $1.quantity }
    }

    var isEmpty: Bool { lineItems.isEmpty }

    var totalLineItemCount: Int { lineItems.count }

    func quantity(forMenuItemId itemId: String) -> Double {
        lineItems.first(where: { $0.menuItemId == itemId })?.quantity ?? 0
    }

    /// - Parameters:
    ///   - ruleOverride: when set, governs this add instead of the
    ///     category's own `selectionRule`. Guided formats use it to tighten
    ///     (a `selectMany` station prompted as "choose 1") or loosen
    ///     (Chipotle tacos want 3 shells from a `selectUpTo(1)` station).
    ///   - scope: restricts the replace/limit bookkeeping to these item ids.
    ///     A category prompted twice under one id (CAVA Greens+Grains splits
    ///     `bases` into a grain half and a greens half) scopes each pick so
    ///     one half's `selectOne` doesn't evict the other.
    @discardableResult
    func add(
        _ item: MenuItem,
        in category: MenuCategory,
        quantity: Double = 1,
        ruleOverride: SelectionRule? = nil,
        within scope: Set<String>? = nil
    ) -> AddOutcome {
        // Re-tapping an already-added item bumps quantity regardless of
        // selectionRule. Quantity is "more of the same thing"; selectionRule
        // governs how many *distinct* items are allowed in a category.
        if let idx = lineItems.firstIndex(where: { $0.menuItemId == item.id }) {
            lineItems[idx] = lineItems[idx].withQuantity(lineItems[idx].quantity + quantity)
            return .incremented
        }

        switch ruleOverride ?? category.selectionRule {
        case .selectOne:
            if let existing = firstLineItem(in: category, scope: scope) {
                lineItems.removeAll { $0.id == existing.id }
                lineItems.append(.snapshot(of: item, in: category, quantity: quantity))
                return .replaced(removedMenuItemId: existing.menuItemId)
            }
            lineItems.append(.snapshot(of: item, in: category, quantity: quantity))
            return .added

        case .selectMany:
            lineItems.append(.snapshot(of: item, in: category, quantity: quantity))
            return .added

        case .selectUpTo(let max):
            if lineItems(in: category, scope: scope).count >= max {
                return .rejectedByLimit(max: max)
            }
            lineItems.append(.snapshot(of: item, in: category, quantity: quantity))
            return .added
        }
    }

    /// Seeds curated format items (`autoAdd`) by resolving each id against
    /// `restaurant` and routing through `add` — so dedup and selection
    /// rules still hold, unlike the raw `init(lineItems:)` seed path.
    /// `multiplier` scales for size formats (Subway Footlong = 2×). Ids
    /// that don't resolve are skipped; `FormatIntegrityTests` guarantees
    /// the shipped data has none.
    func seedThroughRules(_ seeds: [SeedItem], multiplier: Double = 1) {
        for seed in seeds {
            guard let (item, category) = restaurant.resolve(menuItemId: seed.menuItemId) else { continue }
            add(item, in: category, quantity: seed.quantity * multiplier)
        }
    }

    /// Sum of quantities currently held in `category` (optionally scoped
    /// to a subset of item ids). Drives the half-and-half flow: a station
    /// summing to x.5 means a split is open, and the next distinct item
    /// added should complete it at ½.
    func totalQuantity(in category: MenuCategory, scope: Set<String>? = nil) -> Double {
        lineItems(in: category, scope: scope).reduce(0) { $0 + $1.quantity }
    }

    /// Halves an existing line's portion (half white rice, half brown
    /// rice — or just "light rice"). Snaps to the 0.25 grid with a
    /// floor of 0.25 so repeated taps can't strand a zero-quantity line.
    func halve(lineItemId: UUID) {
        guard let item = lineItems.first(where: { $0.id == lineItemId }) else { return }
        let halved = max((item.quantity / 2 * 4).rounded() / 4, 0.25)
        setQuantity(lineItemId: lineItemId, to: halved)
    }

    func remove(lineItemId: UUID) {
        lineItems.removeAll { $0.id == lineItemId }
    }

    func setQuantity(lineItemId: UUID, to value: Double) {
        guard let idx = lineItems.firstIndex(where: { $0.id == lineItemId }) else { return }
        if value <= 0 {
            lineItems.remove(at: idx)
        } else {
            lineItems[idx] = lineItems[idx].withQuantity(value)
        }
    }

    func clear() {
        lineItems.removeAll()
    }

    /// Snapshot of the tray as a `BuiltMeal` WITHOUT clearing.
    /// Logging must never destroy the work — clearing is an explicit,
    /// separate act.
    func snapshotMeal(named name: String? = nil) -> BuiltMeal {
        BuiltMeal(
            id: UUID(),
            restaurantId: restaurant.id,
            name: name,
            lineItems: lineItems,
            createdAt: .now
        )
    }

    func save() -> BuiltMeal {
        let meal = BuiltMeal(
            id: UUID(),
            restaurantId: restaurant.id,
            name: nil,
            lineItems: lineItems,
            createdAt: .now
        )
        clear()
        return meal
    }

    private func lineItems(in category: MenuCategory, scope: Set<String>? = nil) -> [LineItem] {
        var ids = Set(category.items.map(\.id))
        if let scope { ids.formIntersection(scope) }
        return lineItems.filter { ids.contains($0.menuItemId) }
    }

    private func firstLineItem(in category: MenuCategory, scope: Set<String>? = nil) -> LineItem? {
        lineItems(in: category, scope: scope).first
    }
}

private extension LineItem {
    static func snapshot(of item: MenuItem, in category: MenuCategory, quantity: Double = 1) -> LineItem {
        LineItem(
            id: UUID(),
            menuItemId: item.id,
            displayName: item.name,
            servingDescription: item.servingDescription,
            macros: item.macros,
            quantity: quantity,
            iconName: item.iconName ?? category.iconName
        )
    }

    func withQuantity(_ newQuantity: Double) -> LineItem {
        LineItem(
            id: id,
            menuItemId: menuItemId,
            displayName: displayName,
            servingDescription: servingDescription,
            macros: macros,
            quantity: newQuantity,
            iconName: iconName
        )
    }
}
