import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings

    private static let macroFactorShortcutsURL = URL(
        string: "https://github.com/MacroFactor/apple-shortcuts"
    )!

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Shortcut name") {
                        TextField("Log by JSON", text: $settings.shortcutName)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Link(destination: Self.macroFactorShortcutsURL) {
                        Label("Install MacroFactor Shortcut", systemImage: "arrow.up.right.square")
                    }
                } header: {
                    Text("MacroFactor")
                } footer: {
                    Text("The name must match the Shortcut you installed from MacroFactor. Defaults to “Log by JSON”.")
                }

                Section {
                    LabeledContent("Version", value: Self.appVersion)
                    LabeledContent("Bundle", value: Bundle.main.bundleIdentifier ?? "—")
                } header: {
                    Text("About")
                }

                Section {
                    Text("Loadout is not affiliated with, endorsed by, or sponsored by any restaurant. Nutrition information is sourced from each restaurant's publicly available data and may differ from your actual order. Always verify critical dietary information directly with the restaurant.")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                } header: {
                    Text("Disclaimer")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }
}
