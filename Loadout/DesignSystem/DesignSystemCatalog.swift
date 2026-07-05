import SwiftUI

/// Living review surface for the Obsidian design language. Not wired
/// into RootView — open via Xcode Previews when touching the system.
struct DesignSystemCatalog: View {
    @State private var quantity: Double = 1

    private let bowlMacros = Macros(calories: 770, proteinGrams: 64, carbGrams: 47, fatGrams: 27)
    private let chickenMacros = Macros(calories: 180, proteinGrams: 32, carbGrams: 0, fatGrams: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        section("Masthead") {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Design language").microLabelStyle(.volt)
                                Text("Obsidian").displayXLStyle()
                            }
                        }

                        section("Macro ring") {
                            HStack {
                                Spacer()
                                MacroRing(calories: bowlMacros.calories)
                                Spacer()
                            }
                        }

                        section("Hero macros") {
                            MacroBar(macros: bowlMacros, style: .hero)
                        }

                        section("Segment bar") {
                            MacroSegmentBar(macros: bowlMacros)
                        }

                        section("Inline macros") {
                            MacroBar(macros: chickenMacros, style: .inline)
                        }

                        section("Card") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Chicken")
                                        .font(.appHeadline)
                                        .foregroundStyle(.textPrimary)
                                    Text("4 oz")
                                        .font(.appCaption)
                                        .foregroundStyle(.textSecondary)
                                    MacroBar(macros: chickenMacros * quantity, style: .inline)
                                }
                            }
                        }

                        section("Portion controls") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.md) {
                                    HStack {
                                        QuickQuantityChips(value: $quantity)
                                        Spacer()
                                        QuantityStepper(value: $quantity, step: 0.5, range: 0...10)
                                    }
                                }
                            }
                        }

                        section("Buttons") {
                            VStack(spacing: Spacing.sm) {
                                Button { } label: { Label("Log to MacroFactor", systemImage: "bolt.fill") }
                                    .buttonStyle(.primaryAction)
                                Button { } label: { Label("Save Recipe", systemImage: "bookmark") }
                                    .buttonStyle(.ghost)
                            }
                        }

                        section("Typography") {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Display XL").displayXLStyle()
                                Text("Display title").font(.displayTitle).foregroundStyle(.textPrimary)
                                Text("Headline").font(.appHeadline).foregroundStyle(.textPrimary)
                                Text("Body — the quick brown fox.").font(.appBody).foregroundStyle(.textPrimary)
                                Text("Caption — supporting metadata").font(.appCaption).foregroundStyle(.textSecondary)
                                Text("Micro label").microLabelStyle()
                                Text("2,048").font(.numeralHero).foregroundStyle(.textPrimary)
                            }
                        }

                        section("Palette") {
                            Card {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    swatch("volt", .volt)
                                    swatch("protein", .protein)
                                    swatch("carbs", .carbs)
                                    swatch("fat", .fat)
                                    swatch("destructive", .destructiveRed)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Catalog")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: 40, height: 24)
            Text(name).microLabelStyle()
            Spacer()
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title).microLabelStyle()
            content()
        }
    }
}

#Preview {
    DesignSystemCatalog()
}
