import SwiftUI
import SwiftData
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

/// The tray — hero ring + macro trio, per-item portion editing, and
/// the export suite: MacroFactor Shortcut, MyFitnessPal Quick Add
/// (clipboard + app jump), recipe JSON share/copy.
struct MealTrayView: View {
    @Bindable var store: MealBuilderStore
    // The format this build started from, if any. Only used to nudge when a
    // required guided pick is still missing; nil for build-your-own/reopen.
    var format: OrderFormat?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsStore.self) private var settings
    @Environment(MacroFactorExport.self) private var macroFactorExport

    @State private var savePrompt = false
    @State private var recipeName = ""
    @State private var exportNote: String?
    @State private var noteDismissTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Backdrop(tint: store.restaurant.style.hue)

                if store.isEmpty {
                    EmptyStateView(
                        systemImage: "takeoutbag.and.cup.and.straw",
                        title: "Tray's empty",
                        message: "Tap a station item to start building.",
                        tint: store.restaurant.style.hue
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Your tray")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.textSecondary)
                    }
                    .accessibilityLabel("Close tray")
                }
                if !store.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            Haptics.warning()
                            withAnimation(Motion.glide) { store.clear() }
                        }
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.destructiveRed)
                    }
                }
            }
            .alert("Save recipe", isPresented: $savePrompt) {
                TextField("Name", text: $recipeName)
                Button("Save", action: saveRecipe)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Name it so you can rebuild it in two taps.")
            }
            .safeAreaInset(edge: .bottom) {
                if !store.isEmpty { actionDock }
            }
            .overlay(alignment: .bottom) {
                if let exportNote {
                    note(exportNote)
                        .padding(.bottom, 140)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Radius.sheet)
        .presentationBackground(Color.void)
        .presentationDragIndicator(.visible)
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                hero
                    .padding(.top, Spacing.sm)

                VStack(spacing: Spacing.sm) {
                    ForEach(Array(store.lineItems.enumerated()), id: \.element.id) { index, lineItem in
                        LineItemCard(lineItem: lineItem, store: store)
                            .entrance(index)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
    }

    private var hero: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                MacroRing(calories: store.totalMacros.calories, size: 124)

                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xs) {
                    MacroDisplay(kind: .protein, value: store.totalMacros.proteinGrams, style: .hero)
                    MacroDisplay(kind: .carbs, value: store.totalMacros.carbGrams, style: .hero)
                    MacroDisplay(kind: .fat, value: store.totalMacros.fatGrams, style: .hero)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            MacroSegmentBar(macros: store.totalMacros)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Action dock

    private var actionDock: some View {
        VStack(spacing: Spacing.sm) {
            if !unmetRequired.isEmpty {
                nudgeBanner
            }

            Button {
                logToMacroFactor()
            } label: {
                Label("Log to MacroFactor", systemImage: "bolt.fill")
            }
            .buttonStyle(.primaryAction)

            HStack(spacing: Spacing.sm) {
                Button {
                    recipeName = defaultRecipeName
                    savePrompt = true
                } label: {
                    Label("Save Recipe", systemImage: "bookmark")
                }
                .buttonStyle(.ghost)

                exportMenu
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background {
            Rectangle()
                .fill(Color.void)
                .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 1) }
                .ignoresSafeArea()
        }
    }

    /// Required guided picks the meal is still missing. Empty for
    /// build-your-own, reopened meals, and fully-answered formats.
    private var unmetRequired: [FormatPrompt] {
        guard let format else { return [] }
        let selected = Set(store.lineItems.map(\.menuItemId))
        return format.unmetRequiredPrompts(selecting: selected, in: store.restaurant)
    }

    /// Soft, non-blocking heads-up — you can still log an incomplete meal.
    private var nudgeBanner: some View {
        let labels = unmetRequired.map(\.shortLabel).joined(separator: ", ")
        return HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.fat)
                .accessibilityHidden(true)
            Text("Still to add: \(labels)")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background {
            Capsule()
                .fill(Color.fat.opacity(0.12))
                .overlay(Capsule().strokeBorder(Color.fat.opacity(0.32), lineWidth: 1))
        }
    }

    private var exportMenu: some View {
        Menu {
            Button {
                copyForMyFitnessPal()
            } label: {
                Label("Copy for MyFitnessPal", systemImage: "doc.on.clipboard")
            }
            ShareLink(item: recipeShare, preview: SharePreview(defaultRecipeName)) {
                Label("Share recipe file", systemImage: "square.and.arrow.up")
            }
            Button {
                copyRecipeJSON()
            } label: {
                Label("Copy recipe JSON", systemImage: "curlybraces")
            }
        } label: {
            // Manual ghost chrome — Menu doesn't reliably route through
            // ButtonStyle, so the capsule is applied to the label itself.
            Label("Export", systemImage: "arrow.up.forward")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.02))
                        .overlay(Capsule().strokeBorder(Color.hairline, lineWidth: 1))
                }
        }
    }

    // MARK: Actions

    private var defaultRecipeName: String {
        // Name after the format when there is one ("Chipotle Burrito",
        // "CAVA Grain Bowl"); fall back to the generic "… Bowl" for
        // build-your-own and reopened meals.
        if let formatName = store.formatName {
            return "\(store.restaurant.name) \(formatName)"
        }
        return "\(store.restaurant.name) Bowl"
    }

    private var currentPayload: ExportService.RecipePayload {
        ExportService.recipePayload(
            name: defaultRecipeName,
            restaurantId: store.restaurant.id,
            lineItems: store.lineItems
        )
    }

    private var recipeShare: RecipeShareFile {
        RecipeShareFile(payload: currentPayload)
    }

    private func logToMacroFactor() {
        let restaurantName = store.restaurant.name
        // Snapshot only — the tray stays intact. Clearing is the
        // user's call via the Clear button.
        let meal = store.snapshotMeal()
        let exporter = MacroFactorExporter(shortcutName: settings.shortcutName)
        let food = exporter.food(for: meal, restaurantName: restaurantName)
        guard let url = try? exporter.callbackURL(
            for: food,
            success: MacroFactorExport.successURL,
            error: MacroFactorExport.errorURL,
            cancel: MacroFactorExport.cancelURL
        ) else {
            Haptics.warning()
            showNote("Couldn't build the export")
            return
        }
        // Hold the meal for the callback, hand off, and close the tray. The
        // Shortcut returns to the app root via loadout:// when it finishes,
        // and only *then* do we record history + confirm — so this can no
        // longer silently no-op or fake a success.
        macroFactorExport.begin(meal: meal)
        openURL(url)
        dismiss()
    }

    private func saveRecipe() {
        let trimmed = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? defaultRecipeName : trimmed
        let recipe = FavoriteMeal(
            name: name,
            restaurantId: store.restaurant.id,
            lineItems: store.lineItems
        )
        modelContext.insert(recipe)
        try? modelContext.save()
        Haptics.success()
        showNote("Saved to Recipes")
        // Don't clear or dismiss — saving is a side action; the user is
        // probably about to also log the meal.
    }

    private func copyForMyFitnessPal() {
        UIPasteboard.general.string = ExportService.quickAddText(
            name: defaultRecipeName,
            totals: store.totalMacros
        )
        Haptics.success()
        showNote("Copied — paste into Quick Add")
        openURL(ExportService.myFitnessPalURL)
    }

    private func copyRecipeJSON() {
        if let data = try? ExportService.recipeJSON(currentPayload) {
            UIPasteboard.general.string = String(decoding: data, as: UTF8.self)
            Haptics.success()
            showNote("Recipe JSON copied")
        }
    }

    private func showNote(_ text: String) {
        noteDismissTask?.cancel()
        withAnimation(Motion.snap) { exportNote = text }
        noteDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.snap) { exportNote = nil }
        }
    }

    private func note(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.appCaption.weight(.semibold))
            .foregroundStyle(.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background {
                Capsule()
                    .fill(Color.surfaceElevated)
                    .overlay(Capsule().strokeBorder(Color.volt.opacity(0.35), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Line item card

private struct LineItemCard: View {
    let lineItem: LineItem
    @Bindable var store: MealBuilderStore

    private var quantityBinding: Binding<Double> {
        Binding(
            get: { lineItem.quantity },
            set: { store.setQuantity(lineItemId: lineItem.id, to: $0) }
        )
    }

    var body: some View {
        Card(elevated: true, padding: Spacing.sm + Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(lineItem.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)
                    Spacer(minLength: Spacing.xs)
                    Text(lineItem.servingDescription)
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                        .lineLimit(1)
                    Button {
                        Haptics.tap()
                        withAnimation(Motion.glide) {
                            store.remove(lineItemId: lineItem.id)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(.textTertiary)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Remove \(lineItem.displayName)")
                }

                MacroBar(macros: lineItem.macros * lineItem.quantity, style: .inline)

                HStack {
                    QuickQuantityChips(value: quantityBinding)
                    Spacer(minLength: Spacing.sm)
                    QuantityStepper(value: quantityBinding, step: 0.5, range: 0...20)
                }
            }
        }
    }
}

// MARK: - Lazy share file

/// Transferable wrapper so the recipe JSON file is only written when
/// the user actually commits to sharing — not on every body pass.
private struct RecipeShareFile: Transferable {
    let payload: ExportService.RecipePayload

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { share in
            SentTransferredFile(try ExportService.writeShareFile(share.payload))
        }
    }
}
