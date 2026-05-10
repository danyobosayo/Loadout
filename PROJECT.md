# Project Instantiation — Fast Food Macro Builder (iOS)

> **App name:** **Loadout** (pending App Store availability check).
>
> **Purpose of this document:** the single source of truth for what we're building, why, and how. Hand this to Claude Code at the start of every session. Update as decisions are made — never let it go stale.

---

## 1. North Star

A free, ad-free, privacy-respecting iOS app that lets you build a custom meal at a customizable fast-casual restaurant (Chipotle bowl, CAVA bowl, Panda Express plate, etc.), see live macros as you assemble it, and one-tap export the totals into MacroFactor via the official `Log by JSON` Shortcut.

**The job to be done:** "I'm at Chipotle. I want to know my macros *before* I order, then log it in MacroFactor in under 5 seconds."

---

## 2. Goals & Non-Goals

### Goals (v1)
- Build custom meals at six restaurants: **Chipotle, CAVA, Panda Express, Sweetgreen, Subway, Starbucks**.
- Live macro totals (calories, protein, carbs, fat) as items are added/removed.
- Save meals to **Favorites**.
- Local **Order History** (last N meals, automatic).
- One-tap **Export to MacroFactor** via Apple Shortcut handoff (JSON schema).
- Browse menus by restaurant.
- Fully offline-capable after first launch.

### Non-Goals (explicit — do not build these)
- Account system, cloud sync, login, or any backend.
- Analytics, telemetry, crash reporting that phones home, ads, or any monetization.
- Calorie/macro coaching, weight tracking, or recommendations (MacroFactor's job).
- Ordering or payment integration with restaurants.
- Photo recognition / AI logging (MacroFactor already does this).
- Android, iPad-first, or web. iPhone-only for v1; iPad runs in compatibility mode.

---

## 3. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | **Swift 6** | Strict concurrency on. |
| UI | **SwiftUI** | UIKit only if a SwiftUI gap forces it. |
| Min iOS | **iOS 18.0** | Lets us use latest `@Observable`, SwiftData, App Intents v2, `ScrollView` enhancements, mesh gradients. |
| IDE | **Xcode 16+** | |
| Persistence | **SwiftData** | For Favorites + History. Menu data is bundled JSON, not in SwiftData. |
| Shortcuts | **App Intents framework** | Expose intents for "Export last meal to MacroFactor" etc. |
| Dependencies | **None** in v1 | Stay native. Reconsider only for a real need. |
| Testing | **Swift Testing** (`@Test`) + XCUITest | Unit tests for macro math + JSON encoding are non-negotiable. |
| CI | **Xcode Cloud** or **GitHub Actions + Fastlane** | Daniel already has Fastlane experience from CAPCE — reuse the muscle memory. |

---

## 4. Architecture

**Pattern:** MV (Model-View) using `@Observable`. No view models unless a screen genuinely needs one. Keep it boring.

**Layers:**
```
┌─────────────────────────────────────┐
│  Views (SwiftUI)                    │
├─────────────────────────────────────┤
│  Stores (@Observable)               │  MealBuilderStore, FavoritesStore, HistoryStore
├─────────────────────────────────────┤
│  Services                           │  MacroFactorExporter, MenuRepository
├─────────────────────────────────────┤
│  Models (Swift structs, Codable)    │  Restaurant, MenuItem, BuiltMeal, Macros
├─────────────────────────────────────┤
│  Data sources                       │  Bundled JSON (menus), SwiftData (user data)
└─────────────────────────────────────┘
```

**Key principle:** the menu data layer is a `protocol MenuRepository` so we can swap bundled JSON for a remote fetch later without touching UI code.

---

## 5. Data Model

```swift
// Macros are pure values. All math happens here.
struct Macros: Codable, Hashable {
    var calories: Double
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    // Stretch: fiberGrams, sodiumMg, sugarGrams
    static func +(lhs: Macros, rhs: Macros) -> Macros { /* ... */ }
    static func *(lhs: Macros, qty: Double) -> Macros { /* ... */ }
}

struct Restaurant: Codable, Identifiable {
    let id: String                  // "chipotle"
    let name: String                // "Chipotle"
    let categories: [MenuCategory]  // base, protein, toppings, sauces, etc.
    let dataSource: DataSource      // see §6
    let schemaVersion: Int
}

struct MenuCategory: Codable, Identifiable {
    let id: String                  // "protein"
    let name: String                // "Protein"
    let selectionRule: SelectionRule // .selectOne, .selectMany, .selectUpTo(n)
    let items: [MenuItem]
}

struct MenuItem: Codable, Identifiable {
    let id: String
    let name: String
    let servingDescription: String  // "4 oz", "1 scoop", etc.
    let macros: Macros              // per one serving as defined above
    let allergens: [Allergen]?
    let notes: String?              // "Limited time", "Contains dairy", etc.
}

struct BuiltMeal: Codable, Identifiable {
    let id: UUID
    let restaurantId: String
    let name: String?               // user-given, optional
    let lineItems: [LineItem]       // (menuItemId, quantity)
    let createdAt: Date
    var totalMacros: Macros { /* computed */ }
}
```

**Rules of the road:**
- All macro arithmetic lives on `Macros`. No view ever does `a.protein + b.protein` inline.
- `MenuItem.macros` is always per **one** of `servingDescription`. Quantity scaling happens on `BuiltMeal`.
- IDs are stable strings (`"chipotle.protein.chicken"`), never UUIDs in the menu data — so favorites survive menu updates.

---

## 6. Restaurant Data Sourcing

### Format
Each restaurant gets one bundled JSON file: `Resources/Menus/chipotle.json`, `cava.json`, etc. Schema mirrors §5.

### Top of each file
```json
{
  "id": "chipotle",
  "name": "Chipotle",
  "schemaVersion": 1,
  "dataSource": {
    "url": "https://www.chipotle.com/nutrition-calculator",
    "fetchedAt": "2026-05-09",
    "fetchedBy": "manual",
    "notes": "Nutrition values per Chipotle's official calculator. White rice = 1 serving (4 oz)."
  },
  "categories": [ /* ... */ ]
}
```

### Sourcing principles
- **Official sources only.** Each restaurant's own nutrition page or PDF. No MyFitnessPal community entries.
- **Date every file.** `fetchedAt` is required. Stale data is the #1 risk.
- **Document assumptions.** If the source lists "Chicken Bowl" combos but not raw line items, reverse-engineer per item and write down the math in `notes`.
- **Refresh cadence:** quarterly check, or whenever a user reports a discrepancy.
- **Versioning:** bump `schemaVersion` on breaking changes; bump a per-item `revision` field on macro changes so we can show a "menu updated" indicator if useful.

### Sourcing workflow (manual, repeatable)
1. Visit the restaurant's official nutrition page.
2. Capture per-item macros into a working spreadsheet.
3. Convert to JSON via a small script in `Tools/menu-import/`.
4. Run `swift test --filter MenuDataIntegrityTests` — this validates schema, no negative values, no orphan IDs, etc.
5. Commit JSON + the script's input spreadsheet for auditability.

---

## 7. Core Features (MVP detail)

### 7.1 Browse
- Tab 1: **Restaurants** — list of 6 restaurants, alphabetical or by recency-of-use.
- Tap a restaurant → menu screen showing categories.
- Tap a category → items in that category with per-item macros visible.

### 7.2 Build a Meal
- Persistent "current meal" tray at the bottom of the menu screen.
- Tap an item to add (respect `selectionRule`: e.g., bases are select-one).
- Quantity stepper for items where it makes sense (e.g., extra protein at Chipotle = 2x).
- Live totals at the top: **kcal · P · C · F**, big and legible.
- "Clear meal" and "Save" actions.

### 7.3 Favorites
- Save the current meal with an optional name ("Usual Chipotle").
- Favorites tab shows them grouped by restaurant.
- Tap a favorite → opens it in the builder, fully editable.

### 7.4 History
- Every meal that gets exported is auto-saved to History.
- Last 50 meals, FIFO eviction.
- Same interactions as Favorites (re-open, re-export, promote to Favorite).

### 7.5 Export to MacroFactor
- Single button: **"Log to MacroFactor"**.
- Generates JSON conforming to MacroFactor's `Log by JSON` schema (see §8).
- Hands off to the user's installed MacroFactor Shortcut.
- On return, marks the meal as logged in History with a timestamp.

---

## 8. MacroFactor Integration

### Source of truth
- Repo: `https://github.com/MacroFactor/apple-shortcuts`
- Swift package: `Nutrition` (parses `Log by JSON` inputs, encodes outputs).
- We **may** add this package as a dependency to encode against their types directly. **Decision:** start by hand-rolling our own `Codable` mirrors of their schema (lighter), and switch to their package only if drift becomes a problem.

### Handoff mechanism
The MacroFactor Shortcut accepts JSON input. We have two paths:

**Path A (preferred): user-installed Shortcut + share/run.**
- App generates JSON.
- App opens a shortcut URL: `shortcuts://run-shortcut?name=<user's shortcut name>&input=text&text=<urlencoded-json>`.
- User has to install a one-time "Loadout → MacroFactor" shortcut once. Provide an iCloud link in onboarding.

**Path B (fallback): copy JSON to clipboard + deep link.**
- One tap copies JSON, opens MacroFactor's shortcut from the share sheet.

Implement Path A for v1. Path B as a settings toggle.

### JSON requirements per MacroFactor's spec
- Always include a unique `source` identifier (per their README). Use `"loadout.app"` or final bundle id.
- Note from their README: *"The `Log by JSON` action is built for logging food in the moment, not bulk import of past consumption."* — this matches our use case.
- Don't try to backfill history. Export = "log this meal right now."

### What to test
- Round-trip: build a meal → encode JSON → decode with their package's parser in tests → assert equality of macros.
- Unicode: restaurant names with apostrophes ("Cane's"), accents.
- Edge: zero-macro items (water), very large quantities.

---

## 9. UI / UX Direction

### Reference apps
- **Offsuit (Texas Hold'em Poker, iOS)** — the primary aesthetic anchor. Offsuit is a minimalist take on a category (poker) usually drowning in fake felt, neon, and popups. We're doing the same thing for fast-food macro tracking — a category drowning in ads, account walls, and clutter (MyFitnessPal et al.). What to borrow from Offsuit:
  - Native iOS feel — "fits with tech-oriented apps," not skeuomorphic to the food/fitness world.
  - Crisp vector iconography, no illustrations.
  - Restrained, near-monochrome palette with one functional accent.
  - Generous negative space. Calm screens.
  - Smooth, brief animations — not flashy.
  - Optional account, optional everything. The app *just works* with zero config.
- **Cal AI / Carbon (nutrition apps)** — secondary reference for layout patterns specific to food/macros. Big numeric readouts, soft cards, clear hierarchy of "totals → items → details."

### Typography
- **System fonts only.** No custom fonts in v1.
- **SF Pro Display** for headings and UI text.
- **SF Pro Rounded** for macro numerals — same family Apple uses for the Activity rings on Apple Watch. The rounded form makes the numbers feel friendly and at-a-glance, which is the entire point.
- All text uses Dynamic Type with semantic styles (`.largeTitle`, `.body`, etc.) plus a custom `.macroDisplay` style for the hero numerals.

### Specifics
- **Numbers are the hero.** Macro totals get the largest, heaviest type on every screen. Item names are secondary.
- **Color:** system background. One accent color — TBD, propose 3 candidates once design system scaffolds. Red reserved for destructive ("remove"). No category-specific colors (don't tint Chipotle screens orange — that crosses the trademark line and clutters the palette).
- **Cards:** soft shadow, ~16pt corner radius, no harsh borders. Match Offsuit's card treatment.
- **Density:** comfortable, not packed. Builder screen should feel calm even with a 12-item meal.
- **Motion:** snappy spring animations on add/remove. Numbers tick via `contentTransition(.numericText())`.
- **Dark mode:** first-class, not an afterthought. Offsuit is dark-mode-default — consider whether we should be too.
- **Iconography:** SF Symbols throughout. Custom SVGs only if SF Symbols genuinely can't represent the concept.

### Inspiration to mine on Dribbble
Search terms to seed ideation: *nutrition tracker*, *macro builder*, *meal logger ios*, *Cal AI clone*, *Carbon nutrition*, *food tracking minimal*, *poker app ios minimal*. Save 5–10 references to a `/design/inspiration` folder before scaffolding. Take screenshots of Offsuit's actual screens too — they're the closest thing to a north star we have.

### Accessibility
- Dynamic Type: all text scales. Numbers in particular must remain legible at AX5.
- VoiceOver labels on every interactive element. Macro readouts read as "320 calories, 28 grams protein..." not "320, 28..."
- Hit targets ≥ 44pt.
- No color-only signaling.

---

## 10. Project Structure

```
Loadout/
├── Loadout.xcodeproj
├── Loadout/
│   ├── App/
│   │   ├── LoadoutApp.swift
│   │   └── RootView.swift
│   ├── Features/
│   │   ├── Restaurants/        # browse list
│   │   ├── Menu/               # category + item screens
│   │   ├── Builder/            # the meal-building experience
│   │   ├── Favorites/
│   │   ├── History/
│   │   └── Settings/
│   ├── Models/                 # Macros, Restaurant, MenuItem, BuiltMeal
│   ├── Stores/                 # @Observable stores
│   ├── Services/
│   │   ├── MenuRepository.swift
│   │   └── MacroFactorExporter.swift
│   ├── Persistence/            # SwiftData schema
│   ├── DesignSystem/
│   │   ├── Typography.swift    # SF Pro Display + Rounded text styles, .macroDisplay
│   │   ├── Colors.swift
│   │   └── Components/         # Card, MacroBar, QuantityStepper, etc.
│   ├── AppIntents/             # Shortcuts integration
│   └── Resources/
│       ├── Menus/              # *.json
│       └── Assets.xcassets
├── LoadoutTests/               # Swift Testing
│   ├── MacroMathTests.swift
│   ├── MacroFactorJSONTests.swift
│   └── MenuDataIntegrityTests.swift
├── LoadoutUITests/
└── Tools/
    └── menu-import/            # script to convert spreadsheet → JSON
```

---

## 11. Engineering Standards

- **Tests are required for:** macro arithmetic, JSON encoding/decoding (both menu and MacroFactor), menu data integrity (no orphans, no negatives, all required fields present).
- **No force unwraps** in production code. `try?` over `try!`. `guard let`/`if let` everywhere.
- **No singletons** outside `@MainActor` `@Observable` stores wired through the environment.
- **Strict concurrency:** Sendable everything. Pay the cost up front.
- **Naming:** Apple HIG conventions. Don't shorten — `MealBuilderStore`, not `MBStore`.
- **Comments:** explain *why*, not *what*. `// Subway lists 6-inch macros, not full-sub — we double them at display time.` Yes. `// add the items` No.
- **Commits:** conventional commits (`feat:`, `fix:`, `data:`, `chore:`). Menu data updates use `data:` so they're easy to grep.
- **PR self-review:** every PR has a checklist comment: tests added? data dated? no force unwraps? a11y considered?

---

## 12. Privacy & Legal

- **No data collection. None.** No analytics, no crash reporters that exfiltrate, no third-party SDKs.
- All user data lives on-device in SwiftData. No iCloud sync in v1 (consider for v2 — but only via CloudKit user-private database, never our own server).
- App Privacy disclosure on the App Store: "Data Not Collected."
- **Trademarks:** restaurant names appear as plain text only. **No restaurant logos, no brand colors imitated, no marketing imagery.** Use generic icons (a bowl, a sub, a coffee cup) representing the category.
- **Disclaimer in app + App Store description:** *"Loadout is not affiliated with, endorsed by, or sponsored by any restaurant. Nutrition information is sourced from each restaurant's publicly available data and may differ from your actual order. Always verify critical dietary information directly with the restaurant."*
- **Allergen data is "best effort" not medical.** State this explicitly in onboarding if we surface allergens at all.

---

## 13. Open Questions / Decisions Pending

1. **Accent color.** Propose 3–5 options once design system scaffolds. Single accent only — no per-restaurant theming (trademark + clutter).
2. **Dark mode default?** Offsuit defaults to dark. Worth A/B-ing in your own head before scaffolding.
3. **Allergens in v1?** Could be a checkbox in the data model and surfaced later. Recommendation: include the field, hide the UI for v1.
4. **Onboarding length.** Probably one screen explaining the MacroFactor shortcut install + a "skip" button for non-MF users.
5. **Non-MacroFactor users.** Should "Copy macros to clipboard" be a first-class export option for users of other trackers? Likely yes — cheap to add, high value.
6. **Custom items.** Should users be able to add a "custom item" (e.g., the chips they brought from home) to a meal? Defer to v1.1 unless trivial.

---

## 14. Out of Scope for v1 (Backlog)

- iCloud sync of favorites/history (CloudKit user-private).
- Apple Watch companion (quick log a favorite).
- Widget on home screen (today's logged meals or quick-log a favorite).
- Live Activity during meal building.
- More restaurants (Chick-fil-A, Cane's, Qdoba, Mod Pizza, Halal Guys, etc.).
- Sharing built meals as deep links.
- Localization (English-only v1).
- iPad-optimized layout.
- Macro goal awareness ("you have 40g protein left today" — but only if the user explicitly opts in to enter goals locally; never sync from MacroFactor).

---

## 15. Glossary

- **Built meal** — a `BuiltMeal`: an ordered set of menu line items + quantities at one restaurant.
- **Line item** — one menu item + its quantity within a built meal.
- **Macros** — calories, protein (g), carbs (g), fat (g). Optionally fiber, sodium, sugar.
- **Log by JSON** — MacroFactor's official Shortcut action that accepts a JSON payload to log food.
- **Menu repository** — the abstraction that hands out restaurants/menus to the app, currently backed by bundled JSON.

---

## Appendix A — First-pass feature acceptance criteria

A v1 build is shippable when:

- [ ] All six restaurants have validated, dated menu JSON.
- [ ] Building a 5-item meal at any restaurant shows correct macros within ±1 kcal of source data.
- [ ] Exporting that meal to MacroFactor via the shortcut produces a log entry that matches our totals.
- [ ] Favoriting a meal and re-opening it preserves all line items and quantities.
- [ ] History records exports automatically and survives app relaunch.
- [ ] App functions fully in airplane mode after first launch.
- [ ] All listed unit tests pass; no force unwraps; no analytics SDKs.
- [ ] VoiceOver can complete the full "build → export" flow without a sighted user.
- [ ] App Privacy: "Data Not Collected" verifiable.

---

*End of document. Update the date and `schemaVersion` on this file when significant changes happen.*

*Last updated: 2026-05-09 (v0.2 — name locked to Loadout; Offsuit reference clarified as design north star, not a font).*
