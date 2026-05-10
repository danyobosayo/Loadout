import SwiftUI
import SwiftData

struct MealTrayView: View {
    @Bindable var store: MealBuilderStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @State private var savePrompt = false
    @State private var favoriteName = ""

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    ContentUnavailableView(
                        "No items yet",
                        systemImage: "tray",
                        description: Text("Tap items on the menu to start building.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Your meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !store.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            favoriteName = "\(store.restaurant.name) Bowl"
                            savePrompt = true
                        } label: {
                            Label("Save to Favorites", systemImage: "heart")
                        }
                    }
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            store.clear()
                        }
                        .foregroundStyle(.appDestructive)
                    }
                }
            }
            .alert("Save favorite", isPresented: $savePrompt) {
                TextField("Name", text: $favoriteName)
                Button("Save", action: saveFavorite)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give this meal a name so you can rerun it later.")
            }
            .safeAreaInset(edge: .bottom) {
                if !store.isEmpty {
                    logBar
                }
            }
        }
    }

    private var list: some View {
        List {
            Section {
                MacroBar(macros: store.totalMacros, style: .hero)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.sm)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md))
            }

            Section {
                ForEach(store.lineItems) { lineItem in
                    LineItemRow(lineItem: lineItem, store: store)
                }
            } header: {
                Text("^[\(store.totalLineItemCount) item](inflect: true)")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                    .textCase(.uppercase)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var logBar: some View {
        Button {
            logToMacroFactor()
        } label: {
            Label("Log to MacroFactor", systemImage: "arrow.up.forward.app.fill")
                .font(.appHeadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.bar)
    }

    private func logToMacroFactor() {
        let restaurantName = store.restaurant.name
        let meal = store.save()
        let exporter = MacroFactorExporter()
        let food = exporter.food(for: meal, restaurantName: restaurantName)
        if let url = try? exporter.shortcutsURL(for: food) {
            openURL(url)
        }
        recordHistory(meal: meal)
        dismiss()
    }

    private func recordHistory(meal: BuiltMeal) {
        let logged = LoggedMeal(
            restaurantId: meal.restaurantId,
            loggedAt: meal.createdAt,
            lineItems: meal.lineItems
        )
        modelContext.insert(logged)
        do {
            try LoggedMealRetention.enforceLimit(in: modelContext)
            try modelContext.save()
        } catch {
            // Logging the meal to MacroFactor still happened — the user
            // got their value. Failing to persist locally is recoverable
            // (next log will re-attempt eviction). Don't surface an
            // error that interrupts the export flow.
        }
    }

    private func saveFavorite() {
        let trimmed = favoriteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "\(store.restaurant.name) Bowl" : trimmed
        let favorite = FavoriteMeal(
            name: name,
            restaurantId: store.restaurant.id,
            lineItems: store.lineItems
        )
        modelContext.insert(favorite)
        try? modelContext.save()
        // Don't clear or dismiss — saving a favorite is a side action,
        // the user is probably about to also Log it to MacroFactor.
    }
}

private struct LineItemRow: View {
    let lineItem: LineItem
    @Bindable var store: MealBuilderStore

    private static let presets: [Double] = [0.5, 1, 1.5, 2]

    private var matchesPreset: Bool {
        Self.presets.contains { abs($0 - lineItem.quantity) < 0.001 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(lineItem.displayName)
                    .font(.appBody)
                if !matchesPreset {
                    // Quantity is outside the chip presets (e.g., 3 from
                    // re-tapping the menu row). Surface it next to the
                    // title so the chip row's empty selection isn't
                    // mysterious.
                    Text("×\(lineItem.quantity, format: .number.precision(.fractionLength(0...1)))")
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.appAccent)
                }
                Spacer()
                Text(lineItem.servingDescription)
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            MacroBar(macros: lineItem.macros * lineItem.quantity, style: .inline)
            QuickQuantityChips(
                value: Binding(
                    get: { lineItem.quantity },
                    set: { store.setQuantity(lineItemId: lineItem.id, to: $0) }
                )
            )
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.remove(lineItemId: lineItem.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
