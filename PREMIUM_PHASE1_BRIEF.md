# Loadout — Premium Phase 1 Brief: Macro Targets

> Planning brief. Hand to a planning model; execution follows separately.
> Self-contained on purpose — assumes no prior conversation.

## What Loadout is
iOS SwiftUI app (iOS 18 target, Swift 6 strict concurrency, `@Observable`/`@MainActor`,
SwiftData for persisted collections). A fast-casual **meal builder**: pick a restaurant
(Chipotle, CAVA, Panda Express, Sweetgreen, Subway) → build a meal via guided "format"
prompts or a "Build your own" station list → see live macros → log/export to MacroFactor
(a Shortcuts x-callback) → save recipes, keep history, in-menu search.

Design system **OBSIDIAN**: void `#0B0B0F` background, volt `#C8FF4D` accent; macro colors
(protein `#FF7A6B`, carbs `#56C8F5`, fat `#FFC94D`). Tokens live in `Loadout/DesignSystem`
(`Spacing`, `Radius`, `Motion`, `Colors`, `Typography`, and `Components/`: `Card`, `MacroBar`,
`MacroRing`, `QuantityStepper`, `Backdrop`, `Haptics`, button styles `.pressable` /
`.primaryAction` / `.ghost`, `.microLabelStyle()`). Product spec: `PROJECT.md`. Visual spec:
`STYLE_GUIDE.md`.

## The premium direction (already decided)
Loadout is evolving from "log what I built" → "help me decide what to order to hit my macros."
The Pro tier is a **targeting / decider layer**, phased:

1. **Macro targets** ← *this phase*: set a daily macro target — **generate** from a goal
   calculator **or paste** an existing one.
2. **HealthKit read → "remaining today"**: consumed-from-Health, so remaining = target −
   consumed. *(Needs the HealthKit entitlement — NOT this phase.)*
3. **Budget Mode**: live "does this build fit my remaining macros?" in the builder.
4. **Auto-build solver**: bounded branch-and-bound over a restaurant's menu (respecting the
   existing build rules / `PortionPolicy`) to construct an order that hits the target. Output
   lands in the editable builder as a suggestion. Crown jewel.
5. **More exports** (Cronometer, Apple Health direct-write, a generic App Intent); **location**
   awareness last, once restaurant coverage justifies it.

Free stays a **complete logger** (protects word-of-mouth). Pro is the targeting layer. **Paywall
gating is a later step — do not gate anything in this phase; just build the capability.**

## Phase 1 scope — what to plan
Build the macro-target foundation. Pure Swift + SwiftUI, **no new entitlements**, fully
unit-testable.

1. **Target model.** Reuse the existing `Macros` value type (`calories`, `proteinGrams`,
   `carbGrams`, `fatGrams`) as the target numbers. Wrap in a `MacroGoal` value type that also
   records: `source` (`.generated` / `.manual`), the input profile used when generated (so it's
   re-editable), and `updatedAt`. `Codable`, `Sendable`.
2. **`MacroTargetCalculator`** — a pure function: profile inputs → target `Macros`. Formulas below.
3. **Persistence.** Single-user profile → follow the **`SettingsStore` pattern**
   (`@MainActor @Observable`, UserDefaults-backed, injected at the app root via `.environment`).
   Either extend `SettingsStore` or add a sibling `ProfileStore` holding the `MacroGoal` (Codable →
   JSON in UserDefaults). Inject in `Loadout/App/LoadoutApp.swift` alongside `settings` /
   `macroFactorExport`. **Do not** use SwiftData for this (SwiftData is for the `FavoriteMeal` /
   `LoggedMeal` collections; a single profile is a preference).
4. **Goal-setup UI** — a reusable `GoalSetupView` with two paths:
   - **Generate**: collect sex, age, height, current weight, activity level, goal
     (lose / maintain / gain), goal weight + timeframe (to derive the rate). Show the computed
     target with an editable review.
   - **Paste**: enter calories + P/C/F directly (copy from MacroFactor / a coach).
   - Include the health disclaimer + calorie-floor note (below).
5. **Onboarding + Settings integration.** The app has an existing `OnboardingView` (a MacroFactor
   explainer) gated by `SettingsStore.hasCompletedOnboarding`, shown via `fullScreenCover` in
   `RootView`. Add goal setup to the first-run flow (a step in / right after onboarding) **and**
   make `GoalSetupView` reusable so `SettingsView` can present it to edit anytime. Keep goal
   setup **skippable** — Phase 1 gates nothing on it.
6. **Surface the target** (lightweight): show the current target in Settings (and optionally a
   compact readout elsewhere) so it's visible/editable. Full consumption (Budget Mode, solver) is
   a later phase — this phase captures / persists / edits.
7. **Tests** — Swift Testing (`import Testing`, `@Test`, `#expect`) in `LoadoutTests`. Cover the
   calculator vs known BMR/TDEE values, goal deltas, the calorie-floor clamp, and the macro split
   (protein anchoring, non-negative carbs). Add a UI smoke test in `LoadoutUITests` if the flow
   warrants it.

## Calculator spec (concrete defaults — tunable)
- **BMR (Mifflin–St Jeor)** — weight kg, height cm, age yr:
  - Male: `10·kg + 6.25·cm − 5·age + 5`
  - Female: `10·kg + 6.25·cm − 5·age − 161`
  - "Unspecified" → average the two.
- **TDEE = BMR × activity:** sedentary 1.2 · light 1.375 · moderate 1.55 · very 1.725 · extra 1.9.
- **Goal delta:** from goal weight + timeframe → weekly weight change → daily calorie delta
  (1 lb ≈ 3500 cal ⇒ daily delta = lbs/week × 3500 / 7). **Clamp the rate** to a safe max
  (≤ ~1% bodyweight/week). Maintain = 0.
- **Calorie floor:** never output below a safe floor (≈1500 male / ≈1200 female, or `BMR × 0.8`,
  whichever is higher). If clamped, surface a gentle note ("we set a safe minimum").
- **Macro split** (from target calories):
  - Protein ≈ **1.0 g per lb** bodyweight (current or goal; cap sensibly).
  - Fat ≈ **0.35 g/lb** (≈25% of calories).
  - Carbs = remaining calories / 4. If it goes negative at very low calories, reduce fat before
    carbs; **never negative**.
- **Units:** accept lb/kg + ft-in/cm (US audience → default imperial; store metric internally).

## Conventions to follow
- **Concurrency:** stores are `@MainActor @Observable`; pure value types are `nonisolated struct`,
  `Sendable`, `Codable`.
- **Persistence:** UserDefaults via an `@Observable` store (mirror `SettingsStore`) for the profile.
- **Design:** OBSIDIAN tokens + existing components only. Match the dark, premium feel; no colors
  outside the palette. Reuse `Card`, the button styles, `Haptics`, `Backdrop`, `MacroBar`/`MacroRing`
  where a target readout is shown.
- **Files:** Xcode 16 **file-system-synchronized groups** — new `.swift` files under `Loadout/`
  auto-join the target (no pbxproj edits). Models → `Loadout/Models`, stores → `Loadout/Stores`,
  feature views → `Loadout/Features/<Feature>`, pure logic → `Loadout/Services` or `Loadout/Models`.
- **Testing:** Swift Testing for unit, XCUITest for UI. UI tests skip onboarding via the launch
  argument `-loadout.settings.hasCompletedOnboarding YES` — if you add a goal-onboarding step,
  ensure it doesn't block that bypass (add a matching skip if needed).

## Risks / guardrails
- **Target generation is health advice** → in-app disclaimer ("estimate, not medical advice"),
  the calorie floor, and ED-sensitive copy. (A matching ToS clause is handled by the owner.)
- Don't break the existing onboarding gate or the UI-test launch-arg bypass.
- Keep goal setup optional this phase (nothing is gated on it yet).

## Design so later phases drop in cleanly
Expose the target as `Macros` and keep the profile store injectable, so:
- **HealthKit (Phase 2)** can compute `remaining = target − consumed`.
- **Budget Mode (Phase 3)** and the **solver (Phase 4)** can read the target directly.

## Key existing files to read
- `Loadout/Stores/SettingsStore.swift` — the store pattern to mirror.
- `Loadout/Models/Macros.swift` — the target number type to reuse.
- `Loadout/App/LoadoutApp.swift` — where stores are injected.
- `Loadout/App/RootView.swift` — the onboarding `fullScreenCover` gate.
- `Loadout/Features/Onboarding/OnboardingView.swift` — existing first-run flow.
- `Loadout/Features/Settings/SettingsView.swift` — where the "edit target" entry lives.
- `PROJECT.md`, `STYLE_GUIDE.md` — product + visual specs.
