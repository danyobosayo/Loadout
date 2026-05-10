import SwiftUI

struct MenuView: View {
    let restaurant: Restaurant
    @State private var store: MealBuilderStore
    @State private var trayPresented = false

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _store = State(initialValue: MealBuilderStore(restaurant: restaurant))
    }

    var body: some View {
        List {
            ForEach(restaurant.categories) { category in
                Section {
                    ForEach(category.items) { item in
                        Button {
                            store.add(item, in: category)
                        } label: {
                            MenuItemRow(
                                item: item,
                                categoryIconFallback: category.iconName,
                                quantityInMeal: store.quantity(forMenuItemId: item.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(headerText(for: category))
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                        .textCase(.uppercase)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(restaurant.name)
        .safeAreaInset(edge: .bottom) {
            trayBar
        }
        .sheet(isPresented: $trayPresented) {
            MealTrayView(store: store)
        }
    }

    private var trayBar: some View {
        Button {
            trayPresented = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                MacroBar(macros: store.totalMacros, style: .inline)
                Spacer(minLength: Spacing.sm)
                trayBarTrailing
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.bar)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(trayAccessibilityLabel)
        .accessibilityHint("Opens your meal to edit quantities or save.")
    }

    private var trayBarTrailing: some View {
        HStack(spacing: Spacing.xs) {
            if store.isEmpty {
                Text("Tap items to build")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            } else {
                Text("^[\(store.totalLineItemCount) item](inflect: true)")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.appAccent)
            }
        }
    }

    private var trayAccessibilityLabel: String {
        if store.isEmpty {
            return "Meal tray. Empty."
        }
        let totals = store.totalMacros
        return "Meal tray. \(store.totalLineItemCount) items. \(Int(totals.calories.rounded())) calories total."
    }

    private func headerText(for category: MenuCategory) -> String {
        switch category.selectionRule {
        case .selectOne:
            return "\(category.name) · choose 1"
        case .selectUpTo(let max):
            return "\(category.name) · up to \(max)"
        case .selectMany:
            return category.name
        }
    }
}

private struct MenuItemRow: View {
    let item: MenuItem
    let categoryIconFallback: String?
    let quantityInMeal: Double

    private var isInMeal: Bool { quantityInMeal > 0 }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            MenuItemIcon(name: item.iconName, categoryFallback: categoryIconFallback, size: 26)
                .padding(.top, 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.appBody)
                    if isInMeal {
                        Text("×\(quantityInMeal, format: .number.precision(.fractionLength(0...1)))")
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(.appAccent)
                    }
                    Spacer()
                    Text(item.servingDescription)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                MacroBar(macros: item.macros, style: .inline)
                if let notes = item.notes {
                    Text(notes)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isInMeal ? "Tap to add another." : "Tap to add to your meal.")
    }

    private var accessibilityLabel: String {
        var parts = [item.name, item.servingDescription]
        if isInMeal {
            parts.append("\(Int(quantityInMeal.rounded())) in meal")
        }
        return parts.joined(separator: ", ")
    }
}
