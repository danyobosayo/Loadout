import Foundation
import SwiftData

/// On-device persisted log entry — auto-saved every time the user taps
/// "Log to MacroFactor". Per PROJECT.md §7.4, History is capped at the
/// last 50 meals via FIFO eviction; no editing, no naming. Re-opening
/// works the same way as Favorites: pre-populate a `MealBuilderStore`
/// with the saved line items.
///
/// Fields mirror `FavoriteMeal` minus the user-given name. Two separate
/// @Model classes (instead of a shared base) keep the SwiftData store
/// flat and avoid runtime polymorphism — favorites and logged meals are
/// queried independently and have independent retention semantics.
@Model
final class LoggedMeal {
    @Attribute(.unique) var id: UUID
    var restaurantId: String
    var loggedAt: Date
    var lineItems: [LineItem]

    init(
        id: UUID = UUID(),
        restaurantId: String,
        loggedAt: Date = .now,
        lineItems: [LineItem]
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.loggedAt = loggedAt
        self.lineItems = lineItems
    }

    var totalMacros: Macros {
        lineItems.reduce(.zero) { $0 + $1.macros * $1.quantity }
    }
}

/// FIFO retention helper. Call after every `LoggedMeal` insert. Counts
/// outside-of-context to avoid loading every entry; deletes the
/// oldest-first until under the limit.
nonisolated enum LoggedMealRetention {
    static let limit = 50

    static func enforceLimit(in context: ModelContext) throws {
        let total = try context.fetchCount(FetchDescriptor<LoggedMeal>())
        let overflow = total - limit
        guard overflow > 0 else { return }

        var oldestFirst = FetchDescriptor<LoggedMeal>(
            sortBy: [SortDescriptor(\LoggedMeal.loggedAt, order: .forward)]
        )
        oldestFirst.fetchLimit = overflow
        let toDelete = try context.fetch(oldestFirst)
        for meal in toDelete {
            context.delete(meal)
        }
    }
}
