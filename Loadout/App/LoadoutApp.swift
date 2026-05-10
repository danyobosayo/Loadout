import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
        }
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
    }
}
