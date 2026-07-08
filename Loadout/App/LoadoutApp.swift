import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    @State private var settings = SettingsStore()
    @State private var macroFactorExport = MacroFactorExport()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(macroFactorExport)
        }
        .modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
    }
}
