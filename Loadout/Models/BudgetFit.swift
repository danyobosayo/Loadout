import Foundation

/// How a built meal fits a daily budget — either what's *left* today (Apple
/// Health remaining) or the full daily *target* when Health isn't connected.
/// Pure and testable; drives Budget Mode in the builder + tray.
nonisolated struct BudgetFit: Equatable, Sendable {
    enum Basis: Equatable, Sendable {
        case remaining   // target − consumed (Health connected)
        case target      // full daily target (no Health)

        var noun: String {
            switch self {
            case .remaining: "what's left today"
            case .target: "your daily target"
            }
        }
    }

    let meal: Macros
    let budget: Macros
    let basis: Basis

    /// Build a fit for the current meal. Prefers Health "remaining" when
    /// present; falls back to the full target. Nil when no goal is set.
    static func make(meal: Macros, target: Macros?, remaining: Macros?) -> BudgetFit? {
        guard let target else { return nil }
        if let remaining {
            return BudgetFit(meal: meal, budget: remaining, basis: .remaining)
        }
        return BudgetFit(meal: meal, budget: target, basis: .target)
    }

    var fitsCalories: Bool { meal.calories <= budget.calories }
    /// Signed — negative means the meal is over the calorie budget.
    var caloriesLeftAfter: Double { budget.calories - meal.calories }

    /// Share of the calorie budget this meal uses, clamped 0…1 for the gauge
    /// (over-budget is reported via `fitsCalories`, not by exceeding 1).
    var calorieFraction: Double {
        guard budget.calories > 0 else { return meal.calories > 0 ? 1 : 0 }
        return min(meal.calories / budget.calories, 1)
    }

    /// Per-macro fill fraction (0…1) for one component's mini gauge.
    func fraction(_ component: KeyPath<Macros, Double>) -> Double {
        let b = budget[keyPath: component]
        let m = meal[keyPath: component]
        guard b > 0 else { return m > 0 ? 1 : 0 }
        return min(m / b, 1)
    }

    /// Whether the meal exceeds the budget for one component.
    func isOver(_ component: KeyPath<Macros, Double>) -> Bool {
        meal[keyPath: component] > budget[keyPath: component] && budget[keyPath: component] > 0
    }
}
