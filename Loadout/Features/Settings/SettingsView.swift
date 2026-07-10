import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ProfileStore.self) private var profile
    @Environment(\.menuRepository) private var menuRepository
    @Environment(\.openURL) private var openURL
    @State private var restaurants: [Restaurant] = []
    @State private var launchFailed = false
    @State private var showGoalSheet = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        masthead
                            .padding(.top, Spacing.sm)

                        section("Daily target") {
                            Button {
                                showGoalSheet = true
                            } label: {
                                Card {
                                    if let goal = profile.goal {
                                        VStack(alignment: .leading, spacing: Spacing.sm) {
                                            MacroBar(macros: goal.target, style: .inline)
                                            Text("\(goal.source == .generated ? "Calculated" : "Manual") · updated \(goal.updatedAt.formatted(.dateTime.month(.abbreviated).day()))")
                                                .font(.appCaption)
                                                .foregroundStyle(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        HStack {
                                            Label("Set your daily target", systemImage: "target")
                                                .font(.appBody)
                                                .foregroundStyle(.volt)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.textTertiary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.pressable)
                            .accessibilityHint(profile.goal == nil ? "Calculate or enter your daily macros." : "Edit your daily macro target.")
                        }

                        section("MacroFactor") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Shortcut name")
                                            .font(.appCaption)
                                            .foregroundStyle(.textSecondary)
                                        TextField(MacroFactorIntegration.defaultShortcutName, text: $settings.shortcutName)
                                            .font(.appHeadline)
                                            .foregroundStyle(.textPrimary)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    }

                                    Divider().overlay(Color.hairline)

                                    Link(destination: MacroFactorIntegration.installShortcutURL) {
                                        HStack {
                                            Label("Install the Loadout shortcut", systemImage: "arrow.up.right.square")
                                                .font(.appBody)
                                                .foregroundStyle(.volt)
                                            Spacer()
                                        }
                                    }

                                    Button {
                                        testConnection()
                                    } label: {
                                        HStack {
                                            Label("Test connection", systemImage: "checkmark.seal")
                                                .font(.appBody)
                                                .foregroundStyle(.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.textTertiary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Sends a one-calorie test item to your shortcut so you can confirm it logs to MacroFactor.")

                                    Text("Loadout hands each meal to a Shortcut you install once, which passes it to MacroFactor's \u{201C}Log by JSON\u{201D} action. The name above must match that Shortcut's title. \u{201C}Test connection\u{201D} fires it with a one-calorie test item.")
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
            .alert("Couldn't open Shortcuts", isPresented: $launchFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Make sure the Shortcuts app is installed, then try again.")
            }
            .sheet(isPresented: $showGoalSheet) {
                GoalSetupView { goal in
                    profile.goal = goal
                    showGoalSheet = false
                }
                .presentationDetents([.large])
                .presentationCornerRadius(Radius.sheet)
                .presentationBackground(Color.void)
                .presentationDragIndicator(.visible)
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

    /// Fires the user's Shortcut with a tiny 1-calorie probe so they can
    /// confirm the hand-off works end to end — MacroFactor logs the test
    /// item, or Shortcuts reports the shortcut can't be found.
    private func testConnection() {
        let exporter = MacroFactorExporter(shortcutName: settings.shortcutName)
        let probe = MFExport.Food(
            source: MFExport.sourceIdentifier,
            icon: MFExport.defaultIcon,
            name: "Loadout connection test",
            nutrients: [MFExport.NutrientKey.energy: 1],
            serving: .one,
            llmPrompt: nil,
            barcode: nil,
            brand: nil,
            beverage: nil,
            notes: "Test from Loadout Settings",
            recipe: nil
        )
        if let url = try? exporter.shortcutsURL(for: probe) {
            openURL(url) { accepted in
                if !accepted { launchFailed = true }
            }
        }
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
