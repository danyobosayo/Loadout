import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: [SortDescriptor(\FavoriteMeal.createdAt, order: .reverse)])
    private var favorites: [FavoriteMeal]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "heart",
                        description: Text("Tap the heart icon while building a meal to save it here.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(for: FavoriteMeal.self) { favorite in
                ReopenFavoriteView(favorite: favorite)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(favorites) { favorite in
                NavigationLink(value: favorite) {
                    FavoriteRow(favorite: favorite)
                }
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
        try? modelContext.save()
    }
}

private struct FavoriteRow: View {
    let favorite: FavoriteMeal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(favorite.name)
                    .font(.appBody)
                Spacer()
                Text(favorite.restaurantId.capitalized)
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            MacroBar(macros: favorite.totalMacros, style: .inline)
            Text("^[\(favorite.lineItems.count) item](inflect: true)")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
        }
        .padding(.vertical, 4)
    }
}

/// Loads the favorite's source restaurant from the bundled menu, then
/// hands off to `MenuView` with the saved line items as seed. The user
/// lands directly in the meal tray (per `MenuView.init` behavior) so
/// re-running a favorite is a tap → tap-Log flow.
private struct ReopenFavoriteView: View {
    let favorite: FavoriteMeal
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurant: Restaurant?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let restaurant {
                MenuView(restaurant: restaurant, seed: favorite.lineItems)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn't reopen this favorite",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                ProgressView().task(id: favorite.id) {
                    do {
                        restaurant = try await menuRepository.loadRestaurant(id: favorite.restaurantId)
                    } catch {
                        loadError = error.localizedDescription
                    }
                }
            }
        }
    }
}
