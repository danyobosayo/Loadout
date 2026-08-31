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

    /// Stations a person can actually order from. Everything that renders a
    /// station list or solves a meal uses this; only `resolve` sees pantry
    /// stations, because a component still needs its macros looked up.
    var orderableCategories: [MenuCategory] { categories.filter { !$0.isHidden } }

    /// Stations whose items are whole orderable things, in menu order. Empty for
    /// a build-your-own restaurant, where the landing screen offers formats
    /// instead — a Chipotle burrito is something you assemble, not something you
    /// pick off a list.
    var headlineCategories: [MenuCategory] { orderableCategories.filter(\.isHeadline) }

    func category(id: String) -> MenuCategory? {
        categories.first { $0.id == id }
    }
}
