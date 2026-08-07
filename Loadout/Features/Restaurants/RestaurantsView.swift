import SwiftUI

/// The Build tab root — masthead over aurora, one identity card per
/// restaurant, cascading in on first appearance.
struct RestaurantsView: View {
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurants: [Restaurant] = []
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                if let loadError {
                    EmptyStateView(
                        systemImage: "exclamationmark.triangle",
                        title: "Menus didn't load",
                        message: loadError,
                        tint: .destructiveRed
                    )
                } else if restaurants.isEmpty {
                    ProgressView()
                        .tint(.volt)
                } else {
                    list
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Restaurant.self) { restaurant in
                FormatPickerView(restaurant: restaurant)
            }
            .navigationDestination(for: MenuRoute.self) { route in
                MenuView(route: route)
            }
            .task { await load() }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                masthead
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xs)

                ForEach(Array(restaurants.enumerated()), id: \.element.id) { index, restaurant in
                    NavigationLink(value: restaurant) {
                        RestaurantCard(restaurant: restaurant)
                    }
                    .buttonStyle(.pressable)
                    .entrance(index + 1)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Pick your line")
                .microLabelStyle(.volt)
            Text("Loadout")
                .displayXLStyle()
        }
        .entrance(0)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func load() async {
        do {
            restaurants = try await menuRepository.availableRestaurants()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

/// Identity card: hue tile with restaurant glyph, name, station/item meta.
private struct RestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        // Fourteen restaurants: the tile and padding are trimmed from the
        // default so roughly nine fit a screen instead of six. Type sizes are
        // untouched — this is density, not legibility.
        Card(padding: Spacing.sm + Spacing.xs) {
            HStack(spacing: Spacing.md) {
                identityTile

                VStack(alignment: .leading, spacing: 3) {
                    Text(restaurant.name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(restaurant.categories.count) stations · \(itemCount) items")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(restaurant.name), \(restaurant.categories.count) stations, \(itemCount) items")
    }

    private var identityTile: some View {
        Image(restaurant.style.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.void)
            .frame(width: 44, height: 44)
            .background {
                RoundedRectangle(cornerRadius: Radius.chip + 4, style: .continuous)
                    .fill(restaurant.style.hue)
            }
            .accessibilityHidden(true)
    }

    private var itemCount: Int {
        restaurant.categories.reduce(0) { $0 + $1.items.count }
    }
}

#Preview {
    RestaurantsView()
}
