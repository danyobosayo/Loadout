import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ProfileStore.self) private var profile
    @Environment(HealthStore.self) private var health
    @Environment(ProStore.self) private var pro
    @Environment(AppreciationStore.self) private var appreciation
    @Environment(\.menuRepository) private var menuRepository
    @Environment(\.openURL) private var openURL
    @State private var restaurants: [Restaurant] = []
    @State private var launchFailed = false
    @State private var showGoalSheet = false
    @State private var showPaywall = false
    @State private var showRestaurantRequest = false
    @State private var mailFailed = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        masthead
                            .padding(.top, Spacing.sm)

                        if !pro.isPro {
                            section("Loadout Pro") {
                                Button { showPaywall = true } label: {
                                    Card(highlight: .volt) {
                                        HStack(spacing: Spacing.md) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(.volt)
                                                .frame(width: 40, height: 40)
                                                .background(Circle().fill(Color.volt.opacity(0.12)))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Unlock Loadout Pro").font(.appHeadline).foregroundStyle(.textPrimary)
                                                Text("Targets, Budget Mode, Health & auto-build").font(.appCaption).foregroundStyle(.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.textTertiary)
                                        }
                                    }
                                }
                                .buttonStyle(.pressable)
                                .accessibilityIdentifier("unlockPro")
                            }
                        }

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
                            .accessibilityIdentifier("dailyTargetCard")
                            .accessibilityHint(profile.goal == nil ? "Calculate or enter your daily macros." : "Edit your daily macro target.")
                        }

                        section("Auto-build") {
                            Card { autoBuildContent }
                        }

                        section("Apple Health") {
                            Card { appleHealthContent }
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

                        section("Say hello") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Loadout is a one-person passion project. Every menu in it was checked by hand, so if something looks wrong — or something's missing — telling me is genuinely the fastest way it gets fixed.")
                                        .font(.appCaption)
                                        .foregroundStyle(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    linkRow("Request a restaurant", "storefront") {
                                        Haptics.tap()
                                        showRestaurantRequest = true
                                    }
                                    Divider().overlay(Color.hairline)
                                    linkRow("Send feedback", "envelope") { sendFeedback() }

                                    if let website = IndieLinks.websiteURL {
                                        Divider().overlay(Color.hairline)
                                        linkRow("Loadout on the web", "safari") { openURL(website) }
                                    }

                                    // Hidden entirely before there's a listing to
                                    // review — a button that can't do its job is
                                    // worse than no button.
                                    if IndieLinks.isPublished {
                                        Divider().overlay(Color.hairline)
                                        linkRow("Leave a review", "star") { leaveReview() }
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
                if health.status == .connected { await health.refreshToday() }
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
            .alert("Couldn't open Mail", isPresented: $mailFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You can reach me at \(IndieLinks.feedbackEmail).")
            }
            .sheet(isPresented: $showRestaurantRequest) {
                RestaurantRequestSheet()
                    .presentationDetents([.large])
                    .presentationCornerRadius(Radius.sheet)
                    .presentationBackground(Color.void)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationCornerRadius(Radius.sheet)
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

    /// What "Fit my macros" should aim for. A focus is pick-one — the options
    /// pull the objective in competing directions — while the exclusions below
    /// stack, because each just removes items from consideration.
    @ViewBuilder
    private var autoBuildContent: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Focus")
                .microLabelStyle()

            VStack(spacing: Spacing.xs) {
                ForEach(AutoBuildFocus.allCases) { focus in
                    Button {
                        Haptics.tap()
                        withAnimation(Motion.snap) { settings.autoBuild.focus = focus }
                    } label: {
                        focusRow(focus, selected: settings.autoBuild.focus == focus)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("autoBuildFocus.\(focus.rawValue)")
                    .accessibilityAddTraits(settings.autoBuild.focus == focus ? [.isSelected] : [])
                }
            }

            Divider().overlay(Color.hairline)

            Text("Always skip")
                .microLabelStyle()

            ForEach(AutoBuildExclusion.allCases) { exclusion in
                Toggle(isOn: Binding(
                    get: { settings.autoBuild.exclusions.contains(exclusion) },
                    set: { isOn in
                        Haptics.tap()
                        if isOn { settings.autoBuild.exclusions.insert(exclusion) }
                        else { settings.autoBuild.exclusions.remove(exclusion) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exclusion.title).font(.appBody).foregroundStyle(.textPrimary)
                        Text(exclusion.detail).font(.appCaption).foregroundStyle(.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.volt)
                .accessibilityIdentifier("autoBuildExclusion.\(exclusion.rawValue)")
            }

            Divider().overlay(Color.hairline)

            Text("Diet")
                .microLabelStyle()

            ForEach(DietaryRestriction.allCases.filter { !$0.isAllergen }) { restriction in
                restrictionToggle(restriction)
            }

            Text("Allergens")
                .microLabelStyle()
                .padding(.top, Spacing.xs)

            ForEach(DietaryRestriction.allCases.filter(\.isAllergen)) { restriction in
                restrictionToggle(restriction)
            }

            Text("""
                 Auto-build skips anything that doesn't clear these, including \
                 items we haven't been able to check. Allergen data comes from \
                 each restaurant's published guide and is best effort — kitchens \
                 share surfaces and suppliers change. Always confirm a severe \
                 allergy with the restaurant.
                 """)
                .font(.appCaption)
                .foregroundStyle(.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func restrictionToggle(_ restriction: DietaryRestriction) -> some View {
        @Bindable var settings = settings
        return Toggle(isOn: Binding(
            get: { settings.autoBuild.restrictions.contains(restriction) },
            set: { isOn in
                Haptics.tap()
                if isOn { settings.autoBuild.restrictions.insert(restriction) }
                else { settings.autoBuild.restrictions.remove(restriction) }
            }
        )) {
            Text(restriction.title).font(.appBody).foregroundStyle(.textPrimary)
        }
        .tint(.volt)
        .accessibilityIdentifier("dietaryRestriction.\(restriction.rawValue)")
    }

    private func focusRow(_ focus: AutoBuildFocus, selected: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: focus.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? .volt : .textTertiary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(selected ? Color.volt.opacity(0.14) : Color.white.opacity(0.03)))
            VStack(alignment: .leading, spacing: 1) {
                Text(focus.title)
                    .font(.appBody)
                    .foregroundStyle(selected ? .textPrimary : .textSecondary)
                Text(focus.detail)
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selected ? .volt : .textTertiary)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(selected ? Color.volt.opacity(0.07) : .clear)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .strokeBorder(selected ? Color.volt.opacity(0.35) : .clear, lineWidth: 1)
                }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var appleHealthContent: some View {
        switch health.status {
        case .unavailable:
            Text("Apple Health isn't available on this device.")
                .font(.appCaption)
                .foregroundStyle(.textTertiary)
        case .notConnected:
            VStack(alignment: .leading, spacing: Spacing.md) {
                Button {
                    if pro.isPro { Task { await health.connect() } } else { showPaywall = true }
                } label: {
                    HStack {
                        Label("Connect Apple Health", systemImage: "heart.text.square")
                            .font(.appBody)
                            .foregroundStyle(.volt)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                Text("Reads today's calories and macros you've logged elsewhere so Loadout can show what you have left. Read-only — it never writes to Health.")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        case .connected:
            connectedHealth
        }
    }

    @ViewBuilder
    private var connectedHealth: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today").microLabelStyle()
                Spacer()
                Button {
                    Task { await health.refreshToday() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh from Health")
            }

            if let consumed = health.consumedToday {
                healthRow("Eaten today", consumed)
                if let target = profile.target, let remaining = health.remaining(against: target) {
                    Divider().overlay(Color.hairline)
                    let over = remaining.calories < 0
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            if over {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.fat)
                            }
                            Text(over ? "Over budget" : "Left today")
                                .font(.appCaption)
                                .foregroundStyle(over ? .fat : .textSecondary)
                        }
                        MacroBar(macros: remaining, style: .inline)
                    }
                } else {
                    Text("Set a daily target above to see what's left.")
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                }
            } else {
                Text("Reading today's totals…")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }

    private func healthRow(_ label: String, _ macros: Macros) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label).font(.appCaption).foregroundStyle(.textSecondary)
            MacroBar(macros: macros, style: .inline)
        }
    }

    private func linkRow(_ label: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.volt)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.textTertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.pressable)
    }

    private func sendFeedback() {
        Haptics.tap()
        guard let url = IndieLinks.mail(
            subject: "Loadout feedback",
            body: "\n\n— Loadout \(IndieLinks.appVersion)"
        ) else { return }
        openURL(url) { opened in if !opened { mailFailed = true } }
    }

    private func leaveReview() {
        Haptics.tap()
        guard let url = IndieLinks.writeReviewURL else { return }
        appreciation.markReviewRequested()
        openURL(url)
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
