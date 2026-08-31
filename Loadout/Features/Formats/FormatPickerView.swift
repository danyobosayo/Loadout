import SwiftUI
import SwiftData

/// Navigation value for entering the builder. A chosen `format` drives
/// guided entry; `nil` is the build-your-own path (today's behavior).
nonisolated struct MenuRoute: Hashable {
    let restaurant: Restaurant
    let format: OrderFormat?
    /// When true, the builder auto-fills a macro-fitting suggestion on entry
    /// (the "Fit my macros" path). The solve runs in `MenuView` where the
    /// profile/health budget is in scope.
    var autoBuild: Bool = false
    /// A complete meal to land in the tray on entry — a published preset or one
    /// of the user's saved recipes. Unlike the solver's output this is known at
    /// the link, so it rides the route directly. Resolve it once into `@State`
    /// upstream: `LineItem` ids are fresh UUIDs, and regenerating them per body
    /// pass would churn the route's hash and break the link's identity.
    var seed: [LineItem] = []
    /// A headline item picked on the landing screen. `MenuView` opens straight
    /// into its configurator, so "what are you having?" hands directly to "how do
    /// you want it?" without a menu screen in between.
    var configureItemId: String?
}

/// The counter moment — shown when a restaurant is tapped, before the
/// stations. Three ways in, ordered most-personal to most-manual: the meals
/// you've saved here, the restaurant's own published meals, then the formats
/// that scaffold a build. Everything loads async and every section hides when
/// empty, so this never dead-ends — build-your-own is always the floor.
struct FormatPickerView: View {
    let restaurant: Restaurant
    @Environment(\.menuRepository) private var menuRepository
    @Environment(ProfileStore.self) private var profile
    @Environment(HealthStore.self) private var health
    @Environment(ProStore.self) private var pro
    @Environment(SettingsStore.self) private var settings
    /// The user's recipes saved *at this restaurant*, newest first.
    @Query private var savedMeals: [FavoriteMeal]
    @State private var formats: [OrderFormat] = []
    @State private var presets: [ResolvedPreset] = []
    /// Nil until the async load finishes. Without it the view would decide it
    /// has nothing to offer on the first body pass — before formats and presets
    /// arrive — and flash the station list at every restaurant.
    @State private var loaded = false

    /// Keeping more than a few here would turn the counter moment into a second
    /// Recipes tab — which is one tap away in the tab bar.
    private static let savedMealLimit = 3

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        let restaurantId = restaurant.id
        _savedMeals = Query(
            filter: #Predicate<FavoriteMeal> { $0.restaurantId == restaurantId },
            sort: [SortDescriptor(\FavoriteMeal.createdAt, order: .reverse)]
        )
    }

    /// A preset with its lines resolved against the live menu. Resolved once on
    /// load so the `LineItem` UUIDs — and therefore each link's route hash —
    /// stay stable across body passes.
    private struct ResolvedPreset: Identifiable {
        let preset: MealPreset
        let lineItems: [LineItem]
        let macros: Macros
        var id: String { preset.id }
    }

    private var shownSavedMeals: [FavoriteMeal] {
        Array(savedMeals.prefix(Self.savedMealLimit))
    }

    /// The per-meal budget for "Fit my macros": Health remaining when
    /// connected, else the daily target. Nil unless Pro with a goal set.
    private var budget: (macros: Macros, isRemaining: Bool)? {
        guard pro.isPro, let target = profile.target else { return nil }
        if let remaining = health.remaining(against: target) { return (remaining, true) }
        return (target, false)
    }

    /// True when this screen would show a single "Build your own" card and
    /// nothing else — no saved recipes, no published meals, no formats, no
    /// macro-fit. A screen with one destination is a tap that asks nothing, so
    /// it hands straight over to the stations instead. Cane's is the first to
    /// hit this: it is ordered top-down, so its combos ARE the entry point and a
    /// picker in front of them is pure friction.
    private var hasNothingToChoose: Bool {
        loaded && formats.isEmpty && presets.isEmpty && shownSavedMeals.isEmpty
            && restaurant.headlineCategories.isEmpty
            && !(budget.map { MealSolver.canBuild(budget: $0.macros) } ?? false)
    }

    var body: some View {
        Group {
            if hasNothingToChoose {
                MenuView(restaurant: restaurant, format: nil)
            } else {
                picker
            }
        }
        .task {
            formats = (try? await menuRepository.loadFormats(restaurantId: restaurant.id)) ?? []
            let loadedPresets = (try? await menuRepository.loadPresets(restaurantId: restaurant.id)) ?? []
            // A preset whose lines no longer all resolve would show macros that
            // undercount the real order — drop it rather than mislead.
            presets = loadedPresets
                .filter { $0.isComplete(in: restaurant) }
                .map {
                    ResolvedPreset(
                        preset: $0,
                        lineItems: $0.lineItems(in: restaurant),
                        macros: $0.macros(in: restaurant)
                    )
                }
            loaded = true
        }
    }

    private var picker: some View {
        ZStack {
            Backdrop(tint: restaurant.style.hue, intensity: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                    masthead
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.sm)

                    if let budget, MealSolver.canBuild(budget: budget.macros) {
                        NavigationLink(value: MenuRoute(restaurant: restaurant, format: nil, autoBuild: true)) {
                            fitMyMacrosCard(isRemaining: budget.isRemaining, calories: budget.macros.calories)
                        }
                        .buttonStyle(.pressable)
                        .entrance(0)
                        .padding(.bottom, Spacing.xs)
                    }

                    if !shownSavedMeals.isEmpty {
                        sectionLabel("Your recipes")
                        ForEach(Array(shownSavedMeals.enumerated()), id: \.element.id) { index, recipe in
                            NavigationLink(value: MenuRoute(
                                restaurant: restaurant, format: nil, seed: recipe.lineItems
                            )) {
                                CompleteMealCard(
                                    name: recipe.name,
                                    itemCount: recipe.lineItems.count,
                                    macros: recipe.totalMacros,
                                    symbol: "bookmark.fill",
                                    hue: .volt
                                )
                            }
                            .buttonStyle(.pressable)
                            .entrance(savedMealsEntranceBase + index)
                        }
                    }

                    if !headlineSections.isEmpty {
                        ForEach(headlineSections, id: \.category.id) { section in
                            sectionLabel(section.category.name)
                            ForEach(Array(section.groups.enumerated()), id: \.element.id) { index, group in
                                NavigationLink(value: MenuRoute(
                                    restaurant: restaurant, format: nil,
                                    configureItemId: group.defaultMember.id
                                )) {
                                    CompleteMealCard(
                                        name: group.displayName,
                                        blurb: headlineBlurb(group),
                                        itemCount: 0,
                                        macros: group.defaultMember.macros,
                                        symbol: "fork.knife",
                                        hue: restaurant.style.hue
                                    )
                                }
                                .buttonStyle(.pressable)
                                .entrance(headlineEntranceBase + index)
                            }
                        }
                    }

                    if !presets.isEmpty {
                        sectionLabel("On the menu")
                        ForEach(Array(presets.enumerated()), id: \.element.id) { index, resolved in
                            NavigationLink(value: MenuRoute(
                                restaurant: restaurant, format: nil, seed: resolved.lineItems
                            )) {
                                CompleteMealCard(
                                    name: resolved.preset.name,
                                    blurb: resolved.preset.blurb,
                                    itemCount: resolved.lineItems.count,
                                    macros: resolved.macros,
                                    symbol: "star.fill",
                                    hue: restaurant.style.hue
                                )
                            }
                            .buttonStyle(.pressable)
                            .entrance(presetsEntranceBase + index)
                        }
                    }

                    if !formats.isEmpty { sectionLabel("Build to order") }
                    ForEach(Array(formats.enumerated()), id: \.element.id) { index, format in
                        NavigationLink(value: MenuRoute(restaurant: restaurant, format: format)) {
                            FormatCard(format: format, hue: restaurant.style.hue)
                        }
                        .buttonStyle(.pressable)
                        .entrance(formatsEntranceBase + index)
                    }

                    NavigationLink(value: MenuRoute(restaurant: restaurant, format: nil)) {
                        BuildYourOwnCard(browsing: !headlineSections.isEmpty)
                    }
                    .buttonStyle(.pressable)
                    .entrance(formatsEntranceBase + formats.count)
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.md)
            }
            .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // The entrance stagger runs continuously down the page, so each section's
    // base is simply what came before it (0 is the masthead / Fit my macros).
    private var savedMealsEntranceBase: Int { 1 }
    private var headlineEntranceBase: Int { savedMealsEntranceBase + shownSavedMeals.count }

    /// The stations that hold whole orderable things, collapsed by size so a
    /// drink in four cups is one card. Empty for assembly restaurants, which
    /// offer formats instead.
    private var headlineSections: [(category: MenuCategory, groups: [SizeGroup])] {
        restaurant.headlineCategories.map { ($0, $0.sizeGroups()) }
    }

    /// What a headline card says under its name: the serving as the restaurant
    /// prints it, plus the number of cups when there's a choice. Deliberately not
    /// a component count — "13 items" on a Box Combo counted the things you could
    /// toggle, which is not a fact about the combo.
    private func headlineBlurb(_ group: SizeGroup) -> String {
        let serving = group.defaultMember.servingDescription
        guard group.hasChoices else { return serving }
        return "\(serving) · \(group.members.count) sizes"
    }

    private var presetsEntranceBase: Int { headlineEntranceBase + headlineSections.reduce(0) { $0 + $1.groups.count } }
    private var formatsEntranceBase: Int { presetsEntranceBase + presets.count }

    /// "High protein · no sauces" — the active auto-build settings in one line.
    private var autoBuildSummary: String {
        let prefs = settings.autoBuild
        let exclusions = prefs.exclusions
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0 == .sauces ? "no sauces" : $0.title.lowercased() }
        return ([prefs.focus.title] + exclusions).joined(separator: " · ")
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .microLabelStyle(.textTertiary)
            .padding(.top, Spacing.sm)
            .padding(.leading, Spacing.xs)
            .accessibilityAddTraits(.isHeader)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("How are you ordering?")
                .microLabelStyle(restaurant.style.hue)
            Text(restaurant.name)
                .displayXLStyle()
        }
        .entrance(0)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func fitMyMacrosCard(isRemaining: Bool, calories: Double) -> some View {
        Card(highlight: .volt) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.volt)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.volt.opacity(0.12)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fit my macros")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(isRemaining
                         ? "Build for your ~\(Int(calories.rounded())) kcal left today"
                         : "Build toward your daily target")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    // Surface the standing preference here so it's obvious what
                    // the button is about to do — it's set once in Settings and
                    // then easy to forget.
                    Text(autoBuildSummary)
                        .font(.appCaption)
                        .foregroundStyle(.volt)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fit my macros. Auto-builds a meal for your budget.")
    }
}

/// A meal that's already complete — a saved recipe or a published preset. The
/// macros are the point: they're known before the tap, so they get the same
/// inline `MacroBar` treatment the Recipes tab uses. Tapping lands in the tray,
/// where it's logged as-is or edited.
private struct CompleteMealCard: View {
    let name: String
    var blurb: String? = nil
    let itemCount: Int
    let macros: Macros
    let symbol: String
    let hue: Color

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hue)
                    .frame(width: 46, height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .fill(hue.opacity(0.14))
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    // Branch rather than `blurb ?? "…"`: the coalesce produces a
                    // String, which selects `Text(verbatim:)` and renders the
                    // inflection markup literally — "^[13 item](inflect: true)"
                    // on screen. Only a bare literal reaches `LocalizedStringKey`.
                    Group {
                        if let blurb {
                            Text(blurb)
                        } else {
                            Text("^[\(itemCount) item](inflect: true)")
                        }
                    }
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    MacroBar(macros: macros, style: .inline)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(ExportService.summaryLine(macros))")
        .accessibilityHint("Opens in your tray, ready to log or edit")
    }
}

/// One order format: hue tile, name, and a one-line "what it is".
private struct FormatCard: View {
    let format: OrderFormat
    let hue: Color

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(hue.opacity(0.16))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Circle().fill(hue).frame(width: 11, height: 11)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(format.name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(format.blurb)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(format.name). \(format.blurb)")
    }
}

/// The escape hatch — the full flat station list, no guidance. Rendered
/// quieter than the format cards so it reads as "advanced".
private struct BuildYourOwnCard: View {
    /// True when the screen already lists the menu above this card, so the card
    /// is an escape hatch to sides, drinks and sauces rather than the only way in.
    var browsing = false

    private var title: String { browsing ? "Browse the full menu" : "Build your own" }
    private var subtitle: String {
        browsing ? "Sides, drinks, sauces and everything else" : "Start from the full station list"
    }

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                    .frame(width: 46, height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                                    .strokeBorder(Color.hairline, lineWidth: 1)
                            }
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle.lowercased())")
    }
}
