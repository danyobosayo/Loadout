# Loadout: One Direction, One List

## 1. Where Loadout actually sits

**Genuinely differentiated — three things, and only three.**

1. **The numbers are exact and deterministic.** Every competitor in the adjacent clusters is either AI-estimating (±20% MAPE, and worse: *non-deterministic* — same egg whites, 9/10 one month and 4/10 the next) or sitting on crowdsourced rot (a 2014 Chipotle entry at 300 cal against a real ~1100). Loadout's 14 restaurants / ~1200 hand-curated items is the only thing in this competitive set that is simply *right*. It is currently invisible. Nothing on screen says so.
2. **It is predictive, not retrospective.** Every tracker tells you what you ate. A station-by-station builder can tell you what a choice costs *before* you make it. That is a category difference, not a feature difference, and nobody in the direct-competitor cluster has built it — CalorieCap has builders but no decision-time cost; MacroMenu has swap deltas but only post-hoc.
3. **The aesthetic position is unoccupied.** Of eleven direct competitors, zero are monochrome. Two are dark (MacroMate navy/blue, Order Fit black/mint) and both still ship four-colour macro rows. Every app that "looks dated" in these teardowns looks dated by the same mechanism: five accent hues on one viewport. Loadout's one-accent constraint is a real position — and it is currently being violated by its own spec (see §2).

**Table stakes it is missing.** These are not nice-to-haves; their absence is what reviewers of every competitor write about:

- **Saved builds and one-tap rebuild.** The loudest unmet request in Cal AI's 351K-rating corpus and in MFP's regression reviews. People order the same bowl for weeks.
- **A target to measure against.** Without one, the big number is trivia. "640 of 800" is a verdict; "640" is a fact.
- **A handoff that lands.** This is Loadout's *stated premise* and it is also the entire category's dead end — Zolt tells you to copy-paste, Nutritionix gives you a URL. Being the reliable half of the handoff is the position; right now it's a claim.
- **Provenance on screen.** Cronometer's entire moat is a 12pt grey label reading "Data Source: NCCDB."
- **Cold-start content.** An empty builder on first launch is the worst screen you can ship. Zolt puts named presets *above* the empty state and it solves demo, cold start, and App Store screenshots in one move.
- **Swap suggestions with signed deltas.** Pure arithmetic over data you already hold; it's what makes an app appear to reason.

**Things nobody asked for.** A **Recipes** tab in a fast-food chain builder is scope creep wearing a tab bar — it either duplicates saved builds or invents a second product. Merge it into saved builds or cut it. **History** as a peer tab is similarly suspect: history's job here is to power "last time" ghosts and rebuild, both of which belong *inside* Build. Four tabs is three more destinations than an app with one job needs. Aim for **Build / Saved / Settings**, or Build + a sheet.

---

## 2. The design direction

**Keep the position. Sharpen it into a thesis, and cut the one thing that contradicts it.**

The thesis: **Loadout is an instrument, not a wellness app.** It is closer to a trading terminal than to Lifesum. It is dense on purpose, monochrome on purpose, and completely unafraid of small type — because it has exactly one job and the user is standing in a queue with ninety seconds. Every design decision below serves that.

### Palette — the one real change

**Kill the three macro hues.** `#FF7A6B / #56C8F5 / #FFC94D` is the exact mechanism by which MyFitnessPal, MacroFactor, Lifesum and every direct competitor read as generic. MacroFactor makes six hues work only through absolute rigidity, and the cost is that it has no visual signature. Loadout does not need four hues to distinguish four numbers — macros are distinguishable by **fixed order, a trailing letter, and position**, which is exactly how the compact macro line already works.

The full palette, and it is short:

- **Ground** `#0B0B0F`, pushed one degree warm. A blue-grey dark reads as "developer default"; a warm-neutral dark reads as a decision. One token, free.
- **Volt green** `#C8FF4D` — the *only* saturated colour, and never more than one saturated element per screen. It carries the running total, the active/filled state, and nothing else.
- **One warm amber** (~`#FFB020`) reserved for exactly two meanings: **over-target** and **estimated value**. Never red — MacroFactor's no-shaming stance is explicitly what their users cite as valued, and a red bowl is a deleted app.
- **Macro differentiation by opacity ladder** on the same volt/white: protein 100%, carbs 55%, fat 30%, all on the same track. Three greys for text (primary, secondary, "dim legible") and nothing else.

Two hues total. That's the signature.

### Type

Keep SF Pro for words and SF Rounded monospaced-digit for every number — **the tabular figures are already a genuine quality gap you close against your own north star** (MacroFactor's totals visibly jitter when they animate; yours won't). Add four rules and build them as four components, once:

1. **Unit-as-subscript.** Value at full size, unit at 45–50% of it, same weight, one opacity step down, same baseline: `780ᴋᴄᴀʟ`, `42ɢ`. One `MacroValue(value:unit:)` view used everywhere. This is the single highest-value-per-line steal in the whole review.
2. **Numerator dominates denominator.** `640` big and bright, `of 800` small and grey, same baseline, remaining right-aligned. Two readings of one number in one row, hierarchy from weight and size only — which suits a dark monochrome far better than it ever suited MFP's light one.
3. **The compact macro line, verbatim.** `540 · 34P 22F 41C · 12 oz`. No commas, no "Protein:", never wraps. Every item row, every search result, every summary. ~30% narrower than labelled, and it makes every list in the app share one shape.
4. **Round display values to whole units.** Keep precision in the export only. A spurious decimal is a lie told in a serious voice.

### Shape and density

Keep 20pt radius, hairline, no shadow — separation by ground contrast is correct for dark and it's what Bevel and MacroFactor both do. Three additions:

- **Selection is an outline, never a fill.** 1px volt outline for anything spatial (active station, selected size). Reserve filled pills for segmented controls only, and drop the track behind unselected segments — bare text. This is how you signal state without spending a second colour.
- **Full-row wash for completed stations.** Hevy's best idea: a station with a selection floods its whole row at ~12% volt and takes its numerals to full volt; untouched stations stay pure greyscale. Scrolling the builder, "what have I picked" becomes a colour pattern you never read. It also gives the accent an actual job.
- **Chip rows, never picker wheels.** Portion, size, meal format — a horizontal filled-pill row docked above the content. Kills an entire modal from the most-repeated interaction in the app.

On density: go **denser than the category**, and ship exactly one escape hatch. The category's whole failure mode is Cronometer growing row height with no density control, and MFP hiding the day behind "View All." Your escape hatch is not a settings screen — it's a **swipeable summary header with page dots** (MacroFactor's three-density carousel): page 1 one big numeral, page 2 the four-macro block, page 3 per-station breakdown. Same data, escalating detail, shrinking type. A text-size preference disguised as content, no accessibility audit.

### Motion

Define three tiers, name them, never exceed them:

- **Tier 1 (~120ms):** every tap moves something. Ubiquitous.
- **Tier 2 (~300ms):** adding an item counts the total up and floats a **delta chip** — `+180` / `−90` — rising ~12pt and fading. This is the app's entire motion personality and it's about thirty lines of SwiftUI. In a builder, the delta *is* the information; the absolute total is bookkeeping.
- **Tier 3, reserved:** completing an export fires one brief volt sweep and one haptic tick. Nothing else in the app is ever allowed to use it. Own the completion beat — the incumbent's most memorable animation at that exact moment is a 3–5 second ad.

### Iconography

SF Symbols, monochrome, one weight. **No emoji as data** — full-saturation emoji on `#0B0B0F` become the most colourful thing on screen and fight the entire palette. **No mascot.** **No food photography.** Cut-out photography on dark is the one thing that would genuinely raise the ceiling (ZOE proves it), but it's 60–100 assets, it's a "large," and it pulls toward wellness-app when the thesis is instrument. Defer indefinitely.

### The category's actual polish bar, and where you fall short

The bar is not set by MyFitnessPal. It's set by Hevy (4.92 across 84,859 ratings) and Gentler Streak (Apple *Behind the Design*), and concretely it is:

| The bar | Loadout today |
|---|---|
| Sub-second launch straight to the thing you came for | Probably fine — protect it |
| Exactly one saturated element per screen | **Fails** — four accents specced |
| A systematic value/unit type pair, used everywhere | **Missing** — build the component |
| Live numbers that don't jitter | **Ahead** — keep the tabular figures |
| A named, three-tier motion system | **Missing** |
| Release notes written by a human, with a "in case you missed the last update" recap | **Missing** — free, and the one thing a solo dev does better than a company |
| A dedicated privacy claim as App Store screenshot #2 | **Missing** — and it's simply *true* for you |
| Store screenshots that match the app's own look | Unknown — dark monochrome app ships dark monochrome screenshots, no exceptions |

---

## 3. Ranked feature list

Everything here is local. **Nothing on this list needs a backend, an account, or a network call.** That's not a constraint you're working around; it's the reason the list is short enough to ship.

| # | Feature | Size | Backend |
|---|---|---|---|
| 1 | **Pinned running-total HUD** that never scrolls: 2×2 current/target pairs, ~12pt, 2–3pt bar under each, close button, "what's in the bowl" pill. Station list scrolls underneath. | S | No |
| 2 | **Decision-time delta on every option** — `+180` shown on a station item *before* it's tapped. The single thing that makes Loadout categorically not-a-diary. | M | No |
| 3 | **Export: HealthKit `.food` correlation + multi-representation clipboard.** The stated premise, currently unfulfilled. See §4. | S | No |
| 4 | **Per-meal target + "X of Y" framing + target bar with over-zone** (track / volt fill / 1px tick at target / tinted zone beyond). Never red. Ask for the target *after* the first completed build. | S | No |
| 5 | **Saved named builds + "last time" ghost row + one-tap rebuild.** Ghost, never prefill — Hevy's greyed target is loved, Strong's actual prefill draws 3-stars. | M | No |
| 6 | **Preset builds per restaurant** (4–6, composition in the subtitle), shown *above* the empty builder. Kills cold start, demos the data, doubles as screenshot material. | S | No |
| 7 | **Provenance line + "menu wrong?"** — `Official Chipotle nutrition · verified Mar 2026`, and a per-item tap that opens a prefilled mail composer. Your QA pipeline costs a `mailto:`. | S | No |
| 8 | **Swap chips with signed deltas** within a station: `Sofritas −40`, `Double Steak +180`, ranked by |delta|. A sort over items you already hold. Turns a calculator into a tool. | M | No |
| 9 | **The four type components** (unit-subscript, numerator/denominator, compact macro line, delta chip) built once and used everywhere. | S | No |
| 10 | **Swipeable summary density carousel** with page dots. Your answer to the type-size question, with no settings screen. | M | No |
| 11 | **Proximity sort of the restaurant grid** — static lat/long table or `MKLocalSearch`, on-device. The actual moment of use is standing in a queue; cutting scroll-and-search to zero taps beats any build-screen feature. | M | No |
| 12 | **Share card** — `ImageRenderer` + `ShareLink`, Stories-sized: near-black, station list as quiet grey rows, macros enormous in volt. Your output is more interesting than a photo of a salad. | M | No |
| 13 | **Heavy-handed-server toggle** (+15% on scooped items). Pure arithmetic, nobody has it, and it signals you understand the real problem rather than reprinting a PDF. | S | No |
| 14 | **Protein per 100 cal** beside the total. One derived number that lets two builds be compared at a glance. | S | No |

Items 1–4 are the product. 5–7 are what make it get reopened and trusted. 8–14 are where it starts to feel like nobody else's app.

---

## 4. Integrations, in order

The feasibility pass is unambiguous: **there is no programmatic food-write into MyFitnessPal, Cal AI, Lifesum, or YAZIO. Not gated — nonexistent.** MFP's own Partner API documents food as read-only; even an approved partner cannot POST a meal. Stop treating the clipboard as a stopgap; it is the ceiling for MFP.

**1. HealthKit `.food` correlation — do this first. (Small.)**
Write an `HKCorrelation` of type `.food` wrapping `dietaryEnergyConsumed` + protein/carbs/fat, with the meal name in `HKMetadataKeyFoodType`, `HKMetadataKeyWasUserEntered = true`, and the meal's timestamp. This is the *only* lane that machine-delivers a meal into another app with no user step, and one code path buys you three destinations: **Foodnoms** (full food-log entry, best citizen), **Lose It!** (calories for everyone, macros for Premium users with custom nutrient goals), **MacroFactor** (daily totals on the Nutrition page — not the food log). If you write loose quantity samples today, the correlation + `FoodType` upgrade is what makes a meal appear *by name* instead of as orphan numbers.
Design for its failure modes: writes succeed silently even when the receiving app has no read permission, so ship a setup checklist and a "not seeing it?" path; deletes only work from the originating app, so edits must delete-and-rewrite your own correlation; no backdating into Lose It!.

**2. Multi-representation clipboard. (Small, trivial, strictly additive.)**
One `UIPasteboard` item carrying three UTIs: `public.utf8-plain-text` (the human string for MFP Quick Add — calories, P, C, F in field order), `public.json` (your documented payload), and an exported `com.loadout.meal`. Degrades perfectly. Pair it with a deep link that opens MFP so the manual entry is as short as possible. This serves the largest destination in the category and it's the ceiling there — build it well and stop.

**3. Keep the MacroFactor Shortcut. (Already built — harden it.)**
It remains the only path that produces real *per-food* entries in MacroFactor; the HealthKit route gives daily totals only. `shortcuts://run-shortcut` matches by exact name with no `x-success`, so a rename or a non-English install breaks it silently. Detect with can-open plus an explicit "did that work?" confirmation.

**4. Cronometer natural-language paste. (Small.)**
Different formatter: conversational item + quantity, **no nutrient numbers** — `6 oz chicken, 1 cup white rice, 4 oz guacamole` — pasted into Voice Log's Description field, which parses. Better than the MFP paste because the destination does the matching. Two things must be surfaced in your UI: **Voice Logging is Gold-only** (free users have no ingestion surface at all), and Cronometer re-matches against *its* database, so the exact chain figures are lost in translation — show the expected calorie total so the user can sanity-check.

**5. Your own `AppIntent`/`AppShortcut` + a versioned JSON and Cronometer-shaped CSV via share sheet and Files. (Medium.)**
Exposing an intent lets users chain Loadout into anything that ships Shortcuts actions (Foodnoms alone exposes 44). The file formats are for portability and for whatever integration exists in two years — not because any shipping app ingests them.

**Never build:** the MFP partner application (approval doesn't unlock food writes), any reverse-engineered private API (MFP v2, YAZIO v15), anything that collects a third party's password, FHIR or schema.org emission, a share extension as an "integration," or any design assuming another app can call your App Intent — iOS has no such API.

---

## 5. What to say no to

**No AI. None.** Not photo logging, not a chat, not estimation, not "describe your meal." Determinism is the entire moat: users forgive a wrong estimate and do not forgive the same input producing two answers. The moment a stochastic layer touches a total, you become MacrosMap ("estimations are widely inaccurate") instead of the app that's actually right. If you ever want an AI feature, the answer is a deterministic solver — "find a build under 700 cal with 50g protein" — not a model.

**No streaks, no health scores, no grading the bowl.** Nobody eats at Chipotle seven days a week; a streak row renders as failure rings for the exact behaviour you support. And a score is worse: a double-meat burrito at 30/100 is a deleted app. Cal AI's reviews contain a user whose *grilled chicken, avocado and sourdough* got called a poor lunch. Show the number, never grade the meal. If you want a habit surface later, use "Build 47" — accumulation without loss aversion.

**No second accent, ever.** Every time a new state needs a colour, the answer is opacity, position, outline, or a weight flip — not a hue. This is a permanent rule and it's the whole visual position.

**No mascot, no emoji-as-data, no 3D characters, no AI-generated icon.** Two direct competitors ship 3D blobs; it reads consumer-cute and would undermine a numbers-first tool aimed at people who lift. CalorieCap lost a star purely for an AI-generated app icon — this audience notices.

**No onboarding quiz.** Cold-open into the restaurant grid. No account, no questions, no weight, no goal. Ask for a target only *after* a completed build, framed as "want me to remember this?" Cal AI's single most-repeated 1-star sentiment is "I just want to count my calories and it's playing 20 questions with me."

**No notifications.** Not one. Hunger-adjacent push in this category is not a churn risk, it's a harm risk.

**No subscription — and if you ever monetise, decide the line before launch and never walk it backwards.** The live total and the build are permanently free, at any point, ever. Charge for saved builds, history, presets, and export if you must, as a **one-time unlock**. Never weekly pricing above monthly (CalorieCap's "deceptive practices" 1-star). Never retroactively gate something shipped free (MFP's barcode paywall is four years old and still the category's loudest grievance). Never gate after data entry.

**No restaurant-count race.** MacroMate advertises 120+ chains and has no builder. Frame 14 as depth — "every station, every portion size, official published data" — on the store listing's first line, next to "No ads. No account. No subscription to see your macros."

**No social, no feed, no accounts, no analytics, no cloud sync.** Each is a permanent operational burden with no network effect at your scale, and CloudKit-syncing health data collides with App Store Guideline 5.1.3(ii).

**No hour-based or meal-slot time model.** You're per-meal. Don't invent a time model the user didn't ask for.

**No review prompt until a user has completed *and exported* a build twice.** Your ratings are your entire marketing budget. Ask once, at the only moment the app has just proved its value.

**And one meta-no: never move a one-tap control, and never put the running total behind navigation.** MyFitnessPal dropped 1.7 stars in a single version for hiding the day's contents behind "View All." The number people opened the app for must be structurally impossible to hide.

---

**If four evenings are all you have:** kill the three macro hues; build the pinned total HUD; build the four type components; ship the HealthKit `.food` correlation. That's the app's identity, its structure, its craft floor, and its premise — in that order.