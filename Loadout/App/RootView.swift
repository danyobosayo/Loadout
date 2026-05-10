import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            RestaurantsView()
                .tabItem { Label("Menus", systemImage: "fork.knife") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        }
    }
}

#Preview {
    RootView()
}
