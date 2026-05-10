import SwiftUI

struct RestaurantsView: View {
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurants: [Restaurant] = []
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        "Couldn't load menus",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if restaurants.isEmpty {
                    ProgressView()
                } else {
                    list
                }
            }
            .navigationTitle("Restaurants")
            .navigationDestination(for: Restaurant.self) { restaurant in
                MenuView(restaurant: restaurant)
            }
            .task {
                await load()
            }
        }
    }

    private var list: some View {
        List(restaurants) { restaurant in
            NavigationLink(value: restaurant) {
                RestaurantRow(restaurant: restaurant)
            }
        }
    }

    private func load() async {
        do {
            restaurants = try await menuRepository.availableRestaurants()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(restaurant.name)
                .font(.appBody)
            Text("^[\(itemCount) item](inflect: true) across \(restaurant.categories.count) categories")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
        }
        .padding(.vertical, 4)
    }

    private var itemCount: Int {
        restaurant.categories.reduce(0) { $0 + $1.items.count }
    }
}

#Preview {
    RestaurantsView()
}
