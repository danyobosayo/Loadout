# LOADOUT — Design Language: **OBSIDIAN**

> The single source of truth for how Loadout looks, moves, and feels.
> Companion to `PROJECT.md`. Code lives in `Loadout/DesignSystem/`.
> If a screen doesn't feel like this document, the screen is wrong.

---

## 0. Philosophy

Loadout is a precision instrument you use standing in a burrito line. The design language is **Obsidian**: flat near-black planes separated by hairlines, one electric signature color used like a scalpel, numerals that behave like a scoreboard, and motion that confirms every gram you add. The reference bar is "App Store Design Award" — which means restraint, not spectacle.

Five laws:

1. **Dark is the canvas, color is data.** The UI is flat grayscale. Saturated color appears *only* where it means something: macro values, the signature accent on the primary action, and per-station category cues. Never decorate with color, never fill with gradient.
2. **Numbers are the heroes.** Macro numerals are the largest, brightest thing on any screen. They are always SF Rounded, always monospaced-digit, and they *never* teleport — they tick (`.numericText`), because a number that animates is a number you trust.
3. **Everything answers your touch.** Every tappable surface compresses (`scale 0.96–0.97`), every add bounces its icon, every threshold crossed emits a haptic. Zero dead taps.
4. **Choreography over decoration.** Elements enter staggered (40 ms) and rise 14 pt. Motion explains hierarchy; it is never confetti. Every animation uses a named token from `Motion.swift` — raw `withAnimation(.default)` is a code-review rejection.
5. **Flatness is confidence.** Surfaces are solid fills separated by 1 pt hairlines. No gloss, no glow, no glass materials, no edge lights, no gradients. Depth exists only where something truly floats over content — and there are exactly four of those in the whole app (tab bar, tray bar, two toasts), all sharing one restrained shadow.

---

## 1. Color

All tokens live in `Colors.swift`. Never use a literal color in a feature view.

### 1.1 Canvas (the grayscale stack)

| Token | Hex | Role |
|---|---|---|
| `Color.void` | `#0B0B0F` | App background. The bottom of the world. |
| `Color.surface` | `#131318` | Cards, rows, rails. |
| `Color.surfaceElevated` | `#1B1B22` | Sheets, tray, floating bars, pressed rows. |
| `Color.hairline` | `white 8%` | 1 pt strokes — the only edge treatment in the app. |
| `Color.textPrimary` | `#F5F5F7` | Titles, values. |
| `Color.textSecondary` | `#9C9CA8` | Serving sizes, metadata. |
| `Color.textTertiary` | `#5E5E68` | Disabled, watermark labels. |

### 1.2 Signature

| Token | Hex | Role |
|---|---|---|
| `Color.volt` | `#C8FF4D` | THE accent. Primary CTA, selection, active tab, calorie values. Always a solid fill. |

Volt is loud on purpose and therefore rationed: **at most one volt-filled element per screen region.** Text sitting on volt is always `#0B0B0F`, never white. Volt never glows, never gradients — its saturation against the void *is* the emphasis.

### 1.3 Macro semantics (fixed, never re-themed)

| Token | Hex | Macro |
|---|---|---|
| `Color.kcal` | `#C8FF4D` | Calories (shares volt — energy *is* the brand) |
| `Color.protein` | `#FF7A6B` | Protein |
| `Color.carbs` | `#56C8F5` | Carbs |
| `Color.fat` | `#FFC94D` | Fat |

### 1.4 Restaurant identities

Abstract hues and line glyphs owned by us (PROJECT.md §9 forbids brand assets — hues avoid each brand's palette; glyphs are abstract food forms, not logos, drawn in the station-glyph family). The identity tile is a solid hue with the glyph in void ink. Defined in `RestaurantStyle.swift`; glyphs live at `Assets.xcassets/restaurant.*`.

| Restaurant | Token | Hex | Glyph |
|---|---|---|---|
| Chipotle | `ember` | `#FF6B4A` | chili pepper |
| CAVA | `iris` | `#9D7BFF` | med bowl + olive |
| Panda Express | `jade` | `#4ADE9B` | takeout box |
| Sweetgreen | `citrine` | `#FFB84A` | leaf |
| Subway | `ocean` | `#4AA8FF` | scored sub roll |

### 1.5 Feedback

`Color.destructiveRed` `#FF5D5D` (remove, clear). Success states use `volt`, not green — success in Loadout *is* energy.

---

## 2. Typography

`Typography.swift`. Two families, both system: **SF Pro** for words, **SF Rounded** for every number that represents food. In a flat UI, type carries the hierarchy — get this wrong and nothing else can save the screen.

| Token | Spec | Use |
|---|---|---|
| `.displayXL` | 40 pt, heavy, tracking −1.0 | Screen mastheads ("Loadout") |
| `.displayTitle` | 28 pt, bold, tracking −0.5 | Restaurant names, sheet titles |
| `.appHeadline` | 17 pt, semibold | Item names, buttons |
| `.appBody` | 16 pt, regular | Copy |
| `.appCaption` | 12 pt, medium | Serving sizes, metadata |
| `.microLabel` | 11 pt, semibold, **uppercase**, tracking +1.4 | "PROTEIN", section labels |
| `.numeralHero` | 44 pt, rounded, bold, monospaced digits | Tray total calories, ring center |
| `.numeralLarge` | 24 pt, rounded, semibold, mono digits | Macro trio values |
| `.numeral` | 17 pt, rounded, semibold, mono digits | Inline macros, steppers |

Rules: numerals never wrap, never truncate, never proportional-width. `microLabel` is the only uppercase style. Word text is never rounded; number text is never SF Pro.

---

## 3. Space, shape, edge

`Spacing.swift`.

**Spacing** — 4 pt grid: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48`. Screen gutters `md`; card internals `md`; between cards 12. Whitespace is a material: when in doubt, add space rather than a divider.

**Radius** — `Radius.chip 10 · Radius.card 20 · Radius.sheet 28 · Capsule` for pills/CTAs. Always `style: .continuous`.

**The surface recipe** (implemented once in `Card.swift`, never hand-rolled):

```
fill: surface (or surfaceElevated)
stroke: hairline, 1 pt
— that's it. No overlay, no shadow.
```

**The one shadow** — elements that float *over scrolling content* (floating tab bar, tray bar, toasts) get `shadow(black 35%, radius 16, y 6)`, because they genuinely occupy a higher plane. Nothing at rest casts a shadow. Adding a fifth shadowed element requires a very good argument.

**Floating-chrome clearance** — `Metrics.tabBarClearance` (76) and `Metrics.trayBarClearance` (72) in `Spacing.swift`. Screens apply these explicitly via `.contentMargins(.bottom, …)`; safe-area propagation is not trusted across NavigationStack boundaries. Any new root screen must reserve `tabBarClearance`; the menu screen reserves both.

---

## 4. Motion

`Motion.swift`. Three named springs. Nothing else exists.

| Token | Spec | Use |
|---|---|---|
| `Motion.tap` | spring(response 0.22, damping 0.7) | Press compress/release |
| `Motion.snap` | spring(response 0.35, damping 0.75) | Selection, quantity ticks, chips, rail pill |
| `Motion.glide` | spring(response 0.5, damping 0.85) | Layout shifts, tray expansion, ring sweep |

### Choreography rules

- **Entrance**: lists cascade with `.entrance(index:)` — each element starts `opacity 0, y +14` and resolves with `snap` delayed `index × 40 ms`, capped at 400 ms total. Applied on appear only, never on data refresh.
- **Numeric ticks**: every macro readout uses `.contentTransition(.numericText(value:))` animated with `snap`. This is the signature micro-interaction — a bowl being assembled should feel like a scoreboard updating.
- **Add-to-meal**: quantity control swaps in with `snap` scale 0.5→1, tray bar total ticks, haptic `.light`.
- **Ring sweep**: `MacroRing` animates `trim` with `glide` — never linear, never instant.
- **Press state**: `PressableStyle` — scale 0.96, `Motion.tap`. On *every* card and row.
- **Tab switch**: selected pill slides via `matchedGeometryEffect`, icon bounces once.
- **Reduce Motion**: `accessibilityReduceMotion` kills entrance stagger and bounces; numeric ticks and opacity fades remain.

### Haptics (`Haptics` in Motion.swift)

`tap` (add/select) · `success` (save, export) · `warning` (limit hit, destructive). Fired at the store boundary, not sprinkled in views.

---

## 5. The Backdrop

`Backdrop.swift`. Every root screen sits on flat `void` with a single **static** radial wash from the top edge — 5% of the contextual hue (volt on home, restaurant hue in a menu). It registers as atmosphere, not decoration. No motion, no mesh. If a screenshot makes someone ask "what's that gradient?", it's too strong.

---

## 6. Components

All in `DesignSystem/Components/`. Feature views compose these; they do not invent surfaces.

| Component | Contract |
|---|---|
| `Card` | The surface recipe. `Card { }` = surface, `Card(elevated: true)` = sheet-level fill. |
| `MacroRing` | Solid volt arc, rounded caps, ticking numerals at center. Progress = kcal vs. an optional target, or pure gauge without one. |
| `MacroDisplay` | One macro: numeral + `microLabel` in the macro's semantic color. `.hero` / `.inline`. |
| `MacroBar` | The kcal/P/C/F quartet row. |
| `MacroSegmentBar` | Stacked capsule showing each macro's share of calories; re-proportions with `glide`. |
| `PrimaryButton` (`.primaryAction`) | Solid volt capsule, void ink. One per region. |
| `GhostButtonStyle` (`.ghost`) | Hairline capsule, `textPrimary` label. |
| `QuantityStepper` | Hairline capsule ± with ticking numeral. Steps 0.25. |
| `QuickQuantityChips` | Absolute presets ½ · 1 · 1½ · 2 plus the stepper for anything else. |
| `CategoryRail` | The "chapters" bar: pills pinned under the nav on a solid void strip with a bottom hairline; selection pill (solid hue) slides with `matchedGeometryEffect`; syncs bidirectionally with scroll. |
| `MacroStrip` | Compact single-line readout for dense rows: kcal numeral + quiet color-keyed P/C/F pairs. Rows use this; the tray uses the full `MacroBar`. |
| `RestaurantCard` | Solid-hue monogram tile, name, station/item counts, chevron. |
| `EmptyStateView` | Icon in a tinted circle + title + one line of copy. No system `ContentUnavailableView` on styled screens. |
| `Backdrop` | §5. |

### Station glyphs

Twenty custom line glyphs (`Assets.xcassets/station.*`) — 24 pt grid, 1.7 pt round-cap strokes, template-rendered so they tint. Drawn as a single family: no emoji, no SF Symbols in station contexts. `CategoryStyle` maps station ids to glyphs; unknown stations fall back to `station.plate`. New glyphs must match the grid and stroke weight — one outlier ruins the set.

---

## 7. Patterns

**Navigation** — floating tab bar (Build · Recipes · History · Settings): solid `surfaceElevated` capsule, hairline, the one shadow; solid volt pill on the active tab. Within a menu: `CategoryRail` chapters.

**The Tray** — persistent bar above the tab bar while building: ticking total, macro split bar, item count. Tap → full tray sheet (`.presentationDetents([.medium, .large])`, void background, radius `sheet`).

**Portions** — every item row carries three absolute chips: **½ · 1 · 2**. Tap to set, tap the active chip again to remove. No relative +/− on rows, no hidden state: what the chip says is what's in the tray. Half-and-half is just `½` on two items in the same station (rice, beans, and bases are select-many for exactly this). The card body is a shortcut for "1" on items not yet in the meal and inert afterwards. Off-grid quantities (from the tray's 0.5-step stepper) surface as a `×1.5` badge beside the chips.

**Destructive** — swipe-to-remove where a thing can die, plus explicit affordance in edit contexts. Confirmation dialogs only for multi-item loss (Clear meal, Delete recipe).

**Empty states** — every list has a designed `EmptyStateView` with one actionable line.

**Numbers formatting** — calories: integer. Grams: one decimal max, trailing `g` in tertiary. Quantities: `×1.5` form.

---

## 8. Voice

Labels are terse and physical: "Build", "Tray", "Stations", "Log it". Recipes are "Recipes" (not Favorites). Export actions name their destination ("Log to MacroFactor", "Copy for MyFitnessPal"). No exclamation marks. The app never says "oops".

---

## 9. Accessibility

Contrast: `textPrimary` on `surface` ≥ 12:1; volt on void 13.9:1; macro colors ≥ 4.5:1 on `surface` at numeral weights. Every composite row is one `accessibilityElement` with a sentence label. Steppers implement `accessibilityAdjustableAction`. Dynamic Type: word styles scale; hero numerals cap at `.accessibility2` to protect layout. Reduce Motion honored per §4. All surfaces are opaque — Reduce Transparency needs no fallback.

---

## 10. Enforcement checklist (PR gate)

- [ ] No literal colors/fonts/durations in feature views — tokens only
- [ ] No gradients, glows, or materials anywhere; shadows only on the four floating elements
- [ ] Every tappable has a press state; every list has entrance choreography
- [ ] Every macro numeral ticks; none teleport
- [ ] One volt element per region
- [ ] Empty, loading, and error states designed
- [ ] Reduce Motion path verified
- [ ] VoiceOver: composite rows read as one sentence
