import Foundation
import SwiftData

/// On-device persisted favorite — a snapshot of a `BuiltMeal` plus a
/// user-given name. Line items are stored verbatim (Codable into
/// SwiftData's binary attribute), so a favorite saved a year ago keeps
/// rendering and totalling correctly even if the source menu changes,
/// renames, or pulls items.
@Model
final class FavoriteMeal {
    @Attribute(.unique) var id: UUID
    var name: String
    var restaurantId: String
    var createdAt: Date
    var lineItems: [LineItem]

    init(
        id: UUID = UUID(),
        name: String,
        restaurantId: String,
        createdAt: Date = .now,
        lineItems: [LineItem]
    ) {
        self.id = id
        self.name = name
        self.restaurantId = restaurantId
        self.createdAt = createdAt
        self.lineItems = lineItems
    }

    var totalMacros: Macros {
        lineItems.reduce(.zero) { $0 + $1.macros * $1.quantity }
    }
}
