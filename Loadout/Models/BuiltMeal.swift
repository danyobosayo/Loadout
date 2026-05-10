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
}
