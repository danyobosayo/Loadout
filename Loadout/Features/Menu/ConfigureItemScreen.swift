import SwiftUI

/// Configuring an item that arrives already built — the "how do you want it?"
/// screen.
///
/// Pushed, not presented. Every restaurant now answers the same two questions in
/// the same two places: screen 1 is "what are you having?", screen 2 is "how do
/// you want it?". For Chipotle screen 2 is the station builder; for Cane's it is
/// this. A sheet layered on top of screen 1 made those feel like different kinds
/// of place, which is exactly the inconsistency this resolves.
///
/// The interaction is the one every drive-thru app has converged on — Sonic's is
/// the clearest: what comes on it is already lit, what you *can* add is dim, and
/// one tap flips either way. There is no separate "remove" mode and no list of
/// checkboxes; the lit/unlit state is the whole model.
///
/// The header total is the published figure until you touch something, because
/// that is the number on the menu board and the number the restaurant will hand
/// you. Every change from there is a subtraction or addition of a sourced
/// component, never a recomputation.
struct ConfigureItemScreen: View {
    let item: MenuItem
    let category: MenuCategory
    let restaurant: Restaurant
    let accent: Color
    /// Non-nil when reopening a line already on the tray.
    var editing: UUID?
    var initialConfiguration: ItemConfiguration = .unchanged
    let onCommit: (ItemConfiguration) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var configuration: ItemConfiguration = .unchanged
    @State private var expandedRecipeGroups: Set<String> = []

    private var macros: Macros { item.macros(with: configuration, in: restaurant) }
    private var delta: Double { macros.calories - item.macros.calories }
    private var recipe: DrinkRecipe? { restaurant.drinkRecipe(for: item) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                if !item.removableDefaults.isEmpty {
                    section("Comes with", subtitle: "Tap to take something off") {
                        ForEach(item.removableDefaults) { component in
                            row(component, isOn: !configuration.removed.contains(component.menuItemId))
                        }
                    }
                }
                if !item.availableExtras.isEmpty {
                    section("Add", subtitle: nil) {
                        ForEach(item.availableExtras) { component in
                            row(component, isOn: addedQuantity(of: component.menuItemId) > 0)
                        }
                    }
                }
                if let recipe {
                    recipeEditor(recipe)
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, 96)
        }
        .background(Backdrop())
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { commitBar }
        .onAppear { configuration = initialConfiguration }
    }

    // MARK: Header

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(macros.calories, format: .number.precision(.fractionLength(0)))
                        .font(.numeralHero)
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText(value: macros.calories))
                        .numeralFitting()
                    Text("cal")
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                    Spacer(minLength: Spacing.sm)
                    if abs(delta) >= 1 {
                        // Against the board figure, so "what did my change cost?"
                        // is answerable without doing the arithmetic yourself.
                        Text("\(delta > 0 ? "+" : "−")\(Int(abs(delta).rounded())) vs standard")
                            .font(.numeralCompact)
                            .foregroundStyle(accent)
                            .numeralFitting()
                            .transition(.opacity)
                    }
                }
                MacroSegmentBar(macros: macros)
                MacroStrip(macros: macros, showsCalories: false)
                if item.sizeLabel != nil {
                    Text(item.servingDescription)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                if configuration.hasRecipeChanges {
                    standardRecipeNotice
                }
                if item.isEstimated, let notes = item.notes {
                    estimateNote(notes)
                }
            }
        }
        .animation(Motion.snap, value: macros.calories)
    }

    private var standardRecipeNotice: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Starbucks does not recalculate nutrition for customizations. Macros remain the published standard recipe for this size.")
                .font(.appCaption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.textSecondary)
        .accessibilityIdentifier("recipe.standardMacrosNotice")
    }

    /// An unofficial figure says so, in the colour reserved for "unverified".
    private func estimateNote(_ notes: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .bold))
            Text(notes)
                .font(.appCaption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.overTarget)
        .padding(.top, 2)
    }

    // MARK: Rows

    @ViewBuilder
    private func section(
        _ title: String, subtitle: String?, @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(title).microLabelStyle()
                if let subtitle {
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                }
            }
            VStack(spacing: Spacing.sm) { content() }
        }
    }

    private func row(_ component: ItemComponent, isOn: Bool) -> some View {
        let resolved = restaurant.resolve(menuItemId: component.menuItemId)?.item
        let extraCount = addedQuantity(of: component.menuItemId)
        return Button {
            Haptics.tap()
            withAnimation(Motion.snap) { toggle(component) }
        } label: {
            Card(padding: Spacing.sm + Spacing.xs, highlight: isOn ? accent : nil) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isOn ? accent : Color.textTertiary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                            Text(label(for: component, resolved: resolved, extras: extraCount))
                                .font(.appHeadline)
                                .foregroundStyle(isOn ? .textPrimary : .textSecondary)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                            if let resolved {
                                Text(signedCalories(resolved, component, isOn: isOn))
                                    .font(.numeralCompact)
                                    .foregroundStyle(.textTertiary)
                                    .numeralFitting()
                            }
                        }
                        if let resolved, isOn || !component.isDefault {
                            MacroStrip(macros: resolved.macros * effectiveQuantity(component))
                        }
                    }
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(accessibilityLabel(for: component, resolved: resolved, isOn: isOn))
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: Recipe editor

    @ViewBuilder
    private func recipeEditor(_ recipe: DrinkRecipe) -> some View {
        ForEach(recipe.groups) { group in
            section(group.name, subtitle: group.kind == .quantity ? "Match your order" : nil) {
                switch group.kind {
                case .single:
                    recipeSingleRow(group, recipe: recipe)
                case .quantity:
                    if group.choices.count == 1 {
                        ForEach(group.choices) { choice in
                            recipeQuantityRow(choice, group: group, recipe: recipe)
                        }
                    } else {
                        recipeQuantityDisclosure(group, recipe: recipe)
                    }
                }
            }
        }
    }

    private func recipeQuantityDisclosure(
        _ group: RecipeOptionGroup,
        recipe: DrinkRecipe
    ) -> some View {
        let total = group.choices.reduce(0) {
            $0 + recipe.quantity(
                for: $1, sizeLabel: item.sizeLabel, configuration: configuration
            )
        }
        return Card(padding: Spacing.sm + Spacing.xs, highlight: total > 0 ? accent : nil) {
            DisclosureGroup(isExpanded: recipeGroupBinding(group.id)) {
                VStack(spacing: Spacing.sm) {
                    ForEach(group.choices) { choice in
                        recipeQuantityRow(choice, group: group, recipe: recipe)
                    }
                }
                .padding(.top, Spacing.sm)
            } label: {
                HStack {
                    Text(total == 0 ? "Choose amounts" : "\(total) selected")
                        .font(.appHeadline)
                        .foregroundStyle(total > 0 ? .textPrimary : .textSecondary)
                    Spacer()
                }
            }
            .tint(accent)
        }
        .accessibilityIdentifier("recipeGroup.\(group.id)")
    }

    private func recipeGroupBinding(_ groupId: String) -> Binding<Bool> {
        Binding(
            get: { expandedRecipeGroups.contains(groupId) },
            set: { expanded in
                if expanded {
                    expandedRecipeGroups.insert(groupId)
                } else {
                    expandedRecipeGroups.remove(groupId)
                }
            }
        )
    }

    private func recipeSingleRow(_ group: RecipeOptionGroup, recipe: DrinkRecipe) -> some View {
        let selectedId = recipe.selection(
            for: group, sizeLabel: item.sizeLabel, configuration: configuration
        )
        let selectedName = group.choices.first(where: { $0.id == selectedId })?.name ?? "None"

        return Menu {
            if group.allowsNone {
                Button("None") { setRecipeSelection(nil, in: group, recipe: recipe) }
            }
            ForEach(group.choices) { choice in
                Button {
                    setRecipeSelection(choice.id, in: group, recipe: recipe)
                } label: {
                    if choice.id == selectedId {
                        Label(choice.name, systemImage: "checkmark")
                    } else {
                        Text(choice.name)
                    }
                }
            }
        } label: {
            Card(padding: Spacing.sm + Spacing.xs, highlight: accent) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(selectedName)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .accessibilityIdentifier("recipeSingle.\(group.id)")
    }

    private func recipeQuantityRow(
        _ choice: RecipeChoice,
        group: RecipeOptionGroup,
        recipe: DrinkRecipe
    ) -> some View {
        let quantity = recipe.quantity(
            for: choice, sizeLabel: item.sizeLabel, configuration: configuration
        )
        let maximum = choice.maximumQuantity ?? 12

        return Card(padding: Spacing.sm + Spacing.xs, highlight: quantity > 0 ? accent : nil) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.name)
                        .font(.appHeadline)
                        .foregroundStyle(quantity > 0 ? .textPrimary : .textSecondary)
                    Text(quantity == 1 ? "1 serving" : "\(quantity) servings")
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                }
                Spacer()
                Button {
                    setRecipeQuantity(max(0, quantity - 1), for: choice, recipe: recipe)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(quantity > 0 ? accent : Color.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(quantity == 0)
                .accessibilityLabel("Remove one \(choice.name)")
                .accessibilityIdentifier("recipeMinus.\(choice.id)")

                Text("\(quantity)")
                    .font(.numeralCompact)
                    .foregroundStyle(.textPrimary)
                    .frame(minWidth: 24)
                    .accessibilityIdentifier("recipeQuantity.\(choice.id)")

                Button {
                    setRecipeQuantity(min(maximum, quantity + 1), for: choice, recipe: recipe)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
                .disabled(quantity >= maximum)
                .accessibilityLabel("Add one \(choice.name)")
                .accessibilityIdentifier("recipePlus.\(choice.id)")
            }
        }
    }

    private func setRecipeSelection(
        _ choiceId: String?,
        in group: RecipeOptionGroup,
        recipe: DrinkRecipe
    ) {
        let standard = recipe.defaults(for: item.sizeLabel).selections[group.id]
        if choiceId == standard {
            configuration.recipeSelectionChanges.remove(group.id)
            configuration.recipeSelections.removeValue(forKey: group.id)
        } else {
            configuration.recipeSelectionChanges.insert(group.id)
            if let choiceId {
                configuration.recipeSelections[group.id] = choiceId
            } else {
                configuration.recipeSelections.removeValue(forKey: group.id)
            }
        }
    }

    private func setRecipeQuantity(
        _ quantity: Int,
        for choice: RecipeChoice,
        recipe: DrinkRecipe
    ) {
        let standard = recipe.defaults(for: item.sizeLabel).quantities[choice.id] ?? 0
        if quantity == standard {
            configuration.recipeQuantities.removeValue(forKey: choice.id)
        } else {
            configuration.recipeQuantities[choice.id] = quantity
        }
    }

    private func label(for component: ItemComponent, resolved: MenuItem?, extras: Double) -> String {
        var name = resolved?.name ?? "Item"
        if component.isDefault {
            if component.quantity > 1 { name += " ×\(Int(component.quantity))" }
            return name
        }
        // Cane's Sauce is both a default and an addable extra, so without this
        // the same name appears twice in one sheet with no way to tell the rows
        // apart. "Extra Cane's Sauce" is also what you'd say at the counter.
        if isAlsoADefault(component.menuItemId) { name = "Extra \(name)" }
        if extras > 1 { name += " ×\(Int(extras))" }
        return name
    }

    private func isAlsoADefault(_ menuItemId: String) -> Bool {
        (item.components ?? []).contains { $0.menuItemId == menuItemId && $0.isDefault }
    }

    /// A default reads as what it costs you to drop it; an extra as what it adds.
    private func signedCalories(_ resolved: MenuItem, _ component: ItemComponent, isOn: Bool) -> String {
        let each = resolved.macros.calories
        if component.isDefault {
            return isOn ? "−\(Int((each * component.quantity).rounded())) if removed"
                        : "+\(Int((each * component.quantity).rounded())) to restore"
        }
        return "+\(Int(each.rounded())) each"
    }

    // MARK: Toggling

    private func addedQuantity(of menuItemId: String) -> Double {
        configuration.added.first { $0.menuItemId == menuItemId }?.quantity ?? 0
    }

    private func effectiveQuantity(_ component: ItemComponent) -> Double {
        component.isDefault ? component.quantity : max(1, addedQuantity(of: component.menuItemId))
    }

    private func toggle(_ component: ItemComponent) {
        let id = component.menuItemId
        if component.isDefault {
            if configuration.removed.contains(id) {
                configuration.removed.remove(id)
            } else {
                configuration.removed.insert(id)
            }
            return
        }
        // Extras stack: tap once for one, again for two. Tapping a component
        // that is also a default adds a second helping rather than a duplicate
        // line, which is how "extra sauce" is actually ordered.
        if let idx = configuration.added.firstIndex(where: { $0.menuItemId == id }) {
            if configuration.added[idx].quantity >= 3 {
                configuration.added.remove(at: idx)
            } else {
                configuration.added[idx].quantity += 1
            }
        } else {
            configuration.added.append(ItemComponent(menuItemId: id, isDefault: false))
        }
    }

    // MARK: Commit

    private var commitBar: some View {
        VStack(spacing: Spacing.xs) {
            if let summary = item.configurationSummary(configuration, in: restaurant) {
                Text(summary)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            Button(editing == nil ? "Add to meal" : "Update") {
                Haptics.success()
                onCommit(configuration)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        // Clear the floating tab bar. As a sheet this bar sat above it; pushed,
        // it sits under it, and "Add to meal" ended up behind the tab pill.
        .padding(.bottom, Metrics.tabBarClearance)
        .background(.ultraThinMaterial)
        .animation(Motion.snap, value: configuration)
    }

    private func accessibilityLabel(
        for component: ItemComponent, resolved: MenuItem?, isOn: Bool
    ) -> String {
        let name = resolved?.name ?? "item"
        let calories = Int((resolved?.macros.calories ?? 0).rounded())
        if component.isDefault {
            return isOn
                ? "\(name), included, \(calories) calories. Tap to remove."
                : "\(name), removed. Tap to put back."
        }
        let count = addedQuantity(of: component.menuItemId)
        return count > 0
            ? "\(name), \(Int(count)) added, \(calories) calories each. Tap to add another."
            : "\(name), \(calories) calories. Tap to add."
    }
}
