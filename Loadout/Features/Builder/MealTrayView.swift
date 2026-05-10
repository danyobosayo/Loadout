import SwiftUI

struct MealTrayView: View {
    @Bindable var store: MealBuilderStore
    @Environment(\.dismiss) private var dismiss

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
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            store.clear()
                        }
                        .foregroundStyle(.appDestructive)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !store.isEmpty {
                    saveBar
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

    private var saveBar: some View {
        Button {
            // Phase 3b: Save snapshots a BuiltMeal and clears the tray.
            // Phase 4 wires it to MacroFactor export; favorites/history land later.
            _ = store.save()
            dismiss()
        } label: {
            Text("Save meal")
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
}

private struct LineItemRow: View {
    let lineItem: LineItem
    @Bindable var store: MealBuilderStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lineItem.displayName)
                        .font(.appBody)
                    Text(lineItem.servingDescription)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                Spacer()
                QuantityStepper(
                    value: Binding(
                        get: { lineItem.quantity },
                        set: { store.setQuantity(lineItemId: lineItem.id, to: $0) }
                    ),
                    range: 0...10
                )
            }
            MacroBar(macros: lineItem.macros * lineItem.quantity, style: .inline)
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
