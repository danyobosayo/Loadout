import SwiftUI

/// The builder — stations as chapters (CategoryRail), tappable item
/// rows with ½ / + / − portion controls, live-ticking tray bar
/// floating above the tab bar.
///
/// Rail ↔ scroll sync is deliberately one-directional in each role:
/// `onScrollTargetVisibilityChange` *reads* the visible station into
/// `railSelection`, and `scrollTarget` *writes* a rail tap into the scroll
/// view. They are never the same piece of state. A two-way
/// `.scrollPosition(id:)` binding looks tidier but re-pins the scroll view
/// whenever the content mutates, so adding an item would yank the list.
/// While a tap-initiated scroll is in flight the read side is muted, so the
/// pill doesn't flicker through every station it passes.
struct MenuView: View {
    let restaurant: Restaurant
    // The order format this build started from, or nil for build-your-own.
    // Drives the guided quick-picks and which stations show as add-ons.
    let format: OrderFormat?
    @State private var store: MealBuilderStore
    @State private var trayPresented: Bool
    @State private var railSelection: String?
    /// Write-only scroll request: set to a station id to scroll there, cleared
    /// as soon as it lands. Kept separate from the rail's read-side sync so
    /// neither can drive the other (see the scroll view's modifiers).
    @State private var scrollTarget: String?
    @State private var railNavigation: Task<Void, Never>?
    @State private var limitToast: String?
    @State private var toastDismissTask: Task<Void, Never>?
    // Which guided prompt is expanded (accordion). Others show a compact
    // summary. Starts on the first prompt and auto-advances as picks land.
    @State private var expandedPrompt: String?
    // In-menu search. Non-empty query swaps the guided/station view for a
    // flat, filtered list across every station — the way to find one item in
    // a 70-item menu without rail-hopping.
    @State private var searchText = ""
    /// The item whose configure sheet is open — a Cane's combo you're taking the
    /// slaw off. Nil for the ordinary tap-to-add path.
    @State private var configuring: ConfigurationTarget?
    /// Which cup is showing for each size group — `sizeGroup` id → `MenuItem` id.
    /// Absent means the group's own default. Held here rather than in the row so
    /// a choice survives the row being rebuilt as the tray changes.
    @State private var sizeChoice: SizeChoice?
    /// Set when the landing screen picked a headline item; opens its configurator
    /// as soon as this view appears, so "what" hands straight to "how".
    private let configureItemId: String?
    /// One-shot. `.task` runs again every time this view reappears, so without
    /// this, dismissing the configurator popped back here and immediately pushed
    /// a fresh one — you could never reach the menu underneath.
    @State private var didRouteConfigurator = false
    /// Size groups, derived once per category.
    ///
    /// `sizeGroups()` is pure derivation over immutable menu data, but the
    /// station list is a plain VStack — every station rebuilds on every body
    /// pass — so calling it inline re-derived every group on every frame, on the
    /// main thread, during scrolling. That pegged the main thread for 30s on
    /// Chipotle. The menu never changes under us; compute it once.
    @State private var sizeGroupCache: [String: [SizeGroup]] = [:]
    @Environment(ProfileStore.self) private var profile
    @Environment(HealthStore.self) private var health
    @Environment(ProStore.self) private var pro
    @Environment(SettingsStore.self) private var settings
    // When set, the builder auto-fills a macro-fitting suggestion on first
    // appear (the "Fit my macros" path); cleared once it runs.
    @State private var autoBuild: Bool

    init(
        restaurant: Restaurant, format: OrderFormat? = nil, seed: [LineItem] = [],
        autoBuild: Bool = false, configureItemId: String? = nil
    ) {
        self.restaurant = restaurant
        self.format = format
        self.configureItemId = configureItemId
        let seededStore = MealBuilderStore(restaurant: restaurant, lineItems: seed, formatName: format?.name)
        // Curated base/vessel items (a burrito's tortilla) seed rule-safe
        // through the normal add path — not the raw lineItems seed, which
        // bypasses rules. Scaled for size formats (Subway Footlong).
        if let format {
            seededStore.seedThroughRules(format.autoAdd, multiplier: format.portionMultiplier)
        }
        _store = State(initialValue: seededStore)
        // Nothing auto-opens the tray any more, seeded or not.
        //
        // A preset or saved recipe used to land straight in the tray, which read
        // as "done, log it" — while every other route lands somewhere you adjust
        // first. Screen 2 answers "how do you want it?" for everything: a seeded
        // meal arrives in the builder with its items already in, the tray bar
        // showing the running total, and the tray one tap away when you're ready.
        _trayPresented = State(initialValue: false)
        _railSelection = State(initialValue:
            Self.stationCategories(restaurant: restaurant, format: format).first?.id)
        _expandedPrompt = State(initialValue: format?.prompts.first?.id)
        _autoBuild = State(initialValue: autoBuild)
    }

    /// Route-driven entry from the landing screen.
    init(route: MenuRoute) {
        self.init(
            restaurant: route.restaurant,
            format: route.format,
            seed: route.seed,
            autoBuild: route.autoBuild,
            configureItemId: route.configureItemId
        )
    }

    /// The stations shown in the scroll + rail. Guided formats curate this
    /// to their `optionalCategoryIds` (the add-ons after the guided picks);
    /// build-your-own shows every station. One ordered array feeds BOTH the
    /// rail and the scroll `ForEach`, so rail↔scroll sync stays correct.
    static func stationCategories(restaurant: Restaurant, format: OrderFormat?) -> [MenuCategory] {
        guard let format else { return restaurant.orderableCategories }
        return format.optionalCategoryIds.compactMap { restaurant.category(id: $0) }
    }

    private var stationCategories: [MenuCategory] {
        Self.stationCategories(restaurant: restaurant, format: format)
    }

    /// Budget Mode context for the tray bar — how the meal-in-progress fits the
    /// day. Nil when no goal is set.
    private var budgetFit: BudgetFit? {
        guard pro.isPro else { return nil }               // Budget Mode is Pro
        let target = profile.target
        let remaining = target.flatMap { health.remaining(against: $0) }
        return BudgetFit.make(meal: store.totalMacros, target: target, remaining: remaining)
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmedQuery.isEmpty }

    /// Every station's items filtered by the query (name or serving), across
    /// the *whole* menu — guided-prompt items included — so search finds
    /// anything. Each result keeps its real category so taps resolve the right
    /// portion policy and cap. Empty categories drop out.
    private var searchResults: [(category: MenuCategory, matches: [MenuItem])] {
        let q = trimmedQuery.lowercased()
        return restaurant.orderableCategories.compactMap { category in
            let matches = category.items.filter {
                $0.name.lowercased().contains(q)
                    || $0.servingDescription.lowercased().contains(q)
            }
            return matches.isEmpty ? nil : (category, matches)
        }
    }

    var body: some View {
        ZStack {
            Backdrop(tint: restaurant.style.hue, intensity: 0.12)
            stationList
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                searchField
                // The rail is for chapter-hopping the full menu — irrelevant
                // once the list is filtered to a handful of matches.
                if !isSearching {
                    CategoryRail(
                        categories: stationCategories,
                        selection: railSelection,
                        hue: restaurant.style.hue,
                        onTap: jump(to:)
                    )
                }
            }
            .background(Color.void)
        }
        .overlay(alignment: .bottom) {
            trayBar
                .padding(.bottom, Metrics.tabBarClearance)
        }
        .overlay(alignment: .top) {
            if let limitToast {
                toast(limitToast)
            }
        }
        .sheet(isPresented: $trayPresented) {
            MealTrayView(store: store, format: format)
        }
        .sheet(item: $sizeChoice) { choice in
            SizeChoiceSheet(
                group: choice.group,
                accent: restaurant.category(id: choice.categoryId)?.style.accent ?? .volt,
                quantityFor: { store.quantity(forMenuItemId: $0.id) }
            ) { picked in
                guard let category = restaurant.category(id: choice.categoryId) else { return }
                if picked.isConfigurable {
                    let current = choice.group.members.first {
                        store.quantity(forMenuItemId: $0.id) > 0
                    }
                    let line = current.flatMap { current in
                        store.lineItems.first { $0.menuItemId == current.id }
                    }
                    Haptics.tap()
                    configuring = ConfigurationTarget(
                        item: picked,
                        category: category,
                        lineItemId: line?.id,
                        configuration: line?.configuration ?? .unchanged
                    )
                    return
                }
                withAnimation(Motion.snap) {
                    // Switching size on something already in the tray moves the
                    // line rather than leaving both cups on the order.
                    if let current = choice.group.members.first(where: { store.quantity(forMenuItemId: $0.id) > 0 }),
                       current.id != picked.id,
                       let line = store.lineItems.first(where: { $0.menuItemId == current.id }) {
                        let quantity = line.quantity
                        store.remove(lineItemId: line.id)
                        store.add(picked, in: category, quantity: quantity)
                    } else {
                        apply(store.applyPortionTap(picked, in: category), in: category)
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(Radius.sheet)
            .presentationBackground(Color.void)
            .presentationDragIndicator(.visible)
        }
        // Pushed, not presented: this is screen 2, the same slot the station
        // builder occupies for an assembly restaurant. The size sheet below
        // stays a sheet — picking which cup is a sub-decision, not a build.
        .navigationDestination(item: $configuring) { target in
            ConfigureItemScreen(
                item: target.item,
                category: target.category,
                restaurant: restaurant,
                accent: target.category.style.accent,
                editing: target.lineItemId,
                initialConfiguration: target.configuration
            ) { configuration in
                withAnimation(Motion.snap) {
                    apply(
                        store.addConfigured(
                            target.item, in: target.category,
                            configuration: configuration,
                            replacing: target.lineItemId
                        ),
                        in: target.category
                    )
                }
            }
        }
        .task {
            sizeGroupCache = Dictionary(
                uniqueKeysWithValues: restaurant.categories.map { ($0.id, $0.sizeGroups()) }
            )
            openConfiguratorIfRouted()
            runAutoBuild()
        }
    }

    /// "Fit my macros": solve for the user's budget and drop the suggestion into
    /// the tray, editable. Runs once, on entry, only when routed with autoBuild.
    private func runAutoBuild() {
        guard autoBuild, pro.isPro, store.isEmpty, let target = profile.target else { autoBuild = false; return }
        let budget = health.remaining(against: target) ?? target
        if let suggestion = MealSolver.solve(
            restaurant: restaurant, budget: budget, preferences: settings.autoBuild
        ) {
            withAnimation(Motion.snap) { store.replace(with: suggestion.lineItems) }
            Haptics.success()
            trayPresented = true
        }
        autoBuild = false
    }

    // MARK: Stations

    private var stationList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if isSearching {
                        searchResultsView
                    } else {
                        if let format, !format.prompts.isEmpty {
                            guidedSection(format)
                            if !stationCategories.isEmpty {
                                addOnsHeader
                            }
                        }
                        // Only the stations are scroll targets — the guided
                        // section above scrolls with the content but never
                        // drives the rail.
                        LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                            ForEach(stationCategories) { category in
                                stationSection(category)
                                    .id(category.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            }
            .contentMargins(.bottom, Metrics.tabBarClearance + Metrics.trayBarClearance, for: .scrollContent)
            // Scroll → rail sync, muted while a tap navigation is in flight so
            // the target pill doesn't flash back.
            //
            // Read-only on purpose. This used to be
            // `.scrollPosition(id: $scrolledStation, anchor: .top)`, but that
            // binding *also writes back into the scroll view*: any content
            // mutation re-applied it and re-pinned the tracked station to the
            // top. Tapping an item grows its row, so the first tap in a station
            // yanked the list down mid-browse.
            .onScrollTargetVisibilityChange(idType: String.self, threshold: 0.1) { visible in
                guard railNavigation == nil, let top = visible.first else { return }
                withAnimation(Motion.snap) { railSelection = top }
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(Motion.glide) { proxy.scrollTo(target, anchor: .top) }
                // Cleared so tapping the same rail pill twice scrolls again.
                scrollTarget = nil
            }
            .onChange(of: expandedPrompt) { _, prompt in
                // Expanding a prompt grows its options; pull it to the top so
                // the choices are in view instead of scrolled off the bottom.
                guard let prompt else { return }
                withAnimation(Motion.snap) { proxy.scrollTo(prompt, anchor: .top) }
            }
        }
    }

    /// A station's header + rows. `displayItems` narrows which rows show (the
    /// search subset) while the policy/cap still reason over the *real*
    /// category, so a filtered dips list still caps correctly.
    private func stationSection(_ category: MenuCategory, items displayItems: [MenuItem]? = nil) -> some View {
        let policy = category.portionPolicy
        let scoopCapReached: Bool = {
            if case .cappedScoops(let max) = policy {
                return store.totalQuantity(in: category) >= Double(max)
            }
            return false
        }()

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(category.style.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(category.style.accent)
                    .frame(width: 28, height: 28)
                    .background(category.style.accent.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
                Text(headerText(for: category))
                    .microLabelStyle()
            }

            VStack(spacing: Spacing.sm) {
                // One row per *dish*, not per size. A latte in four cups is one
                // row with a picker; Starbucks was 427 rows that were ~100 drinks.
                ForEach(sizeGroups(for: category, items: displayItems)) { group in
                    let item = shownMember(of: group)
                    let quantity = store.quantity(forMenuItemId: item.id)
                    MenuItemRow(
                        item: item,
                        accent: category.style.accent,
                        quantity: quantity,
                        policy: policy,
                        isDisabled: scoopCapReached && quantity == 0,
                        dietary: item.verdict(for: settings.autoBuild.restrictions),
                        sizes: group.hasChoices ? group.members : [],
                        displayName: group.hasChoices ? group.displayName : item.name,
                        onTap: {
                            if group.hasChoices {
                                Haptics.tap()
                                sizeChoice = SizeChoice(group: group, categoryId: category.id)
                            } else {
                                tapStation(item, in: category)
                            }
                        },
                        onDecrement: { decrementStation(item) }
                    )
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.textTertiary)
            TextField("Search \(restaurant.name)", text: $searchText)
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .tint(restaurant.style.hue)
            if !searchText.isEmpty {
                Button {
                    Haptics.tap()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    @ViewBuilder
    private var searchResultsView: some View {
        let results = searchResults
        if results.isEmpty {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.textTertiary)
                Text("No matches for “\(trimmedQuery)”")
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 72)
        } else {
            ForEach(results, id: \.category.id) { result in
                stationSection(result.category, items: result.matches)
            }
        }
    }

    /// Push the configurator for an item chosen on the landing screen. The menu
    /// stays underneath in the stack, so backing out lands on the full station
    /// list — a reasonable "actually, show me everything" affordance.
    private func openConfiguratorIfRouted() {
        guard !didRouteConfigurator,
              let configureItemId,
              let resolved = restaurant.resolve(menuItemId: configureItemId)
        else { return }
        didRouteConfigurator = true
        configuring = ConfigurationTarget(item: resolved.item, category: resolved.category)
    }

    /// Cached for the full station list; derived on the spot for a search
    /// subset, which is a handful of rows rather than the whole menu.
    private func sizeGroups(for category: MenuCategory, items: [MenuItem]?) -> [SizeGroup] {
        guard items == nil else { return category.sizeGroups(from: items) }
        return sizeGroupCache[category.id] ?? category.sizeGroups()
    }

    /// The size the row shows: whatever's already in the tray, so a Venti you
    /// added reads back as a Venti — otherwise the cup you'd get by saying
    /// nothing. Picking a different one happens in the sheet.
    private func shownMember(of group: SizeGroup) -> MenuItem {
        if let inTray = group.members.first(where: { store.quantity(forMenuItemId: $0.id) > 0 }) {
            return inTray
        }
        return group.defaultMember
    }

    private func headerText(for category: MenuCategory) -> String {
        switch category.portionPolicy {
        case .splitBase: "\(category.name) · tap two to split"
        case .cappedScoops(let max): "\(category.name) · up to \(max)"
        case .freeAddOns: category.name
        }
    }

    // MARK: Rail navigation

    private func jump(to stationId: String) {
        railNavigation?.cancel()
        withAnimation(Motion.snap) { railSelection = stationId }
        scrollTarget = stationId
        railNavigation = Task {
            // Hold the rail-sync mute until the programmatic scroll settles,
            // so the pill doesn't flicker through every station it passes.
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            railNavigation = nil
        }
    }

    // MARK: Portion actions

    /// One tap on a station row, resolved by the station's `PortionPolicy`:
    /// cycle full → ×2 → off, an auto ½ + ½ split, or capped scoops.
    private func tapStation(_ item: MenuItem, in category: MenuCategory) {
        // An item that arrives already built opens for configuration instead of
        // dropping straight into the tray — a Box Combo is a starting point, not
        // a finished line. Everything else keeps the tap-to-cycle behaviour.
        guard !item.isConfigurable else {
            Haptics.tap()
            configuring = ConfigurationTarget(item: item, category: category)
            return
        }
        withAnimation(Motion.snap) {
            apply(store.applyPortionTap(item, in: category), in: category)
        }
    }

    /// The counter policies' − control: reduce a topping/scoop by one without
    /// opening the tray.
    private func decrementStation(_ item: MenuItem) {
        Haptics.tap()
        withAnimation(Motion.snap) { store.decrementPortion(item) }
    }

    private func apply(_ outcome: MealBuilderStore.AddOutcome, in category: MenuCategory) {
        switch outcome {
        case .added, .incremented, .replaced:
            Haptics.tap()
        case .rejectedByLimit(let max):
            Haptics.warning()
            showToast("\(category.name): choose up to \(max)")
        }
    }

    // MARK: Toast

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        withAnimation(Motion.snap) { limitToast = message }
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.snap) { limitToast = nil }
        }
    }

    private func toast(_ message: String) -> some View {
        Text(message)
            .font(.appCaption.weight(.semibold))
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background {
                Capsule()
                    .fill(Color.surfaceElevated)
                    .overlay(Capsule().strokeBorder(Color.overTarget.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
            }
            .padding(.top, Spacing.sm)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Tray bar

    private var trayBar: some View {
        Button {
            Haptics.tap()
            trayPresented = true
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(store.totalMacros.calories, format: .number.precision(.fractionLength(0)))
                            .font(.numeralLarge)
                            .foregroundStyle(.textPrimary)
                            .contentTransition(.numericText(value: store.totalMacros.calories))
                            .animation(Motion.snap, value: store.totalMacros.calories)
                        Text("kcal")
                            .microLabelStyle(.kcal)
                    }
                    if !store.isEmpty {
                        MacroSegmentBar(macros: store.totalMacros)
                            .frame(width: 120)
                        if let fit = budgetFit {
                            Text(fit.fitsCalories
                                 ? "\(Int(fit.caloriesLeftAfter.rounded())) kcal left"
                                 : "over by \(Int(-fit.caloriesLeftAfter.rounded()))")
                                .font(.system(size: 10, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(fit.fitsCalories ? Color.volt : Color.fat)
                        }
                    }
                }

                Spacer(minLength: Spacing.sm)

                if store.isEmpty {
                    Text("Tap items to build")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                } else {
                    HStack(spacing: Spacing.xs) {
                        Text("^[\(store.totalLineItemCount) item](inflect: true)")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.textSecondary)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.volt)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Color.surfaceElevated)
                    .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
            }
            // A quick pulse each time an item lands, so the tap visibly
            // "goes in the bag."
            .keyframeAnimator(initialValue: 1.0, trigger: store.totalLineItemCount) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.05, duration: 0.12)
                    CubicKeyframe(1.0, duration: 0.20)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(trayAccessibilityLabel)
        .accessibilityHint("Opens your meal to edit portions, save, or export.")
    }

    private var trayAccessibilityLabel: String {
        if store.isEmpty { return "Meal tray. Empty." }
        return "Meal tray. \(store.totalLineItemCount) items. \(Int(store.totalMacros.calories.rounded())) calories total."
    }
}

// MARK: - Item row

/// A station row. `splitBase` stations cycle (tap → full → ×2 → off, tap a
/// second to split); counter stations (`cappedScoops` / `freeAddOns`) tap to
/// add and show an inline − with a live count so a misclick doesn't need the
/// tray.
private struct MenuItemRow: View {
    let item: MenuItem
    let accent: Color
    let quantity: Double
    let policy: PortionPolicy
    let isDisabled: Bool
    /// How this item sits against the user's dietary restrictions. Shown, never
    /// enforced — the menu marks a conflict and still lets you tap it, because
    /// only the person ordering knows how strict their rule is today.
    var dietary: DietaryVerdict = .allowed
    /// The cups this dish comes in. Empty for anything sold one way, which is
    /// most of the menu — the picker only appears where there's a real choice.
    var sizes: [MenuItem] = []
    /// The dish's name with the size stripped, so the row reads "Caffè Latte"
    /// and the chips say which cup.
    var displayName: String?
    let onTap: () -> Void
    let onDecrement: () -> Void

    private var isInMeal: Bool { quantity > 0 }
    private var isHalf: Bool { abs(quantity - 0.5) < 0.001 }

    var body: some View {
        Group {
            if policy.isCounter { counterRow } else { cycleRow }
        }
        .animation(Motion.snap, value: quantity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isInMeal ? [.isSelected] : [])
    }

    // splitBase: the whole card cycles.
    private var cycleRow: some View {
        Button(action: onTap) {
            Card(padding: Spacing.sm + Spacing.xs, highlight: isInMeal ? accent : nil) {
                HStack(spacing: Spacing.md) {
                    rowContent
                    if let label = cycleBadge {
                        Text(label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(isHalf ? accent : Color.void)
                            .frame(minWidth: 30, minHeight: 28)
                            .padding(.horizontal, 7)
                            .background {
                                if isHalf {
                                    Capsule().strokeBorder(accent, lineWidth: 1.5)
                                } else {
                                    Capsule().fill(accent)
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .buttonStyle(.pressable)
    }

    // counter: tap the row to +1, − to reduce, live count.
    private var counterRow: some View {
        Card(padding: Spacing.sm + Spacing.xs, highlight: isInMeal ? accent : nil) {
            HStack(spacing: Spacing.md) {
                Button(action: onTap) {
                    rowContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(isDisabled)

                if isInMeal {
                    CounterStepper(count: Int(quantity.rounded()), accent: accent, onDecrement: onDecrement)
                }
            }
        }
        .opacity(isDisabled && !isInMeal ? 0.4 : 1)
    }

    private var rowContent: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(isInMeal ? accent : accent.opacity(0.35))
                .frame(width: 8, height: 8)
                .animation(Motion.snap, value: isInMeal)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text(displayName ?? item.name)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                        .layoutPriority(1)          // the name never gives way
                    Spacer(minLength: 0)
                    // Serving size yields first: "Rosemary Parmesan Bread" and
                    // "1 Regular sub roll" would otherwise meet in the middle
                    // and run to both edges.
                    sizeControl
                }
                MacroStrip(macros: item.macros)
                if dietary != .allowed { dietaryNote }
            }
        }
    }

    /// The serving size — a plain label when a dish is sold one way, a menu when
    /// it isn't.
    ///
    /// Deliberately *replaces* the serving text instead of adding a chip row
    /// beneath it. An extra row inside every card changed the row's shape, and
    /// with it the layout and accessibility tree of the whole station list: UI
    /// queries against Chipotle's toppings went from 29 seconds to timing out at
    /// 190, and it made no difference whether the chips were buttons or plain
    /// text. One control, in space the row already had, costs nothing.
    /// The serving line, with a hint when the dish comes in more than one size.
    ///
    /// Deliberately NOT an interactive control. Both row shapes wrap their
    /// content in a Button, so a Menu or a chip placed here can never receive a
    /// tap — the row swallows it — and giving the row a second shape to make
    /// room for one turned unrelated UI queries from 29 seconds into 190-second
    /// timeouts. The row stays exactly as it was; picking a size opens a sheet.
    private var sizeControl: some View {
        HStack(spacing: 3) {
            Text(item.servingDescription)
                .lineLimit(1)
                .truncationMode(.tail)
            if sizes.count > 1 {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
            }
        }
        .font(.appCaption)
        .foregroundStyle(sizes.count > 1 ? accent : Color.textTertiary)
    }

    @ViewBuilder
    private var dietaryNote: some View {
        let excluded = dietary == .excluded
        HStack(spacing: 4) {
            Image(systemName: excluded ? "exclamationmark.triangle.fill" : "questionmark.circle")
                .font(.system(size: 9, weight: .bold))
            Text(excluded ? "Doesn't fit your diet settings" : "Not checked for your diet settings")
                .font(.appCaption)
        }
        .foregroundStyle(excluded ? Color.overTarget : Color.textTertiary)
    }

    /// splitBase badge: ½ / ×2; a plain full portion is just the filled dot.
    private var cycleBadge: String? {
        guard isInMeal else { return nil }
        if isHalf { return "½" }
        if abs(quantity - 2) < 0.001 { return "×2" }
        if abs(quantity - 1) < 0.001 { return nil }
        return "×\(quantity.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var accessibilityText: String {
        // servingDescription stays in here explicitly: when the size picker is a
        // Menu, its text no longer folds into the container's combined label.
        var parts = [displayName ?? item.name, item.servingDescription,
                     "\(Int(item.macros.calories.rounded())) calories"]
        switch dietary {
        case .excluded: parts.append("does not fit your diet settings")
        case .unknown:  parts.append("not checked for your diet settings")
        case .allowed:  break
        }
        if isHalf { parts.append("half portion") }
        else if policy.isCounter, isInMeal { parts.append("\(Int(quantity.rounded())) in meal") }
        else if isInMeal { parts.append("\(quantity.formatted()) in meal") }
        return parts.joined(separator: ", ")
    }

    private var accessibilityHint: String {
        if isDisabled { return "At the limit. Remove another to add this." }
        switch policy {
        case .splitBase: return "Tap to add. Tap again to double, or tap another to split half and half."
        case .cappedScoops: return "Tap to add one; use minus to reduce."
        case .freeAddOns: return "Tap to add one; use minus to reduce."
        }
    }
}

/// The inline − [count] control shared by counter rows (stations + guided).
private struct CounterStepper: View {
    let count: Int
    let accent: Color
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .fill(accent.opacity(0.12))
                            .overlay(Circle().strokeBorder(accent.opacity(0.5), lineWidth: 1))
                    }
                    .frame(width: 44, height: 44)   // 44pt hit target, 30pt visual
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Remove one")

            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
                .frame(minWidth: 16)
                .contentTransition(.numericText(value: Double(count)))
        }
    }
}

// MARK: - Guided quick-picks (Hybrid entry)

private extension MenuView {
    /// Label separating the guided picks from the optional add-on stations.
    var addOnsHeader: some View {
        HStack(spacing: Spacing.sm) {
            Text("Add anything else")
                .microLabelStyle()
            Rectangle()
                .fill(Color.hairline)
                .frame(height: 1)
        }
        .padding(.top, Spacing.xs)
    }

    /// The guided picks — an accordion of compact rows. One expands at a
    /// time; the rest collapse to a "prompt ▸ your choice" summary with a
    /// pencil. Single-select prompts auto-advance to the next unanswered
    /// step as picks land.
    func guidedSection(_ format: OrderFormat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(format.prompts) { prompt in
                guidedPromptRow(prompt)
                    .id(prompt.id)
            }
        }
    }

    @ViewBuilder
    func guidedPromptRow(_ prompt: FormatPrompt) -> some View {
        let category = restaurant.category(id: prompt.categoryId)
        let expanded = expandedPrompt == prompt.id
        let answered = isAnswered(prompt)

        Card(padding: Spacing.sm + Spacing.xs) {
            VStack(alignment: .leading, spacing: expanded ? Spacing.sm : 0) {
                Button {
                    toggleExpand(prompt)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        stationGlyph(category)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(prompt.promptCopy)
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                            if answered, !expanded {
                                Text(summaryText(for: prompt))
                                    .font(.appCaption)
                                    .foregroundStyle(.volt)
                                    .lineLimit(1)
                            }
                        }
                        if prompt.required, !answered {
                            requiredDot
                        }
                        Spacer(minLength: Spacing.xs)
                        if !answered {
                            Text(chooseHint(prompt))
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                        }
                        Image(systemName: expanded ? "chevron.up" : (answered ? "pencil" : "chevron.down"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(answered && !expanded ? .volt : .textTertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(headerAccessibility(prompt, answered: answered))

                if expanded {
                    Rectangle()
                        .fill(Color.hairline)
                        .frame(height: 1)
                    VStack(spacing: 2) {
                        // Grouped by size, exactly like a station row. Without
                        // this the guided path listed every cup separately —
                        // which is most of Starbucks, since its formats put the
                        // drinks in prompts rather than in optional stations.
                        ForEach(guidedGroups(for: prompt)) { group in
                            let item = shownMember(of: group)
                            GuidedItemRow(
                                item: item,
                                accent: category?.style.accent ?? .textSecondary,
                                quantity: store.quantity(forMenuItemId: item.id),
                                isCounter: promptPolicy(prompt)?.isCounter ?? false,
                                sizeCount: group.members.count,
                                displayName: group.hasChoices ? group.displayName : item.name,
                                onTap: {
                                    if group.hasChoices, let category {
                                        Haptics.tap()
                                        sizeChoice = SizeChoice(group: group, categoryId: category.id)
                                    } else {
                                        pick(item, prompt: prompt)
                                    }
                                },
                                onDecrement: { promptDecrement(item) }
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func stationGlyph(_ category: MenuCategory?) -> some View {
        if let category {
            Image(category.style.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(category.style.accent)
                .frame(width: 28, height: 28)
                .background(category.style.accent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
        }
    }

    var requiredDot: some View {
        Circle()
            .fill(Color.volt)
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    // MARK: Guided data

    /// The items a prompt offers: its subset (in authored order) or, when
    /// `subsetItemIds` is nil, the whole category.
    /// A prompt's offered items, collapsed by size.
    func guidedGroups(for prompt: FormatPrompt) -> [SizeGroup] {
        guard let category = restaurant.category(id: prompt.categoryId) else { return [] }
        return category.sizeGroups(from: guidedItems(for: prompt))
    }

    func guidedItems(for prompt: FormatPrompt) -> [MenuItem] {
        guard let category = restaurant.category(id: prompt.categoryId) else { return [] }
        guard let subset = prompt.subsetItemIds else { return category.items }
        return subset.compactMap { id in category.items.first { $0.id == id } }
    }

    /// The line items currently chosen within a prompt's offered items.
    func guidedSelection(for prompt: FormatPrompt) -> [LineItem] {
        let ids = Set(guidedItems(for: prompt).map(\.id))
        return store.lineItems.filter { ids.contains($0.menuItemId) }
    }

    func isAnswered(_ prompt: FormatPrompt) -> Bool {
        !guidedSelection(for: prompt).isEmpty
    }

    func summaryText(for prompt: FormatPrompt) -> String {
        guidedSelection(for: prompt).map(\.displayName).joined(separator: ", ")
    }

    func chooseHint(_ prompt: FormatPrompt) -> String {
        switch prompt.choose {
        // Surface the half-and-half affordance where most people build —
        // guided rice/grain/bread prompts, not just the station list.
        case .selectOne: return canSplit(prompt) ? "tap 2 to split" : "choose 1"
        case .selectUpTo(let max): return "up to \(max)"
        case .selectMany: return "add any"
        }
    }

    func headerAccessibility(_ prompt: FormatPrompt, answered: Bool) -> String {
        var parts = [prompt.promptCopy]
        if prompt.required { parts.append("required") }
        if answered { parts.append(summaryText(for: prompt)) }
        return parts.joined(separator: ", ")
    }

    /// Tap-to-cycle (with ½ + ½ split) applies to a single full-portion pick
    /// — not tacos (×3), a Footlong (×2), or the CAVA halves (already ½),
    /// which toggle at their set quantity instead.
    func canSplit(_ prompt: FormatPrompt) -> Bool {
        guard prompt.allowsSplit else { return false }
        guard case .selectOne = prompt.choose else { return false }
        return prompt.quantityPerPick == 1 && (format?.portionMultiplier ?? 1) == 1
    }

    // MARK: Guided actions

    func toggleExpand(_ prompt: FormatPrompt) {
        Haptics.tap()
        withAnimation(Motion.snap) {
            expandedPrompt = (expandedPrompt == prompt.id) ? nil : prompt.id
        }
    }

    /// A guided pick. "Choose one" prompts holding a single full portion (not
    /// tacos ×3 or a Footlong) use the same tap-to-cycle model as the stations
    /// — tap to add, again to double, or tap another to split ½ + ½ within the
    /// prompt's subset. Everything else toggles at its set quantity.
    ///
    /// The prompt only closes once it's *saturated* — a "choose 2 entrées"
    /// waits for the second tap. Anything short of that leaves it open so
    /// portions stay adjustable.
    func pick(_ item: MenuItem, prompt: FormatPrompt) {
        guard let category = restaurant.category(id: prompt.categoryId) else { return }
        let scope = prompt.subsetItemIds.map(Set.init)

        if let policy = promptPolicy(prompt) {
            Haptics.tap()
            withAnimation(Motion.snap) {
                apply(store.applyPortionTap(item, in: category, policy: policy, scope: scope), in: category)
            }
        } else if let line = store.lineItems.first(where: { $0.menuItemId == item.id }) {
            Haptics.tap()
            withAnimation(Motion.snap) { store.setQuantity(lineItemId: line.id, to: 0) }
        } else {
            let quantity = prompt.quantityPerPick * (format?.portionMultiplier ?? 1)
            withAnimation(Motion.snap) {
                apply(store.add(item, in: category, quantity: quantity, ruleOverride: prompt.choose, within: scope), in: category)
            }
        }

        if isSaturated(prompt) { advance(past: prompt) }
    }

    /// Whether a prompt has taken everything it can hold.
    ///
    /// Only a real cap counts. A `selectOne` base can still be doubled or split
    /// ½ + ½ after its first tap, so it is never saturated — closing it on the
    /// first tap is exactly the behaviour that made portions unadjustable and
    /// got auto-advance removed once already. Fixed-quantity picks (tacos ×3, a
    /// Footlong loaf) can't be adjusted in place, so one pick completes them.
    func isSaturated(_ prompt: FormatPrompt) -> Bool {
        guard let category = restaurant.category(id: prompt.categoryId) else { return false }
        switch prompt.choose {
        case .selectUpTo(let max):
            let scope = prompt.subsetItemIds.map(Set.init)
            return store.totalQuantity(in: category, scope: scope) >= Double(max)
        case .selectOne:
            return !canSplit(prompt) && isAnswered(prompt)
        case .selectMany:
            return false                      // uncapped: the user says when
        }
    }

    /// Collapse the finished prompt and open the next unanswered one. When
    /// every prompt is answered nothing expands, which drops the accordion to
    /// its compact summaries and brings the add-on stations up into view.
    func advance(past prompt: FormatPrompt) {
        guard let format,
              let index = format.prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        let next = format.prompts[(index + 1)...].first { !isAnswered($0) }
        withAnimation(Motion.snap) { expandedPrompt = next?.id }
    }

    /// The `PortionPolicy` a prompt's `choose` implies, so the guided rows use
    /// the same tap model as the stations: choose-one → splitBase (tap-cycle +
    /// split), up-to-N → capped counter, many → free counter. Returns nil for
    /// fixed-quantity picks (tacos ×3, Footlong ×2, CAVA halves) which just
    /// toggle at their set quantity.
    func promptPolicy(_ prompt: FormatPrompt) -> PortionPolicy? {
        switch prompt.choose {
        case .selectOne:            return canSplit(prompt) ? .splitBase : nil
        case .selectUpTo(let max):  return .cappedScoops(max: max)
        case .selectMany:           return .freeAddOns
        }
    }

    func promptDecrement(_ item: MenuItem) {
        Haptics.tap()
        withAnimation(Motion.snap) { store.decrementPortion(item) }
    }
}

// MARK: - Guided item row

/// A single guided choice inside the prompt accordion (chromeless — the card
/// is the surface). Mirrors the stations: `splitBase`-style prompts show a
/// radio + ½/×2 badge and cycle on tap; counter prompts (up-to-N, many) tap
/// to add and show an inline − with a live count.
private struct GuidedItemRow: View {
    let item: MenuItem
    let accent: Color
    let quantity: Double
    let isCounter: Bool
    /// How many cups this drink comes in. >1 means the row opens a size sheet
    /// instead of picking outright.
    var sizeCount: Int = 1
    var displayName: String?
    let onTap: () -> Void
    let onDecrement: () -> Void

    private var isSelected: Bool { quantity > 0 }
    private var isHalf: Bool { abs(quantity - 0.5) < 0.001 }
    private var hasSizes: Bool { sizeCount > 1 }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: onTap) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? accent : Color.hairline, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if isSelected {
                            Circle().fill(accent).frame(width: 12, height: 12)
                        }
                    }
                    .animation(Motion.snap, value: isSelected)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(displayName ?? item.name)
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                                .lineLimit(2)
                            Spacer(minLength: Spacing.xs)
                            HStack(spacing: 3) {
                                Text(item.servingDescription)
                                    .lineLimit(1)
                                if hasSizes {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8, weight: .bold))
                                }
                            }
                            .font(.appCaption)
                            .foregroundStyle(hasSizes ? accent : Color.textTertiary)
                        }
                        MacroStrip(macros: item.macros)
                    }

                    if !isCounter, let label = badgeLabel {
                        Text(label)
                            .font(.numeral)
                            .foregroundStyle(accent)
                    }
                }
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.pressable)

            if isCounter, isSelected {
                CounterStepper(count: Int(quantity.rounded()), accent: accent, onDecrement: onDecrement)
            }
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.xs)
        .background {
            // No container border here: guided rows sit joined under one prompt
            // header, so the filled radio (+ a faint tint) carries selection —
            // a per-row border would fight that grouped look.
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(isSelected ? accent.opacity(0.08) : Color.clear)
        }
        .animation(Motion.snap, value: quantity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var badgeLabel: String? {
        guard isSelected, abs(quantity - 1) > 0.001 else { return nil }
        if isHalf { return "½" }
        return "×\(quantity.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var accessibilityText: String {
        var parts = [displayName ?? item.name, item.servingDescription,
                     "\(Int(item.macros.calories.rounded())) calories"]
        if hasSizes { parts.append("\(sizeCount) sizes") }
        if isSelected { parts.append(isCounter ? "\(Int(quantity.rounded())) selected" : "selected") }
        return parts.joined(separator: ", ")
    }
}
