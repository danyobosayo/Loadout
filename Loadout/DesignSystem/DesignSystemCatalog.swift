import SwiftUI

// Phase 2 review surface. Lives in DesignSystem/ rather than Features/
// so it can be deleted in one folder when Phase 3 wires the real
// Restaurants tab into RootView.
struct DesignSystemCatalog: View {
    @State private var quantity: Double = 1

    private let bowlMacros = Macros(calories: 770, proteinGrams: 64, carbGrams: 47, fatGrams: 27)
    private let chickenMacros = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    section("Hero macros") {
                        MacroBar(macros: bowlMacros, style: .hero)
                    }

                    section("Inline macros") {
                        MacroBar(macros: chickenMacros, style: .inline)
                    }

                    section("Card") {
                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Chicken")
                                    .font(.appHeadline)
                                Text("4 oz")
                                    .font(.appCaption)
                                    .foregroundStyle(.appSecondaryText)
                                MacroBar(macros: chickenMacros * quantity, style: .inline)
                            }
                        }
                    }

                    section("Quantity stepper") {
                        Card {
                            HStack {
                                Text("Servings")
                                    .font(.appBody)
                                Spacer()
                                QuantityStepper(value: $quantity, step: 0.5, range: 0.5...4)
                            }
                        }
                    }

                    section("Typography") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Large title").font(.appLargeTitle)
                            Text("Title").font(.appTitle)
                            Text("Headline").font(.appHeadline)
                            Text("Body — the quick brown fox jumps over the lazy dog.")
                                .font(.appBody)
                            Text("Caption — supporting metadata")
                                .font(.appCaption)
                                .foregroundStyle(.appSecondaryText)
                        }
                    }

                    section("Accent") {
                        Card {
                            HStack(spacing: Spacing.md) {
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 32, height: 32)
                                Text("Color.appAccent")
                                    .font(.appBody)
                                Spacer()
                                Button("Action") {}
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.appBackground)
            .navigationTitle("Loadout")
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
                .textCase(.uppercase)
            content()
        }
    }
}

#Preview("Light") {
    DesignSystemCatalog()
}

#Preview("Dark") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}
