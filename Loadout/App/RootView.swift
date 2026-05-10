import SwiftUI

struct RootView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        TabView {
            RestaurantsView()
                .tabItem { Label("Menus", systemImage: "fork.knife") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !settings.hasCompletedOnboarding },
            set: { isPresented in
                // SwiftUI calls this with `false` when the cover dismisses.
                // That's our signal to mark onboarding done — once true,
                // the binding's `get` returns false, the cover stays gone.
                if !isPresented {
                    settings.hasCompletedOnboarding = true
                }
            }
        )) {
            OnboardingView()
        }
    }
}

#Preview {
    RootView()
}
