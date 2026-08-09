import AppIntents
import Foundation
import SwiftData

/// Read-only: what's in a saved recipe. No permissions, no side effects, works
/// from the Lock Screen — the one that should never fail.
struct RecipeMacrosIntent: AppIntent {
    static let title: LocalizedStringResource = "Check a recipe's macros"
    static let description = IntentDescription(
        "Reads back the calories and macros of a saved recipe.",
        categoryName: "Recipes"
    )
    /// Answers out loud without launching the app.
    static let openAppWhenRun = false

    @Parameter(title: "Recipe")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the macros for \(\.$recipe)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let m = recipe.macros
        let spoken = "\(recipe.name): \(Int(m.calories.rounded())) calories, "
            + "\(Int(m.proteinGrams.rounded())) grams protein, "
            + "\(Int(m.carbGrams.rounded())) carbs, "
            + "\(Int(m.fatGrams.rounded())) fat."
        return .result(value: ExportService.summaryLine(m), dialog: IntentDialog(stringLiteral: spoken))
    }
}

/// Writes a saved recipe to Apple Health as one food entry. Runs without
/// launching the app, which is the whole point — "log my usual Chipotle" should
/// be one sentence, not a sentence plus four taps.
struct LogRecipeToHealthIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a recipe to Apple Health"
    static let description = IntentDescription(
        "Logs a saved recipe to Apple Health as a food entry.",
        categoryName: "Recipes"
    )
    static let openAppWhenRun = false

    @Parameter(title: "Recipe")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$recipe) to Apple Health")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let health = HealthStore()
        let ok = await health.logMeal(named: recipe.name, macros: recipe.macros)
        guard ok else {
            // A thrown error reads better in Shortcuts than a cheerful dialog
            // that quietly logged nothing.
            throw LoadoutIntentError.healthUnavailable
        }
        recordHistory(for: recipe)
        return .result(dialog: "Logged \(recipe.name) — \(Int(recipe.macros.calories.rounded())) calories.")
    }

    /// Keep History honest: a meal logged by Siri is still a meal you logged.
    @MainActor
    private func recordHistory(for recipe: RecipeEntity) {
        guard let container = LoadoutStore.shared else { return }
        let context = ModelContext(container)
        let id = recipe.id
        let descriptor = FetchDescriptor<FavoriteMeal>(predicate: #Predicate { $0.id == id })
        guard let saved = try? context.fetch(descriptor).first else { return }
        context.insert(LoggedMeal(
            restaurantId: saved.restaurantId,
            lineItems: saved.lineItems
        ))
        try? context.save()
        try? LoggedMealRetention.enforceLimit(in: context)
    }
}

/// Opens the app with a recipe loaded in the tray, ready to hand to
/// MacroFactor. The hand-off itself needs the app foregrounded — it opens
/// Shortcuts with an x-callback — so this one deliberately launches.
struct OpenRecipeIntent: AppIntent {
    static let title: LocalizedStringResource = "Open a recipe in Loadout"
    static let description = IntentDescription(
        "Opens Loadout with a saved recipe in the tray, ready to log or edit.",
        categoryName: "Recipes"
    )
    static let openAppWhenRun = true

    @Parameter(title: "Recipe")
    var recipe: RecipeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$recipe) in Loadout")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingIntentRoute.shared.recipeToOpen = recipe.id
        return .result()
    }
}

nonisolated enum LoadoutIntentError: Error, CustomLocalizedStringResourceConvertible {
    case healthUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .healthUnavailable:
            "Couldn't write to Apple Health. Open Loadout → Settings → Apple Health and connect it first."
        }
    }
}

/// A one-slot handoff from an intent into the running app. `OpenRecipeIntent`
/// sets it, `RootView` consumes it on the next appear and clears it.
@MainActor
@Observable
final class PendingIntentRoute {
    static let shared = PendingIntentRoute()
    var recipeToOpen: UUID?
    private init() {}
}

/// The phrases Siri recognises without the user building a shortcut first.
nonisolated struct LoadoutShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogRecipeToHealthIntent(),
            phrases: [
                "Log \(\.$recipe) with \(.applicationName)",
                "Log my \(\.$recipe) in \(.applicationName)",
            ],
            shortTitle: "Log a recipe",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: RecipeMacrosIntent(),
            phrases: [
                "What's in my \(\.$recipe) on \(.applicationName)",
                "\(.applicationName) macros for \(\.$recipe)",
            ],
            shortTitle: "Check macros",
            systemImageName: "chart.bar.fill"
        )
        AppShortcut(
            intent: OpenRecipeIntent(),
            phrases: ["Open \(\.$recipe) in \(.applicationName)"],
            shortTitle: "Open a recipe",
            systemImageName: "fork.knife"
        )
    }
}
