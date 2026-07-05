import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurants: [Restaurant] = []

    private static let macroFactorShortcutsURL = URL(
        string: "https://github.com/MacroFactor/apple-shortcuts"
    )!

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        masthead
                            .padding(.top, Spacing.sm)

                        section("MacroFactor") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Shortcut name")
                                            .font(.appCaption)
                                            .foregroundStyle(.textSecondary)
                                        TextField("Log by JSON", text: $settings.shortcutName)
                                            .font(.appHeadline)
                                            .foregroundStyle(.textPrimary)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    }

                                    Divider().overlay(Color.hairline)

                                    Link(destination: Self.macroFactorShortcutsURL) {
                                        HStack {
                                            Label("Install MacroFactor Shortcut", systemImage: "arrow.up.right.square")
                                                .font(.appBody)
                                                .foregroundStyle(.volt)
                                            Spacer()
                                        }
                                    }

                                    Text("The name must match the Shortcut installed from MacroFactor. Defaults to \u{201C}Log by JSON\u{201D}.")
                                        .font(.appCaption)
                                        .foregroundStyle(.textTertiary)
                                }
                            }
                        }

                        section("Data sources") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                                    if restaurants.isEmpty {
                                        Text("Loading menu metadata…")
                                            .font(.appCaption)
                                            .foregroundStyle(.textTertiary)
                                    }
                                    ForEach(restaurants) { restaurant in
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(restaurant.name)
                                                .font(.appBody)
                                                .foregroundStyle(.textPrimary)
                                            Spacer()
                                            Text("verified \(restaurant.dataSource.fetchedAt)")
                                                .font(.appCaption)
                                                .foregroundStyle(.textSecondary)
                                        }
                                    }
                                }
                            }
                        }

                        section("About") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    row("Version", Self.appVersion)
                                    row("Bundle", Bundle.main.bundleIdentifier ?? "—")
                                    row("Design language", "Obsidian")
                                }
                            }
                        }

                        Text("Loadout is not affiliated with, endorsed by, or sponsored by any restaurant. Nutrition information is sourced from each restaurant's publicly available data and may differ from your actual order. Always verify critical dietary information directly with the restaurant.")
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                            .padding(.horizontal, Spacing.xs)
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                restaurants = (try? await menuRepository.availableRestaurants()) ?? []
            }
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tune it")
                .microLabelStyle(.volt)
            Text("Settings")
                .displayXLStyle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .microLabelStyle()
                .padding(.horizontal, Spacing.xs)
            content()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appBody)
                .foregroundStyle(.textPrimary)
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }
}
