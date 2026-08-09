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
                // Share the container with App Intents so a recipe logged by
                // Siri and one logged in the app are the same row. The fallback
                // is only reachable if the store is unreadable, where
                // `.modelContainer(for:)` behaves exactly as it did before.
                .modelContainerIfAvailable(LoadoutStore.shared)
        }
    }
}
