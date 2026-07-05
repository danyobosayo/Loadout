import Foundation

nonisolated extension Restaurant {
    /// Reverse lookup by item id → the item and its parent category.
    /// Formats reference items by id (`autoAdd`, `subsetItemIds`), but a
    /// `LineItem` snapshot needs both the `MenuItem` and its `MenuCategory`
    /// (for the icon fallback and rule). Linear scan; menu-sized data
    /// needs no index.
    func resolve(menuItemId: String) -> (item: MenuItem, category: MenuCategory)? {
        for category in categories {
            if let item = category.items.first(where: { $0.id == menuItemId }) {
                return (item, category)
            }
        }
        return nil
    }

    func category(id: String) -> MenuCategory? {
        categories.first { $0.id == id }
    }
}
