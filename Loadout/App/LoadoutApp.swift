import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
    }
}
