import Foundation

nonisolated struct BuiltMeal: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    let restaurantId: String
    let name: String?
    let lineItems: [LineItem]
    let createdAt: Date

    var totalMacros: Macros {
        lineItems.reduce(.zero) { $0 + $1.macros * $1.quantity }
    }
}

nonisolated struct LineItem: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    let menuItemId: String
    // Snapshot fields. A logged or favorited meal must keep totalling and
    // rendering correctly even after the source menu is updated, renamed,
    // or pulled — otherwise a year-old favorite becomes "[unknown] · 0 cal"
    // the day Chipotle tweaks its calculator.
    let displayName: String
    let servingDescription: String
    let macros: Macros
    let quantity: Double
    // Resolved at snapshot time (item override or category fallback). Nil
    // is permitted — `MenuItemIcon` shows the universal fallback symbol.
    let iconName: String?
    /// Set when this line came from a configured item — a Box Combo with the slaw
    /// declined. Kept so the row can be reopened and edited, and so a favorite
    /// replays the exact order. `macros` above is already the configured total,
    /// so nothing downstream has to understand configurations to add up.
    let configuration: ItemConfiguration?
    /// Snapshot of "no coleslaw · extra cane's sauce" at the time it was built,
    /// for the same reason the other fields are snapshots: a favorite must still
    /// read correctly after the menu moves under it.
    let configurationDetail: String?

    init(
        id: UUID,
        menuItemId: String,
        displayName: String,
        servingDescription: String,
        macros: Macros,
        quantity: Double,
        iconName: String? = nil,
        configuration: ItemConfiguration? = nil,
        configurationDetail: String? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.displayName = displayName
        self.servingDescription = servingDescription
        self.macros = macros
        self.quantity = quantity
        self.iconName = iconName
        self.configuration = configuration
        self.configurationDetail = configurationDetail
    }
}
