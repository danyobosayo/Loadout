import Foundation

/// Auto-build: given a restaurant menu + a per-meal budget, greedily construct a
/// valid, editable meal that best hits it — **protein-first, calories as a hard
/// cap**. Pure + deterministic. Design verified before build; see
/// `PREMIUM_PHASE4_SOLVER.md`.
nonisolated enum MealSolver {
    struct Pick: Hashable, Sendable {
        let item: MenuItem
        let categoryId: String
        let iconName: String?
        var quantity: Double
    }

    struct Suggestion: Sendable {
        let picks: [Pick]
        let macros: Macros
        let score: Double

        var lineItems: [LineItem] {
            picks.map { p in
                LineItem(
                    id: UUID(),
                    menuItemId: p.item.id,
                    displayName: p.item.name,
                    servingDescription: p.item.servingDescription,
                    macros: p.item.macros,
                    quantity: p.quantity,
                    iconName: p.iconName
                )
            }
        }
    }

    // MARK: Tunables
    static let minMeal = 150.0            // don't offer auto-build below this budget
    private static let mealCeiling = 1100.0
    private static let seedCount = 4
    private static let maxSteps = 16
    private static let freeAddonCap = 3

    /// Whether there's a sensible meal to build for this budget (drives the
    /// entry point's visibility). Budgets can be signed (Health remaining), so
    /// a non-positive / tiny budget means "nothing to build."
    static func canBuild(budget: Macros) -> Bool { budget.calories >= minMeal }

    /// Best-fitting meal, or nil when the budget is too small (see `canBuild`).
    static func solve(restaurant: Restaurant, budget: Macros) -> Suggestion? {
        guard canBuild(budget: budget) else { return nil }

        // Scale the WHOLE goal to the meal (calories AND macros by the same
        // factor) so the target stays internally feasible.
        let calCap = min(budget.calories, mealCeiling)
        let s = calCap / budget.calories
        let goal = Macros(
            calories: calCap,
            proteinGrams: max(0, budget.proteinGrams * s),
            carbGrams: max(0, budget.carbGrams * s),
            fatGrams: max(0, budget.fatGrams * s)
        )

        let candidates = candidateList(restaurant)                 // sorted by id (determinism)
        guard !candidates.isEmpty else { return nil }

        // Seeds: highest ABSOLUTE protein among real items that fit alone under
        // the cap (calories > 0 guards the zero-cal divide + garnish).
        let seeds = candidates
            .filter { $0.item.macros.calories > 0
                   && $0.item.macros.calories <= calCap
                   && $0.item.macros.proteinGrams > 0 }
            .sorted { lhs, rhs in
                lhs.item.macros.proteinGrams != rhs.item.macros.proteinGrams
                    ? lhs.item.macros.proteinGrams > rhs.item.macros.proteinGrams
                    : lhs.item.id < rhs.item.id
            }
            .prefix(seedCount)

        var builds: [[String: Pick]] = [greedy(from: [:], goal: goal, calCap: calCap, candidates: candidates)]
        for seed in seeds {
            let start = [seed.item.id: Pick(item: seed.item, categoryId: seed.categoryId, iconName: seed.iconName, quantity: 1)]
            builds.append(greedy(from: start, goal: goal, calCap: calCap, candidates: candidates))
        }

        return builds
            .map { suggestion(from: $0, goal: goal) }
            .filter { !$0.picks.isEmpty }
            .min { $0.score < $1.score }
    }

    // MARK: Greedy

    private static func greedy(
        from start: [String: Pick],
        goal: Macros,
        calCap: Double,
        candidates: [Candidate]
    ) -> [String: Pick] {
        var build = start
        var current = macros(of: build)
        var currentScore = score(current, goal: goal)

        for _ in 0..<maxSteps {
            var bestCandidate: Candidate?
            var bestScore = currentScore
            var bestMacros = current
            for c in candidates {                                   // pre-sorted → deterministic
                guard allowed(c, in: build) else { continue }
                let m = current + c.item.macros
                guard m.calories <= calCap else { continue }
                let sc = score(m, goal: goal)
                if sc < bestScore - 1e-9 {                          // strict → first (lowest id) wins ties
                    bestScore = sc; bestCandidate = c; bestMacros = m
                }
            }
            guard let cand = bestCandidate else { break }
            build[cand.item.id, default: Pick(item: cand.item, categoryId: cand.categoryId, iconName: cand.iconName, quantity: 0)].quantity += 1
            current = bestMacros
            currentScore = bestScore
        }
        return build
    }

    /// Protein-first, one-sided (only shortfall is penalized, never overshoot);
    /// carbs/fat symmetric to steer toward the budget composition; calories are
    /// a hard cap, not a scored target. Lower is better.
    private static func score(_ m: Macros, goal: Macros) -> Double {
        let proteinShortfall = max(0, goal.proteinGrams - m.proteinGrams) / max(goal.proteinGrams, 1)
        let carbDev = abs(m.carbGrams - goal.carbGrams) / max(goal.carbGrams, 1)
        let fatDev = abs(m.fatGrams - goal.fatGrams) / max(goal.fatGrams, 1)
        return 3.0 * proteinShortfall + 0.6 * carbDev + 0.4 * fatDev
    }

    // MARK: Validity (policy AND selectionRule)

    /// Can we add one more of `c` to `build`? Honors the portion policy *and*
    /// the category's real `selectionRule` (which is stricter for select-one
    /// vessels like a Chipotle tortilla).
    private static func allowed(_ c: Candidate, in build: [String: Pick]) -> Bool {
        let currentQty = build[c.item.id]?.quantity ?? 0
        let inCategory = build.values.filter { $0.categoryId == c.categoryId }
        let distinct = inCategory.count
        let categoryTotal = inCategory.reduce(0) { $0 + $1.quantity }
        let isNew = currentQty == 0

        switch c.policy {
        case .splitBase:
            if isNew && distinct >= 1 { return false }              // one base item
            return currentQty + 1 <= 2                              // whole or double
        case .cappedScoops(let max):
            if categoryTotal + 1 > Double(max) { return false }
            if isNew && distinct >= maxDistinct(c) { return false }
            return true
        case .freeAddOns:
            if currentQty + 1 > 2 { return false }
            if isNew && distinct >= maxDistinct(c) { return false }
            return true
        }
    }

    private static func maxDistinct(_ c: Candidate) -> Int {
        let ruleCap: Int
        switch c.selectionRule {
        case .selectOne: ruleCap = 1
        case .selectUpTo(let n): ruleCap = n
        case .selectMany: ruleCap = .max
        }
        let policyCap: Int
        switch c.policy {
        case .splitBase: policyCap = 1
        case .cappedScoops(let max): policyCap = max
        case .freeAddOns: policyCap = freeAddonCap
        }
        return min(ruleCap, policyCap)
    }

    // MARK: Helpers

    private struct Candidate {
        let item: MenuItem
        let categoryId: String
        let iconName: String?
        let policy: PortionPolicy
        let selectionRule: SelectionRule
    }

    private static func candidateList(_ restaurant: Restaurant) -> [Candidate] {
        restaurant.categories
            .flatMap { category in
                category.items.map { item in
                    Candidate(
                        item: item,
                        categoryId: category.id,
                        iconName: item.iconName ?? category.iconName,
                        policy: category.portionPolicy,
                        selectionRule: category.selectionRule
                    )
                }
            }
            .sorted { $0.item.id < $1.item.id }
    }

    private static func macros(of build: [String: Pick]) -> Macros {
        build.values.reduce(.zero) { $0 + $1.item.macros * $1.quantity }
    }

    private static func suggestion(from build: [String: Pick], goal: Macros) -> Suggestion {
        let picks = build.values
            .filter { $0.quantity > 0 }
            .sorted { $0.item.id < $1.item.id }
        let total = macros(of: build)
        return Suggestion(picks: picks, macros: total, score: score(total, goal: goal))
    }
}
