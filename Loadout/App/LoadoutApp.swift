import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    @State private var settings = SettingsStore()
    @State private var macroFactorExport = MacroFactorExport()
    @State private var profile = ProfileStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(macroFactorExport)
                .environment(profile)
        }
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
    }
}
