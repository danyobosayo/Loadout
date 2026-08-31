import AppIntents
import Foundation
import SwiftData
import Testing
@testable import Loadout

/// Intents run outside the app, so the parts that can be exercised without
/// Siri are worth pinning: the entity's shape, the query's matching, and that
/// logging writes history.
@MainActor
struct AppIntentTests {
    /// An in-memory stand-in for `LoadoutStore.shared`, so tests never touch
    /// the real store.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: LoadoutStore.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func recipe(_ name: String, _ restaurantId: String, calories: Double) -> FavoriteMeal {
        FavoriteMeal(
            name: name,
            restaurantId: restaurantId,
            lineItems: [
                LineItem(
                    id: UUID(),
                    menuItemId: "\(restaurantId).protein.chicken",
                    displayName: "Chicken",
                    servingDescription: "4 oz",
                    macros: Macros(calories: calories, proteinGrams: 32, carbGrams: 0, fatGrams: 7),
                    quantity: 1
                )
            ]
        )
    }

    @Test func entityCarriesASnapshotNotALiveReference() throws {
        let context = try makeContext()
        let saved = recipe("Usual Chipotle", "chipotle", calories: 180)
        context.insert(saved)
        try context.save()

        let entity = RecipeEntity(
            id: saved.id,
            name: saved.name,
            restaurantName: ExportService.displayName(forRestaurantId: saved.restaurantId),
            macros: saved.totalMacros
        )
        #expect(entity.macros.calories == 180)

        // Mutating the stored recipe must not change an entity already handed
        // to Shortcuts — an intent can run long after the picker resolved it.
        saved.lineItems = []
        try context.save()
        #expect(entity.macros.calories == 180)
    }

    @Test func entityDisplaysNameAndRestaurant() {
        let entity = RecipeEntity(
            id: UUID(), name: "Usual Chipotle", restaurantName: "Chipotle",
            macros: Macros(calories: 817, proteinGrams: 45, carbGrams: 66, fatGrams: 41)
        )
        let display = entity.displayRepresentation
        #expect("\(display.title)".contains("Usual Chipotle"))
    }

    /// Siri hands over loose text, so matching has to cover the restaurant name
    /// too — "log my Chipotle" should find "Usual Chipotle Bowl".
    @Test func stringMatchingCoversNameAndRestaurant() {
        let entities = [
            RecipeEntity(id: UUID(), name: "Usual Bowl", restaurantName: "Chipotle", macros: .zero),
            RecipeEntity(id: UUID(), name: "Big Sub", restaurantName: "Jersey Mike's Subs", macros: .zero),
        ]
        func matches(_ needle: String) -> [RecipeEntity] {
            let n = needle.lowercased()
            return entities.filter {
                $0.name.lowercased().contains(n) || $0.restaurantName.lowercased().contains(n)
            }
        }
        #expect(matches("chipotle").count == 1)
        #expect(matches("bowl").count == 1)
        #expect(matches("jersey").count == 1)
        #expect(matches("nothing").isEmpty)
    }

    /// A meal logged by Siri is still a meal you logged — it belongs in History.
    @Test func loggingWritesToHistory() throws {
        let context = try makeContext()
        let saved = recipe("Usual Chipotle", "chipotle", calories: 180)
        context.insert(saved)
        try context.save()

        // Mirrors LogRecipeToHealthIntent.recordHistory.
        let id = saved.id
        let found = try #require(
            try context.fetch(FetchDescriptor<FavoriteMeal>(predicate: #Predicate { $0.id == id })).first
        )
        context.insert(LoggedMeal(restaurantId: found.restaurantId, lineItems: found.lineItems))
        try context.save()

        let history = try context.fetch(FetchDescriptor<LoggedMeal>())
        #expect(history.count == 1)
        #expect(history.first?.restaurantId == "chipotle")
        #expect(history.first?.totalMacros.calories == 180)
    }

    /// The shared container is what makes intents and the app agree on data.
    @Test func sharedSchemaCoversBothPersistedModels() {
        let names = LoadoutStore.schema.entities.map(\.name)
        #expect(names.contains("FavoriteMeal"))
        #expect(names.contains("LoggedMeal"))
    }
}
