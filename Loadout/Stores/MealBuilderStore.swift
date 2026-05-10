import Foundation
import Observation

@MainActor
@Observable
final class MealBuilderStore {
    let restaurant: Restaurant
    private(set) var lineItems: [LineItem] = []

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
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

    @discardableResult
    func add(_ item: MenuItem, in category: MenuCategory) -> AddOutcome {
        // Re-tapping an already-added item bumps quantity regardless of
        // selectionRule. Quantity is "more of the same thing"; selectionRule
        // governs how many *distinct* items are allowed in a category.
        if let idx = lineItems.firstIndex(where: { $0.menuItemId == item.id }) {
            lineItems[idx] = lineItems[idx].withQuantity(lineItems[idx].quantity + 1)
            return .incremented
        }

        switch category.selectionRule {
        case .selectOne:
            if let existing = firstLineItem(in: category) {
                lineItems.removeAll { $0.id == existing.id }
                lineItems.append(.snapshot(of: item, in: category))
                return .replaced(removedMenuItemId: existing.menuItemId)
            }
            lineItems.append(.snapshot(of: item, in: category))
            return .added

        case .selectMany:
            lineItems.append(.snapshot(of: item, in: category))
            return .added

        case .selectUpTo(let max):
            if lineItems(in: category).count >= max {
                return .rejectedByLimit(max: max)
            }
            lineItems.append(.snapshot(of: item, in: category))
            return .added
        }
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

    private func lineItems(in category: MenuCategory) -> [LineItem] {
        let ids = Set(category.items.map(\.id))
        return lineItems.filter { ids.contains($0.menuItemId) }
    }

    private func firstLineItem(in category: MenuCategory) -> LineItem? {
        lineItems(in: category).first
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
