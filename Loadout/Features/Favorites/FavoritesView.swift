import SwiftUI
import SwiftData
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

/// Saved recipes — rebuild, share, or delete. A recipe reopens into
/// the builder tray with its portions intact.
struct RecipesView: View {
    @Query(sort: [SortDescriptor(\FavoriteMeal.createdAt, order: .reverse)])
    private var recipes: [FavoriteMeal]
    @Environment(\.modelContext) private var modelContext
    @Environment(MacroFactorExport.self) private var macroFactorExport
    @Environment(SettingsStore.self) private var settings
    @Environment(\.openURL) private var openURL
    @State private var pendingDelete: FavoriteMeal?
    @State private var launchFailed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: .volt)

                if recipes.isEmpty {
                    EmptyStateView(
                        systemImage: "bookmark",
                        title: "No recipes yet",
                        message: "Build a meal, then Save Recipe in the tray to keep it here."
                    )
                } else {
                    list
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FavoriteMeal.self) { recipe in
                ReopenRecipeView(recipe: recipe)
            }
            .confirmationDialog(
                "Delete \"\(pendingDelete?.name ?? "recipe")\"?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete recipe", role: .destructive) {
                    if let recipe = pendingDelete {
                        Haptics.warning()
                        withAnimation(Motion.glide) {
                            modelContext.delete(recipe)
                            try? modelContext.save()
                        }
                    }
                    pendingDelete = nil
                }
            }
            .alert("Couldn't open Shortcuts", isPresented: $launchFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Make sure the Shortcuts app is installed, then try again.")
            }
        }
    }

    /// Fire the MacroFactor hand-off straight from the saved snapshot — no
    /// menu load, no tray. Success/failure surfaces via the app-root banner.
    private func logAgain(_ recipe: FavoriteMeal) {
        let meal = BuiltMeal(
            id: UUID(),
            restaurantId: recipe.restaurantId,
            name: recipe.name,
            lineItems: recipe.lineItems,
            createdAt: .now
        )
        let built = MacroFactorLog.handOff(
            meal: meal,
            restaurantName: ExportService.displayName(forRestaurantId: recipe.restaurantId),
            shortcutName: settings.shortcutName,
            coordinator: macroFactorExport,
            open: openURL
        ) { accepted in
            if !accepted { launchFailed = true }
        }
        if !built { launchFailed = true }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                masthead
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.sm)

                ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                    NavigationLink(value: recipe) {
                        RecipeCard(recipe: recipe, onLogAgain: { logAgain(recipe) }) {
                            pendingDelete = recipe
                        }
                    }
                    .buttonStyle(.pressable)
                    .entrance(index + 1)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .contentMargins(.bottom, Metrics.tabBarClearance, for: .scrollContent)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Saved loadouts")
                .microLabelStyle(.volt)
            Text("Recipes")
                .displayXLStyle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Recipe card

private struct RecipeCard: View {
    let recipe: FavoriteMeal
    let onLogAgain: () -> Void
    let onDelete: () -> Void

    private var payload: ExportService.RecipePayload {
        ExportService.recipePayload(
            name: recipe.name,
            restaurantId: recipe.restaurantId,
            lineItems: recipe.lineItems
        )
    }

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                identityTile

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(recipe.name)
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: Spacing.xs)
                        Text(recipe.createdAt, format: .dateTime.month(.abbreviated).day())
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                    }
                    Text("\(ExportService.displayName(forRestaurantId: recipe.restaurantId)) · ^[\(recipe.lineItems.count) item](inflect: true)")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    MacroBar(macros: recipe.totalMacros, style: .inline)
                }

                menuButton
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name), \(ExportService.summaryLine(recipe.totalMacros))")
    }

    private var identityTile: some View {
        let style = Restaurant.style(forId: recipe.restaurantId)
        return Image(style.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 21, height: 21)
            .foregroundStyle(Color.void)
            .frame(width: 40, height: 40)
            .background {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(style.hue)
            }
            .accessibilityHidden(true)
    }

    private var menuButton: some View {
        Menu {
            Button(action: onLogAgain) {
                Label("Log again", systemImage: "bolt.fill")
            }
            Divider()
            ShareLink(item: RecipeShareFile(payload: payload), preview: SharePreview(recipe.name)) {
                Label("Share recipe file", systemImage: "square.and.arrow.up")
            }
            Button {
                if let data = try? ExportService.recipeJSON(payload) {
                    UIPasteboard.general.string = String(decoding: data, as: UTF8.self)
                    Haptics.success()
                }
            } label: {
                Label("Copy recipe JSON", systemImage: "curlybraces")
            }
            Button {
                UIPasteboard.general.string = ExportService.quickAddText(
                    name: recipe.name, totals: recipe.totalMacros
                )
                Haptics.success()
            } label: {
                Label("Copy for MyFitnessPal", systemImage: "doc.on.clipboard")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.textSecondary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.04)))
                .contentShape(Circle())
        }
        .accessibilityLabel("Recipe actions")
    }
}

/// Loads the recipe's restaurant, then hands off to the builder with
/// the saved line items as seed — landing directly in the tray.
private struct ReopenRecipeView: View {
    let recipe: FavoriteMeal
    @Environment(\.menuRepository) private var menuRepository
    @State private var restaurant: Restaurant?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Backdrop(tint: Restaurant.style(forId: recipe.restaurantId).hue, intensity: 0.12)
            if let restaurant {
                MenuView(restaurant: restaurant, seed: recipe.lineItems)
            } else if let loadError {
                EmptyStateView(
                    systemImage: "exclamationmark.triangle",
                    title: "Couldn't reopen",
                    message: loadError,
                    tint: .destructiveRed
                )
            } else {
                ProgressView().tint(.volt).task(id: recipe.id) {
                    do {
                        restaurant = try await menuRepository.loadRestaurant(id: recipe.restaurantId)
                    } catch {
                        loadError = error.localizedDescription
                    }
                }
            }
        }
    }
}

private struct RecipeShareFile: Transferable {
    let payload: ExportService.RecipePayload

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { share in
            SentTransferredFile(try ExportService.writeShareFile(share.payload))
        }
    }
}
