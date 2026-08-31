import AppIntents
import Foundation
import SwiftData

/// A saved recipe, as Shortcuts and Siri see it.
///
/// Carries a *snapshot* of the macros rather than a live reference: an intent
/// may run long after the query, and a value that can't go stale mid-run is
/// worth more here than one that stays current.
struct RecipeEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String
    let restaurantName: String
    let macros: Macros

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Recipe",
        numericFormat: "\(placeholder: .int) recipes"
    )

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(restaurantName) · \(Int(macros.calories.rounded())) kcal"
        )
    }

    static let defaultQuery = RecipeQuery()
}

/// Fetches recipes for the parameter picker and for "log my usual X" matching.
struct RecipeQuery: EntityStringQuery {
    @MainActor
    private func all() -> [RecipeEntity] {
        guard let container = LoadoutStore.shared else { return [] }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<FavoriteMeal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let saved = try? context.fetch(descriptor) else { return [] }
        return saved.map {
            RecipeEntity(
                id: $0.id,
                name: $0.name,
                restaurantName: ExportService.displayName(forRestaurantId: $0.restaurantId),
                macros: $0.totalMacros
            )
        }
    }

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [RecipeEntity] {
        let wanted = Set(identifiers)
        return all().filter { wanted.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [RecipeEntity] {
        // Newest first — "log my usual" almost always means a recent one.
        Array(all().prefix(10))
    }

    /// Matches what the user actually said. Siri hands over a loose string, so
    /// match the restaurant name too: "log my Chipotle" should find "Usual
    /// Chipotle Bowl" without the name having to be exact.
    @MainActor
    func entities(matching string: String) async throws -> [RecipeEntity] {
        let needle = string.lowercased().trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return all() }
        return all().filter {
            $0.name.lowercased().contains(needle)
                || $0.restaurantName.lowercased().contains(needle)
        }
    }
}
