import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            RestaurantsView()
                .tabItem { Label("Menus", systemImage: "fork.knife") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
        }
    }
}

#Preview {
    RootView()
}
