import SwiftUI

struct MenuView: View {
    let restaurant: Restaurant

    var body: some View {
        List {
            ForEach(restaurant.categories) { category in
                Section {
                    ForEach(category.items) { item in
                        MenuItemRow(item: item)
                    }
                } header: {
                    Text(category.name)
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                        .textCase(.uppercase)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(restaurant.name)
    }
}

private struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .font(.appBody)
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
        .padding(.vertical, 4)
    }
}
