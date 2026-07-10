# Premium Phase 1 Implementation Plan — Macro Targets

> Execution plan derived from `PREMIUM_PHASE1_BRIEF.md`. Written against the codebase at
> commit `0ef8662`. Execute batch-by-batch on `main`: build + test + verify each batch,
> commit, then move on (the repo's established rhythm).

## 0. Decisions resolved (the brief left these open)

| Question | Decision | Why |
|---|---|---|
| Extend `SettingsStore` vs sibling store? | **New `ProfileStore`** | `SettingsStore` is app-mechanics prefs (shortcut name, onboarding flag). The body profile + goal is a user-domain object that Phases 2–4 (HealthKit remaining, Budget Mode, solver) will grow around. Separate store keeps that growth out of app prefs. |
| Where does goal setup sit in onboarding? | **Step 2 inside the existing `fullScreenCover`** | `OnboardingView` becomes a two-step container: step 1 = the existing pitch (unchanged), "Continue" advances to step 2 = embedded `GoalSetupView` with "Skip for now". One gate, no second flag: `hasCompletedOnboarding` is still set by the cover's dismiss binding in `RootView`. Existing users (flag already true) simply find goal setup in Settings. |
| Protein anchored to current or goal weight? | **`min(current, goal ?? current)`** | 1 g/lb of *current* weight overshoots badly for overweight users cutting; min() is the standard defensible anchor. Cap at 250 g. |
| Goal-rate clamp | **Lose ≤ 1% BW/week, gain ≤ 0.5% BW/week** (and never > 2 lb/wk) | Standard safe ranges; gain slower than loss by convention. Clamping sets a flag so the UI says "we slowed this to a safe pace." |
| Generate path age bounds | **18–99** | Calorie-target generation for minors is liability we don't need. Under-18 users can still use manual entry. |
| Timeframe input | **Goal weight + target number of weeks** (stepper, 4–104) | Matches the brief ("goal weight + timeframe"); rate is derived, then clamped. |

## 1. New files

```
Loadout/Models/MacroGoal.swift            — BodyProfile, MacroGoal, supporting enums
Loadout/Services/MacroTargetCalculator.swift — pure calculator
Loadout/Stores/ProfileStore.swift         — @Observable UserDefaults-backed persistence
Loadout/Features/Goal/GoalSetupView.swift — reusable two-mode setup UI
Loadout/Features/Goal/GoalReviewCard.swift — computed-target review (split out; shared by both modes)
LoadoutTests/MacroTargetCalculatorTests.swift
LoadoutTests/ProfileStoreTests.swift
LoadoutUITests/GoalSetupUITests.swift
```

File-system-synchronized groups: creating the files is enough; no pbxproj edits. `Loadout/Features/Goal/`
is a new folder — same mechanism (folders auto-join), mirror how `Features/Formats/` was added.

## 2. Model spec — `Loadout/Models/MacroGoal.swift`

All `nonisolated struct`/`enum`, `Codable`, `Hashable`, `Sendable` (match `Macros`/`BuiltMeal` style).

```swift
enum BiologicalSex: String { case male, female, unspecified }   // unspecified → average of M/F BMR

enum ActivityLevel: String, CaseIterable {
    case sedentary, light, moderate, veryActive, extraActive
    var multiplier: Double   // 1.2 / 1.375 / 1.55 / 1.725 / 1.9
    var label: String        // "Sedentary — desk day, little exercise" etc.
}

enum GoalDirection: String, CaseIterable { case lose, maintain, gain }

struct BodyProfile {
    var sex: BiologicalSex
    var age: Int
    var heightCm: Double        // stored metric, ALWAYS
    var weightKg: Double        // stored metric, ALWAYS
    var activity: ActivityLevel
    var direction: GoalDirection
    var goalWeightKg: Double?   // nil when .maintain
    var timeframeWeeks: Int?    // nil when .maintain
}

struct MacroGoal {
    enum Source: String, Codable { case generated, manual }
    var target: Macros          // reuse the existing value type — Phases 2–4 read this
    var source: Source
    var profile: BodyProfile?   // present when generated → re-editable form
    var updatedAt: Date
    var floorApplied: Bool      // calorie floor kicked in → UI shows the safe-minimum note
    var rateClamped: Bool       // requested pace was unsafe → UI shows the slowed-pace note
}
```

Unit conversion helpers (lb↔kg, ft/in↔cm) as `static` members or a small `Units` enum in the same
file — pure math, unit-tested. UI is imperial-first; storage is metric, always.

## 3. Calculator spec — `Loadout/Services/MacroTargetCalculator.swift`

Pure, `nonisolated`, no I/O. One entry point:

```swift
enum MacroTargetCalculator {
    struct Output: Sendable, Hashable {
        var target: Macros
        var bmr: Double          // surfaced on the review card ("maintenance ≈ 2,450")
        var tdee: Double
        var floorApplied: Bool
        var rateClamped: Bool
        var achievableWeeks: Int?  // honest timeline after BOTH clamps (rate + floor);
                                   // nil when the floor eats the whole deficit (step 8)
    }
    static func target(for profile: BodyProfile) -> Output
}
```

Algorithm (constants as named `private static let`s, one place to tune):

1. **BMR (Mifflin–St Jeor):** male `10·kg + 6.25·cm − 5·age + 5`; female `− 161`;
   unspecified → mean of both.
2. **TDEE** = BMR × activity multiplier.
3. **Rate:** `weeklyDeltaKg = (goalKg − currentKg) / weeks` (0 for maintain). Clamp magnitude to
   `min(1% of current BW [lose] / 0.5% [gain], 0.91 kg)`. If clamped → `rateClamped = true`.
4. **Calories:** `tdee + weeklyDeltaKg × 7700 / 7` (7700 kcal/kg ≈ 3500 kcal/lb).
5. **Floor:** `max(computed, sexFloor, bmr × 0.8)` where sexFloor = 1500 (male) / 1200 (female) /
   1350 (unspecified). If raised → `floorApplied = true`. **Round to nearest 10 AFTER the floor**
   (so floored outputs are round-10 too).
6. **Split — calories are authoritative; the cascade solves within them** (each step monotone,
   so it terminates and can never *raise* a macro):
   - anchor weight = `min(currentKg, goalKg ?? currentKg)` in lb;
   - protein = `min(1.0 g/lb, 250 g)`;
   - fat = `0.35 g/lb`;
   - carbs = `(calories − 4·protein − 9·fat) / 4`;
   - if carbs < 0: `fat = max(0.25 g/lb, (calories − 4·protein) / 9)`, recompute carbs;
   - if carbs still < 0 (fat at its floor): `protein = max(0, (calories − 9·fat) / 4)`,
     `carbs = 0`. (No fixed protein floor in this terminal step — for a >160 kg anchor a
     0.7 g/lb "floor" exceeds the 250 g cap and would *raise* protein mid-reduction; whatever
     the calories afford after the fat floor is the honest answer.)
   - Grams rounded to whole numbers.
7. `target = Macros(calories:, proteinGrams:, carbGrams:, fatGrams:)`. By construction
   `4P + 4C + 9F` matches `calories` within rounding (≈±20 kcal) — assert this in tests; it is
   an invariant, not a hope.
8. **`achievableWeeks`:** the honest timeline must account for BOTH clamps. Effective daily
   deficit = `tdee − flooredCalories`; `achievableWeeks = ceil(|goalKg − currentKg| /
   (effectiveDeficit × 7 / 7700))`. If the floor eats the whole deficit (`effectiveDeficit ≤ 0`),
   set `achievableWeeks = nil` and the UI says progress will be slower at the safe minimum
   (no weeks estimate).

**Input validation** lives in the form (age 18–99, weight 30–300 kg, height 120–230 cm,
weeks 4–104, goal weight within ±50% of current); the calculator itself is total — it never
crashes on odd-but-typed input.

## 4. Store spec — `Loadout/Stores/ProfileStore.swift`

Mirror `SettingsStore` exactly:

```swift
@MainActor @Observable
final class ProfileStore {
    private let defaults: UserDefaults
    var goal: MacroGoal? { didSet { persist() } }      // JSONEncoder → Data under Keys.macroGoal
    var target: Macros? { goal?.target }               // the one accessor Phases 2–4 use

    init(defaults: UserDefaults = .standard)           // decode on init; corrupt data → nil (never crash)
    private enum Keys { static let macroGoal = "loadout.profile.macroGoal" }
}
```

- Injection: `LoadoutApp` gains `@State private var profile = ProfileStore()` +
  `.environment(profile)` beside `settings` / `macroFactorExport`. Update `RootView`'s
  `#Preview` to add **both** `.environment(ProfileStore())` **and** `.environment(MacroFactorExport())`
  — the preview is *already* broken today (it injects only `SettingsStore` while `RootView`
  requires `MacroFactorExport`); fix the pre-existing gap while there so the executor doesn't
  attribute the residual crash to the new store.
- Encode with the same `JSONEncoder` defaults used elsewhere; a decode failure silently resets
  to nil (a lost goal is re-enterable; a crash loop is not).

## 5. UI spec

### 5a. `GoalSetupView` (reusable core)

Self-contained scroll content + callbacks; the presenter owns the chrome:

```swift
struct GoalSetupView: View {
    var onSave: (MacroGoal) -> Void
    var onSkip: (() -> Void)? = nil     // nil → no skip button (Settings edit mode)
}
```

- Reads `ProfileStore` from `@Environment` to prefill from an existing goal (edit mode re-opens
  the saved `profile` when `source == .generated`).
- **Mode switch** at top: two tappable `Card`s ("Calculate for me" / "I have my numbers"),
  selected state = the accent border+tint `Card(highlight:)` pattern from the menu rows.
- **Calculate mode:** sex (segmented Picker), age (TextField, `.keyboardType(.numberPad)`),
  height (ft + in fields; unit toggle to cm), weight (lb field; toggle to kg), activity
  (Picker with the descriptive labels), direction (segmented lose/maintain/gain), and — when
  not maintain — goal weight + timeframe-weeks stepper. A volt "Calculate" `.primaryAction`
  button → `GoalReviewCard`.
- **Manual mode:** four numeral fields (calories, P, C, F). While calories is empty, show a
  live "≈ N kcal from macros" hint (4/4/9); user can accept or type their own.
- **`GoalReviewCard`:** `MacroRing(calories:)` + `MacroDisplay` trio (the tray-hero layout,
  smaller) + "maintenance ≈ N kcal" caption + the conditional notes:
  - `floorApplied` → "We set a safe minimum. Eating below this isn't recommended."
  - `rateClamped` → "We slowed this to a safe pace — expect ~N weeks."
  - Each macro editable inline (numeral `TextField`s) — editing flips `source` to `.manual`
    at save time only if numbers changed from the computed ones.
- **Disclaimer** (both modes, `appCaption` `.textTertiary`, verbatim):
  > "This is an estimate for healthy adults, not medical advice. Talk to a professional before
  > making significant dietary changes."
- Buttons: "Save target" (`.primaryAction`, `Haptics.success()`), optional "Skip for now"
  (`.ghost`). Number fields use `.keyboardType(.decimalPad)`; add a keyboard toolbar Done
  button (covers have no nav bar to tap away).

### 5b. Onboarding — step 2 of the existing cover

`OnboardingView` gains `@State private var step: Step = .pitch` (`enum Step { pitch, goal }`):

- `.pitch`: current content, unchanged, except "Continue" now does
  `withAnimation(Motion.glide) { step = .goal }` instead of `dismiss()`.
- `.goal`: micro-label header ("Your target") + short lede ("Set a daily macro target now, or
  skip — it lives in Settings.") + embedded `GoalSetupView(onSave: { profile.goal = $0; dismiss() },
  onSkip: { dismiss() })`.
- Transition: `.transition(.opacity.combined(with: .move(edge: .trailing)))` on the step switch.
- The gate is untouched: `RootView`'s cover binding still flips `hasCompletedOnboarding` on
  dismiss, whichever path dismissed. Force-quit mid-flow replays onboarding — correct.
- **UI-test bypass unaffected:** `-loadout.settings.hasCompletedOnboarding YES` suppresses the
  whole cover, step 2 included. No new launch arg needed.

### 5c. Settings — "Daily target" section

Insert between the masthead and "MacroFactor" (it's the premium identity going forward):

- No goal → `Card` with a volt "Set your daily target" row (chevron) → sheet.
- Goal set → `Card` with `MacroBar(macros: goal.target, style: .hero)` (hero is the readable
  variant at card width; verify at runtime vs `.inline`) + a caption line
  "Calculated · updated Jul 12" / "Manual · updated Jul 12" + tap-anywhere → sheet.
- Sheet: `GoalSetupView(onSave:)` with `presentationDetents([.large])` (full height for the form —
  intentional divergence from the tray's `[.medium, .large]`) + `presentationCornerRadius(Radius.sheet)`
  + `presentationBackground(Color.void)` + `presentationDragIndicator(.visible)` — the system drag
  indicator, matching the tray; no hand-built grabber.

## 6. Test plan

**`MacroTargetCalculatorTests`** (pure, fast):
- BMR reference: male 30 y / 80 kg / 180 cm → 1780; female 30 y / 65 kg / 165 cm → 1370.25
  (assert ±0.5). Unspecified = mean.
- TDEE multiplier applied per level.
- Deficit path: goal −8 kg in 16 wk → −0.5 kg/wk → ≈ −550 kcal/day off TDEE.
- Rate clamp: −20 kg in 10 wk for a 90 kg profile clamps to 0.9 kg/wk, `rateClamped`, and
  `achievableWeeks` reflects the clamped (and, if binding, floored) pace.
- Floor: tiny sedentary female profile with aggressive cut → `floorApplied`, calories ≥ 1200,
  and the emitted calories are still round-10.
- Split: protein = 1 g/lb of min weight; carbs never negative even at floor calories
  (fat reduced first — assert fat ≥ 0.25 g/lb floor before protein moves).
- **Energy consistency invariant** (the case a naive cascade gets wrong): heavy floored profile
  (e.g. sedentary female, 140 kg → 139 kg) → assert `4P + 4C + 9F` within ~20 kcal of
  `target.calories`. A dual-floor cascade that pins fat AND holds a fixed protein floor emits
  1200 kcal with ~1550 kcal of macros — this test is the guard.
- **Cascade monotonicity:** a > 160 kg anchor profile → protein in the output ≤ the capped
  starting protein (250 g); the terminal step must never raise it.
- **Floor-bound timeline:** profile where the floor eats the entire deficit → `achievableWeeks
  == nil` (UI suppresses the weeks estimate rather than lying).
- Gain path: surplus positive, clamp at 0.5%/wk.

**`ProfileStoreTests`:** round-trip via `UserDefaults(suiteName: #function)` (isolated, removed
in teardown); corrupt JSON → `goal == nil`, no crash; `target` mirrors `goal?.target`.

**`GoalSetupUITests`:**
1. Launch with the flag **forced off** — `app.launchArguments += ["-loadout.settings.hasCompletedOnboarding", "NO"]`
   → pitch shows → Continue → goal step → "Skip for now" → restaurant list appears (gate still
   completes). ⚠️ Do NOT just omit the arg: `hasCompletedOnboarding` persists in the simulator's
   standard defaults across runs (and this very test sets it on dismiss), so an arg-less launch is
   nondeterministic. NSArgumentDomain outranks the persisted domain, so forcing `NO` is
   deterministic on every run.
2. Bypassed launch → Settings → "Set your daily target" → manual mode → type 2200/180/200/60 →
   Save → Settings card shows the numbers (assert via accessibility label).
Existing suites keep passing: the assertion-bearing ones (`PortionControlUITests`,
`OrderFormatFlowUITests`) all use the bypass arg; the template `LoadoutUITests` /
`LoadoutUITestsLaunchTests` launch bare but assert nothing, so the new onboarding step can't
fail them.

## 7. Execution batches (commit after each)

| Batch | Contents | Gate |
|---|---|---|
| **A** | `MacroGoal.swift`, `MacroTargetCalculator.swift`, calculator tests | build + unit suite green |
| **B** | `ProfileStore.swift`, injection in `LoadoutApp`, store tests | build + unit suite green |
| **C** | `GoalSetupView` + `GoalReviewCard` + Settings section + sheet | build + manual-path UI test + screenshot review of both modes |
| **D** | Onboarding step 2 + onboarding UI test + polish from screenshots | full UI smoke (incl. the forced-`NO` onboarding run) + unit suite green |

## 8. Out of scope (explicitly)

No paywall/entitlement gating, no HealthKit (entitlement is Phase 2, owner flips it), no Budget
Mode UI in the builder, no solver, no export changes, no location. The only Phase-2 hook this
phase must leave behind: `ProfileStore.target: Macros?` injectable at the root.
