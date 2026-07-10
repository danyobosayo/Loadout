import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    @State private var settings = SettingsStore()
    @State private var macroFactorExport = MacroFactorExport()
    @State private var profile = ProfileStore()
    @State private var health = HealthStore()
    @State private var pro = ProStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(macroFactorExport)
                .environment(profile)
                .environment(health)
                .environment(pro)
        }
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
    }
}
