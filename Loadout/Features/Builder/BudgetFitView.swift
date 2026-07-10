import SwiftUI

/// Budget Mode — how the built meal fits the day's budget (Health remaining, or
/// the full daily target). A headline verdict plus a per-macro gauge that fills
/// toward the budget and flips amber when over.
struct BudgetFitView: View {
    let fit: BudgetFit

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                header
                VStack(spacing: Spacing.sm) {
                    gauge(.calories, meal: fit.meal.calories, budget: fit.budget.calories, keyPath: \.calories)
                    gauge(.protein, meal: fit.meal.proteinGrams, budget: fit.budget.proteinGrams, keyPath: \.proteinGrams)
                    gauge(.carbs, meal: fit.meal.carbGrams, budget: fit.budget.carbGrams, keyPath: \.carbGrams)
                    gauge(.fat, meal: fit.meal.fatGrams, budget: fit.budget.fatGrams, keyPath: \.fatGrams)
                }
            }
        }
        .animation(Motion.snap, value: fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var over: Bool { !fit.fitsCalories }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: over ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(over ? Color.fat : Color.volt)
            VStack(alignment: .leading, spacing: 1) {
                Text(over
                     ? "Over by \(Int(-fit.caloriesLeftAfter.rounded())) kcal"
                     : "\(Int(fit.caloriesLeftAfter.rounded())) kcal left")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Text("of \(fit.basis.noun)")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
            Spacer(minLength: 0)
        }
    }

    private func gauge(_ kind: MacroDisplay.Kind, meal: Double, budget: Double, keyPath: KeyPath<Macros, Double>) -> some View {
        let isOver = fit.isOver(keyPath)
        let fraction = fit.fraction(keyPath)
        return HStack(spacing: Spacing.sm) {
            Text(kind.shortLabel)
                .microLabelStyle(kind.color)
                .lineLimit(1)
                .frame(width: 34, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(isOver ? Color.fat : kind.color)
                        .frame(width: max(geo.size.width * fraction, fraction > 0 ? 3 : 0))
                }
            }
            .frame(height: 6)
            Text("\(Int(meal.rounded())) / \(Int(budget.rounded()))")
                .font(.appCaption)
                .monospacedDigit()
                .foregroundStyle(isOver ? Color.fat : .textSecondary)
                .frame(width: 78, alignment: .trailing)
        }
    }

    private var accessibilityText: String {
        let lead = over
            ? "Over budget by \(Int(-fit.caloriesLeftAfter.rounded())) calories"
            : "\(Int(fit.caloriesLeftAfter.rounded())) calories left of \(fit.basis.noun)"
        return "Budget. \(lead)."
    }
}
