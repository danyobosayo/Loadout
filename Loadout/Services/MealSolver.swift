import Foundation

/// Auto-build: given a restaurant menu + a per-meal budget, greedily construct a
/// valid, editable meal that best hits it — **protein-first, calories as a hard
/// cap**. Pure + deterministic. Design verified before build; see
/// `PREMIUM_PHASE4_SOLVER.md`.
///
/// Two properties matter as much as hitting the numbers, and the first draft
/// had neither:
///
/// * **Calories are never free.** The original objective scored only macro
///   deviation, so once protein was met, filling the remaining calorie headroom
///   cost nothing — Sweetgreen came back as bacon and three breads. Every build
///   now pays for the calories it spends, and pays *more* when the budget isn't
///   the binding constraint (the first meal of the day should be lean and
///   protein-dense, not a 1100-kcal meal just because 1100 was available).
/// * **A meal has a base.** Optimising macros alone will skip it: Chipotle came
///   back as beans, meat and a tortilla with no rice at all, which reads as
///   broken even when the numbers are fine.
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
    /// An item has to actually improve the meal to earn a place on it. Without
    /// a floor here, anything near-zero-calorie (seasonings, hot sauce, a
    /// squeeze of lemon) gets added for a rounding-error gain and the
    /// suggestion arrives cluttered with garnish.
    private static let minImprovement = 0.01

    /// Stations that count as the thing the meal sits on, in preference order.
    /// `tortilla` is deliberately absent — it's an optional vessel, not a base,
    /// and treating it as one is how a "bowl" ended up as a bare tortilla.
    private static let baseCategoryIds = ["bases", "rice", "crusts", "breads"]

    /// Stations that read as vegetables for the veg-forward focus.
    private static let vegetableCategoryIds: Set<String> = ["veggies", "toppings", "ingredients", "salsa"]

    /// Whether there's a sensible meal to build for this budget (drives the
    /// entry point's visibility). Budgets can be signed (Health remaining), so
    /// a non-positive / tiny budget means "nothing to build."
    static func canBuild(budget: Macros) -> Bool { budget.calories >= minMeal }

    /// Best-fitting meal, or nil when the budget is too small (see `canBuild`).
    static func solve(
        restaurant: Restaurant,
        budget: Macros,
        preferences: AutoBuildPreferences = .default
    ) -> Suggestion? {
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

        // Is the remaining budget what actually limits this meal? Late in the
        // day it is, and spending what's left is the right call. First thing in
        // the morning it isn't — the ceiling is, and chasing whole-day carb and
        // fat numbers into it produces exactly the filler we don't want.
        let budgetIsBinding = budget.calories <= mealCeiling
        let objective = Objective(
            goal: goal,
            calCap: calCap,
            weights: Weights(focus: preferences.focus, budgetIsBinding: budgetIsBinding)
        )

        let candidates = candidateList(restaurant, excluding: preferences.exclusions)
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

        // Every run starts on a base where the menu has one, so the base is
        // chosen *for* the meal rather than left out of it.
        var builds: [[String: Pick]] = [greedy(from: seededBase([:], candidates, objective), objective: objective, candidates: candidates)]
        for seed in seeds {
            var start = [seed.item.id: Pick(item: seed.item, categoryId: seed.categoryId, iconName: seed.iconName, quantity: 1)]
            start = seededBase(start, candidates, objective)
            builds.append(greedy(from: start, objective: objective, candidates: candidates))
        }

        let order = categoryOrder(restaurant)
        return builds
            .map { suggestion(from: $0, objective: objective, order: order) }
            .filter { !$0.picks.isEmpty }
            .min { $0.score < $1.score }
    }

    /// Put a base under the build before the greedy pass fills around it.
    /// No-op when the menu has no base station, when one is already present, or
    /// when nothing fits the cap — a suggestion without a base still beats none.
    private static func seededBase(
        _ build: [String: Pick],
        _ candidates: [Candidate],
        _ objective: Objective
    ) -> [String: Pick] {
        guard !build.values.contains(where: { baseCategoryIds.contains($0.categoryId) }) else { return build }
        guard let baseId = baseCategoryIds.first(where: { id in candidates.contains { $0.categoryId == id } })
        else { return build }

        let options = candidates.filter {
            $0.categoryId == baseId
                && allowed($0, in: build)
                && macros(of: build).calories + $0.item.macros.calories <= objective.calCap
        }
        // Score each option in place; ties break on id so the result is stable.
        let best = options.min { lhs, rhs in
            let l = score(withOneMore: lhs, added: build, objective)
            let r = score(withOneMore: rhs, added: build, objective)
            return l != r ? l < r : lhs.item.id < rhs.item.id
        }
        guard let best else { return build }
        var seeded = build
        seeded[best.item.id] = Pick(item: best.item, categoryId: best.categoryId, iconName: best.iconName, quantity: 1)
        return seeded
    }

    private static func score(withOneMore c: Candidate, added build: [String: Pick], _ objective: Objective) -> Double {
        var trial = build
        trial[c.item.id, default: Pick(item: c.item, categoryId: c.categoryId, iconName: c.iconName, quantity: 0)].quantity += 1
        return score(trial, objective)
    }

    // MARK: Greedy

    private static func greedy(
        from start: [String: Pick],
        objective: Objective,
        candidates: [Candidate]
    ) -> [String: Pick] {
        var build = start
        var currentScore = score(build, objective)

        for _ in 0..<maxSteps {
            var bestCandidate: Candidate?
            var bestScore = currentScore
            for c in candidates {                                   // pre-sorted → deterministic
                guard allowed(c, in: build) else { continue }
                guard macros(of: build).calories + c.item.macros.calories <= objective.calCap else { continue }
                let sc = score(withOneMore: c, added: build, objective)
                if sc < bestScore - minImprovement {                // strict → first (lowest id) wins ties
                    bestScore = sc; bestCandidate = c
                }
            }
            guard let cand = bestCandidate else { break }
            build[cand.item.id, default: Pick(item: cand.item, categoryId: cand.categoryId, iconName: cand.iconName, quantity: 0)].quantity += 1
            currentScore = bestScore
        }
        return build
    }

    // MARK: Objective

    private struct Weights {
        let protein: Double
        let carbs: Double
        let fat: Double
        /// One-sided means only *overshoot* is punished. Undershooting carbs or
        /// fat is not a problem when the day is wide open — but a symmetric
        /// term actively rewards adding filler to reach a whole-day number, and
        /// with fat that means bacon and cheese get treated as progress.
        let carbsExcessOnly: Bool
        let fatExcessOnly: Bool
        /// What a calorie costs. This is the term that stops the build padding
        /// itself out to the cap once the macros are met.
        let efficiency: Double
        let vegetables: Double
        let volume: Double

        init(focus: AutoBuildFocus, budgetIsBinding: Bool) {
            // When what's left in the day is the real constraint, spending it is
            // the point: chase the composition symmetrically, charge little for
            // calories. When it isn't, the carb/fat targets are whole-day
            // numbers that mean nothing for one meal — so only punish going
            // over, and make calories expensive.
            var protein = 3.0
            var carbs = budgetIsBinding ? 0.6 : 0.5
            var fat = budgetIsBinding ? 0.4 : 0.8
            var carbsExcessOnly = !budgetIsBinding
            var fatExcessOnly = !budgetIsBinding
            var efficiency = budgetIsBinding ? 0.25 : 1.2
            var vegetables = 0.0
            var volume = 0.0

            switch focus {
            case .balanced:
                // Chase carbs both ways so a "balanced" meal still arrives with
                // a real base under it, while fat stays excess-only so the
                // carb-chasing doesn't turn into a fat free-for-all.
                carbsExcessOnly = false
            case .protein:
                carbs = 0.3
                carbsExcessOnly = true
                // Lean *and* high protein: without the fat penalty this just
                // finds the calorie-cheapest protein, which is cured meat and
                // hard cheese.
                protein = 4.5
                fat = 1.1
                fatExcessOnly = true
                efficiency += 0.6
            case .carbs:
                carbs = budgetIsBinding ? 1.3 : 0.9
                carbsExcessOnly = false           // the point is to reach it
                efficiency = max(0.1, efficiency - 0.4)
            case .fat:
                fat = budgetIsBinding ? 1.3 : 0.9
                fatExcessOnly = false             // the point is to reach it
                efficiency = max(0.1, efficiency - 0.4)
            case .vegetables:
                vegetables = 1.4
            case .volume:
                volume = 1.4
                efficiency += 0.3                 // more food, not more calories
            }
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.carbsExcessOnly = carbsExcessOnly
            self.fatExcessOnly = fatExcessOnly
            self.efficiency = efficiency
            self.vegetables = vegetables
            self.volume = volume
        }
    }

    private struct Objective {
        let goal: Macros
        let calCap: Double
        let weights: Weights
    }

    /// Protein-first and one-sided (only shortfall is penalized, never
    /// overshoot); carbs/fat symmetric to steer toward the budget composition;
    /// calories capped hard *and* charged for. Lower is better.
    ///
    /// The focus bonuses are capped rather than per-item so they can't run the
    /// greedy loop to `maxSteps` just to farm more of them.
    private static func score(_ build: [String: Pick], _ o: Objective) -> Double {
        let m = macros(of: build)
        let proteinShortfall = max(0, o.goal.proteinGrams - m.proteinGrams) / max(o.goal.proteinGrams, 1)
        let carbDev = deviation(m.carbGrams, o.goal.carbGrams, excessOnly: o.weights.carbsExcessOnly)
        let fatDev = deviation(m.fatGrams, o.goal.fatGrams, excessOnly: o.weights.fatExcessOnly)

        var total = o.weights.protein * proteinShortfall
            + o.weights.carbs * carbDev
            + o.weights.fat * fatDev
            + o.weights.efficiency * (m.calories / max(o.calCap, 1))

        if o.weights.vegetables > 0 {
            let servings = build.values
                .filter { vegetableCategoryIds.contains($0.categoryId) }
                .reduce(0) { $0 + $1.quantity }
            total -= o.weights.vegetables * min(servings, 6) / 6
        }
        if o.weights.volume > 0 {
            let servings = build.values.reduce(0) { $0 + $1.quantity }
            total -= o.weights.volume * min(servings, 10) / 10
        }
        return total
    }

    private static func deviation(_ actual: Double, _ target: Double, excessOnly: Bool) -> Double {
        let delta = excessOnly ? max(0, actual - target) : abs(actual - target)
        return delta / max(target, 1)
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

    private static func candidateList(
        _ restaurant: Restaurant,
        excluding exclusions: Set<AutoBuildExclusion>
    ) -> [Candidate] {
        let blocked = exclusions.reduce(into: Set<String>()) { $0.formUnion($1.excludedCategoryIds) }
        return restaurant.categories
            .filter { !blocked.contains($0.id) }
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

    /// Menu order, so a suggestion reads the way the counter is laid out —
    /// base first, then protein, then the add-ons. Sorting by item id instead
    /// scattered the base into the middle of the tray, which is why a Chipotle
    /// suggestion read as a pile of toppings with no visible foundation.
    private static func categoryOrder(_ restaurant: Restaurant) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: restaurant.categories.enumerated().map { ($1.id, $0) })
    }

    private static func suggestion(
        from build: [String: Pick],
        objective: Objective,
        order: [String: Int]
    ) -> Suggestion {
        let picks = build.values
            .filter { $0.quantity > 0 }
            .sorted { lhs, rhs in
                let l = order[lhs.categoryId] ?? .max
                let r = order[rhs.categoryId] ?? .max
                return l != r ? l < r : lhs.item.id < rhs.item.id
            }
        return Suggestion(picks: picks, macros: macros(of: build), score: score(build, objective))
    }
}
