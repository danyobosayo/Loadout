# Premium Phase 4 — Auto-Build Solver (design)

> "Build for my macros": given the user's budget (Health remaining, else daily target),
> construct a valid, editable meal at a restaurant that best hits it.

## Corrections applied after adversarial verification (implemented in MealSolver.swift)
The first draft below had real flaws the review caught; the shipped solver fixes them:
- **Feasible goal:** scale ALL macros by `s = calCap / budget.calories` (not just cap calories),
  so the per-meal goal is internally consistent instead of chasing whole-day protein/carbs inside
  a 1000-kcal cap.
- **Objective:** protein penalty is **one-sided** (only shortfall, never overshoot); **no calorie
  target term** — calories are a hard cap only (the old 2.0·relDev(cal) rewarded filler). Carbs/fat
  stay symmetric to steer toward the budget composition.
- **Seeds:** rank by **absolute protein** among items with `calories > 0` (zero-cal items — Subway
  has 11, Sweetgreen 5 — would NaN the protein-per-kcal divide; leafy greens/seasonings outranked
  real proteins).
- **Validity:** `allowed()` honors the category's **selectionRule** (min with the policy cap), so a
  Chipotle `tortilla` (selectUpTo 1) can't be emitted 3×.
- **Gating:** budget is signed (Health remaining can be ≤ 0); `canBuild` requires `≥ minMeal (150)`.
- **Navigation:** `MenuRoute` gains an `autoBuild` flag (it can't carry a seed as a Hashable value
  cleanly); `MenuView` runs the solver on appear and seeds itself.

---

> Original design (superseded in the specifics above; the structure/rationale still holds):

## Why not exhaustive branch-and-bound
Category → `PortionPolicy` (keyed by id): `rice/beans/bases/mains/protein/proteins → splitBase`;
`dips → cappedScoops(3)`, `dressings → cappedScoops(2)`, `dressing → cappedScoops(1)`; everything
else → `freeAddOns`. Two facts kill exhaustive search:
- **The protein source isn't always splitBase.** Chipotle `protein`, Subway `proteins`, CAVA
  `mains`, Sweetgreen `proteins` are splitBase — but **Panda `entrees` is freeAddOns** (default),
  and it's the protein driver. So the solver can't privilege splitBase.
- **freeAddOns categories are big + uncapped** (Sweetgreen `ingredients` 21, `dressings` 21;
  Subway `proteins`/`sauces` 18). 2^21 subsets per category ⇒ no full enumeration.

## Algorithm: protein-seeded greedy with restarts
Fast, general, good-enough (the output is a *suggestion* the user tweaks), and it handles
freeAddOns protein sources naturally.

```
solve(restaurant, target) -> [Suggestion]        // Suggestion = [(MenuItem, qty)] + score
  calCap   = min(target.calories, MEAL_CEILING)  // MEAL_CEILING = 1000 kcal, so a full-day
                                                 // budget doesn't yield a 2000-kcal monster
  goal     = Macros(calories: calCap, protein: target.protein, carbs: target.carbs, fat: target.fat)
  // Seeds: the K items with the best protein-per-kcal that fit under calCap alone.
  seeds    = topProteinPerCalorie(restaurant, calCap, K = SEED_COUNT=4)
  builds   = []
  for seed in ([] + seeds):                      // also one unseeded greedy run
     builds.append(greedyFill(startingFrom: seed, restaurant, goal, calCap))
  return dedup(builds).sortedByScore().prefix(3)

greedyFill(start, restaurant, goal, calCap) -> Build
  build = start
  loop up to MAX_STEPS (15):
     best = argmin over every candidate (item, +1) that is ALLOWED and keeps calories<=calCap
            of score(build + candidate, goal)
     if best exists AND score improves: apply best
     else break
  return build
```

**Allowed(item, build)** enforces the policy of the item's category:
- `splitBase`: at most one *distinct* item in the category; that item's qty ∈ {1, 2}. (So a
  second splitBase item is disallowed; doubling the chosen one is allowed. ½+½ splits are left to
  the user — the solver picks whole/ double portions only.)
- `cappedScoops(max)`: category total qty ≤ max; each item integer ≥ 1.
- `freeAddOns`: each item qty ∈ {1, 2}; **≤ FREE_ADDON_CAP (3) distinct items per category** for
  reasonableness (no "10 sauces").
- Global: `build.calories + item.macros.calories ≤ calCap`.

**score(build, goal)** — lower is better; protein-first, calories anchored to the cap:
```
relDev(x, t) = t > 0 ? abs(x - t) / t : (x > 0 ? 1 : 0)
score = 3.0·relDev(protein) + 2.0·relDev(calories) + 0.5·relDev(carbs) + 0.5·relDev(fat)
```
The calorie term pulls the meal toward the budget (not just "any feasible"); protein dominates.

## Reasonableness / termination
- Bounded: ≤ (1 + SEED_COUNT) greedy runs × MAX_STEPS steps × O(items) per step ⇒ a few thousand
  score evals worst case. Milliseconds.
- Never returns empty when the menu has an item under calCap: the unseeded/seeded runs add at
  least the seed. If *nothing* fits under calCap (tiny budget), return the single lowest-calorie
  protein item and flag it (UI: "your remaining budget is very small").
- Determinism: stable sort + fixed tie-breaks (by item id) ⇒ same input → same output (testable).

## Target framing
- `budget = health.remaining(against: target) ?? profile.target` (the same source Budget Mode
  uses). Most valuable with Health (what's left today); without Health it targets the full day but
  the MEAL_CEILING keeps the suggestion a single realistic meal.
- Requires a goal. No goal ⇒ the entry point is hidden / prompts to set one.

## Surfacing (entry point)
`FormatPickerView` gains a **"Fit my macros"** card at the top (volt, only when `profile.target`
exists). Tap → run `MealSolver.solve` for that restaurant + budget → navigate into
`MenuView(restaurant:, seed: bestSuggestion.asLineItems)` — the existing seed path (same as
re-opening a recipe), so the result lands in the tray fully editable. The tray's Budget Mode
(Phase 3) then shows the fit immediately.

Output conversion: each `(MenuItem, qty)` → `LineItem(id: UUID(), menuItemId: item.id,
displayName: item.name, servingDescription: item.servingDescription, macros: item.macros,
quantity: qty, iconName: item.iconName ?? category.iconName)`.

## New files
```
Loadout/Services/MealSolver.swift          — pure solver (nonisolated enum), MealSolver.solve
Loadout/Features/Formats/...               — "Fit my macros" card wiring in FormatPickerView
LoadoutTests/MealSolverTests.swift
LoadoutUITests (extend) — screenshot the suggested build landing in the tray
```

## Tests (pure, per restaurant)
For chipotle / cava / panda / subway / sweetgreen, given a mid-size target (e.g. 700 kcal / 50 g
protein):
- **Valid**: no two distinct splitBase items in one category; cappedScoops totals ≤ cap; ≤ 3
  distinct freeAddOns per category; total calories ≤ calCap.
- **Non-empty** and **has protein**: the build contains a meaningful protein source (proves the
  freeAddOns-protein path works for **Panda**).
- **Under cap**, and **protein is reasonably close** to the (achievable) target.
- **Deterministic**: solve twice → identical.
- **Tiny budget** (150 kcal): returns something valid (the fallback), never crashes.
- **No goal**: solver isn't called; entry hidden (UI test / guard).

## Out of scope (v1)
½+½ splits in the solver, multi-scoop scoop distributions, allergen/preference filters, location.
Beam search (a better-than-greedy upgrade) noted for later if quality needs it.
