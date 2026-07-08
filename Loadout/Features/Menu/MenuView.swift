import SwiftUI

/// The builder — stations as chapters (CategoryRail), tappable item
/// rows with ½ / + / − portion controls, live-ticking tray bar
/// floating above the tab bar.
///
/// Rail ↔ scroll sync: `railSelection` (what the pill shows) is
/// deliberately separate from `scrolledStation` (the scroll binding).
/// While a tap-initiated scroll is in flight, scroll-position updates
/// are ignored so mid-deceleration taps can't be overwritten — and the
/// programmatic write is re-asserted once, because a write issued
/// during deceleration can be swallowed by the scroll view's own
/// position stream.
struct MenuView: View {
    let restaurant: Restaurant
    // The order format this build started from, or nil for build-your-own.
    // Drives the guided quick-picks and which stations show as add-ons.
    let format: OrderFormat?
    @State private var store: MealBuilderStore
    @State private var trayPresented: Bool
    @State private var railSelection: String?
    @State private var scrolledStation: String?
    @State private var railNavigation: Task<Void, Never>?
    @State private var limitToast: String?
    @State private var toastDismissTask: Task<Void, Never>?
    // Which guided prompt is expanded (accordion). Others show a compact
    // summary. Starts on the first prompt and auto-advances as picks land.
    @State private var expandedPrompt: String?

    init(restaurant: Restaurant, format: OrderFormat? = nil, seed: [LineItem] = [], skipTrayAutoOpen: Bool = false) {
        self.restaurant = restaurant
        self.format = format
        let seededStore = MealBuilderStore(restaurant: restaurant, lineItems: seed, formatName: format?.name)
        // Curated base/vessel items (a burrito's tortilla) seed rule-safe
        // through the normal add path — not the raw lineItems seed, which
        // bypasses rules. Scaled for size formats (Subway Footlong).
        if let format {
            seededStore.seedThroughRules(format.autoAdd, multiplier: format.portionMultiplier)
        }
        _store = State(initialValue: seededStore)
        // Guided formats open on the fillings, never the tray. Re-opening a
        // saved recipe lands in the tray with items visible — that's the
        // point of saving it.
        _trayPresented = State(initialValue: !seed.isEmpty && !skipTrayAutoOpen)
        _railSelection = State(initialValue:
            Self.stationCategories(restaurant: restaurant, format: format).first?.id)
        _expandedPrompt = State(initialValue: format?.prompts.first?.id)
    }

    /// Route-driven entry from the format picker. A chosen format skips the
    /// tray auto-open (nothing to review yet — the user is about to build);
    /// build-your-own (`format == nil`) is byte-for-byte today's behavior.
    init(route: MenuRoute) {
        self.init(restaurant: route.restaurant, format: route.format, skipTrayAutoOpen: route.format != nil)
    }

    /// The stations shown in the scroll + rail. Guided formats curate this
    /// to their `optionalCategoryIds` (the add-ons after the guided picks);
    /// build-your-own shows every station. One ordered array feeds BOTH the
    /// rail and the scroll `ForEach`, so rail↔scroll sync stays correct.
    static func stationCategories(restaurant: Restaurant, format: OrderFormat?) -> [MenuCategory] {
        guard let format else { return restaurant.categories }
        return format.optionalCategoryIds.compactMap { restaurant.category(id: $0) }
    }

    private var stationCategories: [MenuCategory] {
        Self.stationCategories(restaurant: restaurant, format: format)
    }

    var body: some View {
        ZStack {
            Backdrop(tint: restaurant.style.hue)
            stationList
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            CategoryRail(
                categories: stationCategories,
                selection: railSelection,
                hue: restaurant.style.hue,
                onTap: jump(to:)
            )
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
    }

    // MARK: Stations

    private var stationList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let format, !format.prompts.isEmpty {
                    guidedSection(format)
                    if !stationCategories.isEmpty {
                        addOnsHeader
                    }
                }
                // Only the stations are scroll targets — the guided section
                // above scrolls with the content but never drives the rail.
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(stationCategories) { category in
                        stationSection(category)
                            .id(category.id)
                    }
                }
                .scrollTargetLayout()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
        .scrollPosition(id: $scrolledStation, anchor: .top)
        .contentMargins(.bottom, Metrics.tabBarClearance + Metrics.trayBarClearance, for: .scrollContent)
        .onChange(of: scrolledStation) { _, newValue in
            // Scroll → rail sync, muted while a tap navigation is in
            // flight so the target pill doesn't flash back.
            guard railNavigation == nil, let newValue else { return }
            withAnimation(Motion.snap) { railSelection = newValue }
        }
    }

    private func stationSection(_ category: MenuCategory) -> some View {
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
                ForEach(category.items) { item in
                    let quantity = store.quantity(forMenuItemId: item.id)
                    MenuItemRow(
                        item: item,
                        accent: category.style.accent,
                        quantity: quantity,
                        policy: policy,
                        isDisabled: scoopCapReached && quantity == 0,
                        onTap: { tapStation(item, in: category) }
                    )
                }
            }
        }
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
        withAnimation(Motion.glide) { scrolledStation = stationId }
        railNavigation = Task {
            // Re-assert once: a position write issued mid-deceleration
            // can be dropped in favor of the decelerating scroll.
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            if scrolledStation != stationId {
                withAnimation(Motion.glide) { scrolledStation = stationId }
            }
            // Hold the mute until the programmatic scroll settles.
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            railNavigation = nil
        }
    }

    // MARK: Portion actions

    /// One tap on a station row, resolved by the station's `PortionPolicy`:
    /// cycle full → ×2 → off, an auto ½ + ½ split, or capped scoops.
    private func tapStation(_ item: MenuItem, in category: MenuCategory) {
        withAnimation(Motion.snap) {
            apply(store.applyPortionTap(item, in: category), in: category)
        }
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
                    .overlay(Capsule().strokeBorder(Color.destructiveRed.opacity(0.4), lineWidth: 1))
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

/// A station row in the tap-to-cycle model (replaces the ½ · 1 · 2 chips).
/// The whole card is one tap target; its `PortionPolicy` decides what the
/// tap does. Current state reads out as a trailing badge (½ / ×2 / scoop
/// count); a full single portion is just the filled dot.
private struct MenuItemRow: View {
    let item: MenuItem
    let accent: Color
    let quantity: Double
    let policy: PortionPolicy
    let isDisabled: Bool
    let onTap: () -> Void

    private var isInMeal: Bool { quantity > 0 }
    private var isHalf: Bool { abs(quantity - 0.5) < 0.001 }

    var body: some View {
        Button(action: onTap) {
            Card(padding: Spacing.sm + Spacing.xs) {
                HStack(spacing: Spacing.md) {
                    Circle()
                        .fill(isInMeal ? accent : accent.opacity(0.35))
                        .frame(width: 8, height: 8)
                        .animation(Motion.snap, value: isInMeal)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                                .lineLimit(2)
                            Spacer(minLength: Spacing.xs)
                            Text(item.servingDescription)
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                                .lineLimit(1)
                        }
                        MacroStrip(macros: item.macros)
                    }

                    if let label = badgeLabel {
                        Text(label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(isHalf ? accent : Color.void)
                            .frame(minWidth: 30)
                            .frame(height: 28)
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
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .animation(Motion.snap, value: quantity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isInMeal ? [.isSelected] : [])
    }

    /// ½ and ×2 always show; scoops show their count; a plain full portion
    /// is just the filled dot (no badge).
    private var badgeLabel: String? {
        guard isInMeal else { return nil }
        if isHalf { return "½" }
        if case .cappedScoops = policy { return "\(Int(quantity.rounded()))" }
        if abs(quantity - 2) < 0.001 { return "×2" }
        if abs(quantity - 1) < 0.001 { return nil }
        return "×\(quantity.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var accessibilityText: String {
        var parts = [item.name, item.servingDescription, "\(Int(item.macros.calories.rounded())) calories"]
        if isHalf { parts.append("half portion") }
        else if isInMeal { parts.append("\(quantity.formatted()) in meal") }
        return parts.joined(separator: ", ")
    }

    private var accessibilityHint: String {
        if isDisabled { return "At the limit. Remove another to add this." }
        switch policy {
        case .splitBase: return "Tap to add. Tap again to double, or tap another to split half and half."
        case .cappedScoops: return "Tap to add a scoop."
        case .freeAddOns: return "Tap to add. Tap again to double, again to remove."
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
                        ForEach(guidedItems(for: prompt)) { item in
                            GuidedItemRow(
                                item: item,
                                accent: category?.style.accent ?? .textSecondary,
                                isSelected: store.quantity(forMenuItemId: item.id) > 0,
                                resultingQuantity: store.quantity(forMenuItemId: item.id),
                                onTap: { pick(item, prompt: prompt) }
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
        case .selectOne: return "choose 1"
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
    /// prompt's subset. Everything else toggles at its set quantity. The prompt
    /// stays open after a pick (no auto-advance) so portions stay adjustable;
    /// the user moves on by tapping the next prompt's header.
    func pick(_ item: MenuItem, prompt: FormatPrompt) {
        guard let category = restaurant.category(id: prompt.categoryId) else { return }
        let scope = prompt.subsetItemIds.map(Set.init)

        if canSplit(prompt) {
            Haptics.tap()
            withAnimation(Motion.snap) {
                apply(store.applyPortionTap(item, in: category, policy: .splitBase, scope: scope), in: category)
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
    }
}

// MARK: - Guided item row

/// A single guided choice — a radio-style option row inside the prompt
/// accordion (chromeless; the accordion card is the surface). Guided picks
/// are select/deselect (the format sets the quantity), so there are no
/// ½ · 1 · 2 chips. A non-unit result (tacos ×3, Footlong ×2, a CAVA half)
/// surfaces as a small volt chip.
private struct GuidedItemRow: View {
    let item: MenuItem
    let accent: Color
    let isSelected: Bool
    let resultingQuantity: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? accent : Color.hairline, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(accent)
                            .frame(width: 12, height: 12)
                    }
                }
                .animation(Motion.snap, value: isSelected)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.name)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(2)
                        Spacer(minLength: Spacing.xs)
                        Text(item.servingDescription)
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                            .lineLimit(1)
                    }
                    MacroStrip(macros: item.macros)
                }

                if let quantityLabel {
                    Text(quantityLabel)
                        .font(.numeral)
                        .foregroundStyle(.volt)
                }
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.08) : Color.clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var quantityLabel: String? {
        guard isSelected, abs(resultingQuantity - 1) > 0.001 else { return nil }
        if abs(resultingQuantity - 0.5) < 0.001 { return "½" }
        return "×\(resultingQuantity.formatted(.number.precision(.fractionLength(0...2))))"
    }

    private var accessibilityText: String {
        var parts = [item.name, item.servingDescription, "\(Int(item.macros.calories.rounded())) calories"]
        if isSelected { parts.append("selected") }
        return parts.joined(separator: ", ")
    }
}
