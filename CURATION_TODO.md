# Curation TODO — the flagship four

Running list of things curation must get right, captured as they come up so they
don't live only in a chat log.

## Before the App Store: fill in `IndieLinks`

`Loadout/Features/Indie/IndieLinks.swift` holds every outward-facing address in
the app. Two are placeholders and the UI is built to notice:

- **`appStoreId` is nil.** Every App Store link is suppressed while it stays nil
  — the Settings "Leave a review" row doesn't render at all, and the thank-you
  note's review button falls back to the system prompt. Set the id and both light
  up with no other change. A UI test asserts the row stays hidden until then.
- **`feedbackEmail` defaults to the developer's personal address** and
  **`websiteURL` is nil** (the row hides). Swap in whatever the real feedback
  destination ends up being.

## Decisions taken

- **Ordering models differ per restaurant.** Bottom-up assembly (Chipotle, CAVA)
  vs top-down configuration (Chick-fil-A, Raising Cane's, MOD) vs recipe with
  modifiers (Starbucks) vs hybrid (Subway, Jersey Mike's). One mechanism covers
  all: a `MenuItem` may carry components; the published total is AS SERVED and
  authoritative, so removing a component is a subtraction.
- **Drinks are in.** Reversed the earlier food-only rule — a combo includes a
  drink, so excluding them made the most common real order unrepresentable.
  Drinks get their own station, sizes carry both label and fluid ounces
  ("Medium · 30 fl oz") because a Medium differs by chain.
- **Unremovable defaults are hidden**, not shown greyed out.
- **Prefer a labeled best estimate to a known gap.** Use official subtraction or
  scaling first, then a close official analogue, then a reputable secondary or
  community value that survives a plausibility check. Set `isEstimated`, keep
  the method and confidence in the data notes, and show only a brief disclosure
  in the menu. Allergens and dietary safety are never estimated.
- **Chick-fil-A breakfast is not a daypart fork** — the whole menu shows all day.
- **Nuggets stay separate items** (grilled vs breaded) rather than one parent
  with a variant picker. The name already carries the distinction.
- **Raising Cane's is top-down by combo**, not quantity-first. Box Combo,
  Caniac, 3 Finger, Sandwich Combo, Kids — then modify.

## Raising Cane's — DONE

Rebuilt top-down. `orderingModel: "configuration"`, five combos as configured
items, 87 official drink rows in 30 size groups, derived combo-portion fries in a
hidden `pantry` station. Its format picker was deleted — the combos are the entry
point, and `FormatPickerView` now hands straight to the stations whenever it would
have offered a single "Build your own" card.

**Combo fries were the find.** Cane's serves a smaller fry in combos than à la
carte and never says so. Sandwich Combo − Chicken Sandwich = 310/4/39/15 on all
four macros exactly, and that figure then closes the carb column exactly on the
3 Finger (83 g) and Box (98 g) combos. Kid's derives exact on all four. Three
independent subtractions agreeing to the gram — a derivation, not an estimate.

### "Naked Birds" — shipped as the first flagged estimate
Resolved 2026-08-10. The user supplied a community figure (70 cal / 13 P / 0 C /
2 F per finger). It is not official, but it survives two checks: protein is
unchanged from the published breaded finger's 13 g, and Atwater on 13P/0C/2F gives
exactly 70. It ships as `Chicken Finger (Naked)` with `isEstimated: true`, a
brief amber estimate label, and a data note saying plainly that it is a
community estimate.

This established the estimate pattern: label it rather than hiding uncertainty,
retain the reasoning in data notes, and replace it when stronger evidence becomes
available. `ItemConfigurationTests` now requires every estimate to retain its
explanation instead of preventing additional well-supported estimates.

## Chick-fil-A — DONE (two live wrong numbers, both fixed)

1. **Salads were stored dressing-free.** Cobb read 520 against a board figure of
   830, Market 320 against 550, Side Salad 160 against 470 — every salad
   undercounted by a whole dressing. All three now carry their as-served total
   with the designated dressing as a removable default. Each restored total was
   checked by addition and lands on the board figure **exactly**.
2. **Cool Wrap double-count.** Its 660 already contains Avocado Lime Ranch, so
   adding a dressing double-counted and removing the one you actually get was
   impossible. Now composed from a derived undressed base (350/42/29/13) plus the
   published dressing — which closes on all four macros, not just calories.

Also added: Spicy Southwest Salad (680, absent entirely), the 4 missing dressings,
and a Toppings & Buns station so sandwiches can actually be modified. Derived
bases live in a hidden `pantry` station and inherit their parent's allergens —
removing a dressing can only drop an allergen, so inheriting fails safe.
`chick-fil-a.formats.json` deleted: the menu is the entry point.

### Chick-fil-A — breakfast and treats, DONE

Added 2026-08-11 from the `tableData` blob embedded in Chick-fil-A's own
nutrition & allergens page, so macros **and** allergens are sourced rather than
typed: 3 breakfast muffins, the 3 breakfast breads, the whole Treats menu (21
items — milkshakes, frosted lemonades/coffees/sodas, Icedream, cookie, brownie,
Dr Pepper Float), Chicken Tortilla Soup, Buddy Fruits Apple Sauce, and the 3
Honey Pepper Pimento sandwiches. 79 items → 117.

Three judgment calls worth knowing about:

- **The 6-pack cookie is deliberately not shipped.** Chick-fil-A lists it, but
  publishes it PER COOKIE — same 78 g serving, same 370 cal as a single. As a
  "6 ct" size it would have read as six cookies for 370 calories, wrong by a
  factor of six in the direction that matters. Six cookies is a quantity, not a
  size. A test keeps it out.
- **Mini Yeast Rolls are flagged as containing honey**, which is an over-flag
  rather than a fact. Chick-fil-A publishes no ingredient list for the rolls sold
  on their own, and the Chick-n-Minis built on them do carry honey (from the
  spread). An over-flag shows a warning to someone avoiding honey; an under-flag
  feeds it to them. Only one of those is recoverable. Recorded in the item's
  `notes`.
- **Peach Frosted Lemonade's diet build is published with identical macros** to
  the regular, unlike the other two flavours which save 60-70 cal. That is what
  Chick-fil-A prints, so it ships as printed rather than "corrected", with a note.

### Chick-fil-A — drinks, DONE
53 items in 33 rows: teas, lemonades, Sunjoys, sodas and the Pineapple Dragonfruit
range at Small/Medium/Large, plus the coffee menu. Sourced from the same
first-party `tableData` blob, so allergens came with them (every dairy drink
carries `milk`). Not a cosmetic gap — a large Chick-fil-A Lemonade is 380 cal,
more than a Chicken Sandwich minus its bun.

Two things deliberately excluded:
- **Catering gallons** (27 rows across Gallon and Seasonal Gallon Beverages). A
  gallon is not a drink logged against a meal, and they would have doubled the
  station. Same call as Panda's cub meals.
- **The Drinks menu's "Iced Coffee"**, because Chick-fil-A publishes it twice with
  different figures — 661 g / 200 cal there, 624 g / 110 cal as a sub of the
  Coffee menu's Iced Coffee — and the Drinks figure is byte-identical to the Mocha
  Iced Coffee row, so which drink it describes is ambiguous. The Coffee menu's
  four rows (plain 110, Mocha 200, Vanilla 210, Caramel 260) are internally
  consistent, so those ship.

The Frosted Coffees stay on Treats, where Chick-fil-A sells them, rather than
appearing in both stations under two ids.

### Fixed: three names this project broke itself
When the salads were restored to their as-served totals, they kept their old
"(no dressing)" names — so a Cobb read 830 cal while calling itself dressing-free.
Renamed, and a test now scans every menu for the same contradiction.

## CAVA — food already exact; drinks added

A full diff of all 51 items against the official March 2026 nutrition guide found
**zero** macro mismatches. The gap was the drinks, which at CAVA are not a
rounding error — a large Classic Lemonade is 360 cal, more than a Grilled Chicken
and a Saffron Basmati Rice together. Added all 44 published rows across 20 groups
(Kids 12 oz / Small 16 oz / Large 22 oz), spot-checked against the source.

### CAVA — curated bowls, SHIPPED (the block was wrong)

10 of 11 now ship as verified presets. The previous verdict failed for a reason
worth remembering: **cava.com returns HTTP 403 to every programmatic fetch**
(Cloudflare), so a researcher probing it concludes there is nothing there. In a
real browser, cava.com/menu publishes the full composition of every curated bowl
and pita, with a detail page per item.

Two independent checks:
1. The calories on cava.com match the nutrition guide EXACTLY for all 8 bowls —
   same menu vintage, which is precisely what was wrong with the older
   ingredients PDF (Lemon Chicken / Tahini Caesar / Market Spice).
2. **Summation closes.** Composed from this app's own CAVA items, every shipped
   preset lands within 2.8% of its published total, most within 1%.

That summation also settled the one portion question. Portions are not published,
and summing a two-base bowl at full portions overshoots by ~150 cal; halving them
lands Spicy Lamb + Avocado on 798 against a published 800. So a bowl naming two
bases is served half and half — CAVA's own split-base service, which this app
already models as its `greens-and-grains` format. **A pita is not split**: its
base is the pita plus romaine at full portions, and halving those made nothing
close.

**Steak + Feta is held.** Its card lists two dressings (garlic 180 + Greek
vinaigrette 130) and it overshoots by 170 cal — almost exactly one dressing — so
that is near-certainly an either/or the card does not disambiguate.

## Panda Express — food already exact; drinks added

Same story: zero macro mismatches against all 178 published rows. Added the full
drinks list — 102 items, 25 sized groups at Kids 12 / Small 22 / Medium 30 /
Large 42 oz (teas pour 22/32/40, so ounces ride on the item, not the label) —
plus the fortune cookie and apple crisps, and restored the published piece counts
on the appetizers ("3 pcs — 3.6 oz" instead of "1 serving").

Region-locked duplicates (Fanta Orange "PR only", Fanta Strawberry "TX only") are
deliberately omitted: both already exist nationally with different macros, and
two identically-named rows is worse than one.

### Panda Express — Hot & Sour Soup deliberately not carried
Macros and allergens are published; whether the broth is meat-based is not, and
hot & sour soup usually is. `dietaryMarkers: []` would assert "verified free of
meat" on a guess. Blocked on an ingredient source.

## Starbucks — sizes collapsed, and the picker finally reaches the screen

Starbucks shipped **427 rows that are really ~100 drinks**: "Caffè Latte",
"Caffè Latte (Tall)", "Caffè Latte (Venti)", "Caffè Latte (Short)" as four
separate rows. 99 size groups now cover 365 of those items, taking the menu to
161 rows.

**The `SizeGroup` model had existed and been unit-tested for months while no view
ever called it.** `grep sizeGroups()` across the whole app returned nothing
outside the model and its tests — the collapse was real in the data layer and
invisible on screen. `MenuView` now renders one row per dish, and
`SizePickerUITests` exists specifically so that can't silently happen again: it
asserts the collapse from the UI, not from the model.

Two things the migration had to be careful about:

- **Not every parenthetical is a size.** "Pike Place Roast (Medium)" is a roast
  level and "(No Added Sugar)" is a recipe variant; only labels in the known size
  vocabulary are ever stripped. A test pins that Pike Place keeps its "(Medium)".
- **Espresso pours are sizes.** Solo/Doppio/Triple/Quad are one drink at several
  pours, so they share the ladder, with Doppio as the default.

Switching size on a row that's already in the tray **moves** the line rather than
adding a second cup — tapping "Venti" means "make it a Venti", not "and also a
Venti".

### Why the picker is a sheet and not chips in the row

Worth recording, because the obvious design is the one that doesn't work. Both
station-row shapes wrap their content in a `Button`, so **any interactive element
placed inside a row never receives its own taps** — the row swallows them. That
killed inline chips and, later, a `Menu` on the serving text.

Giving the row a second shape to make room for a chip row was worse: it changed
the layout and accessibility tree of the whole station list, and
`PortionControlUITests.testToppingsCountUncapped` went from **29 seconds to
timing out at 190**, with the app reporting "main thread busy for 30.0s".
Isolating it took several passes — it was not the nested scroll view, not the
button style, not the accessibility traits, and *not even whether the chips were
buttons or plain text*. It was the extra structure in every row.

So the row is exactly as it always was, and tapping a multi-size dish opens
`SizeChoiceSheet`. That turned out better anyway: the sheet shows every size with
its full macros, so you can see what a Venti costs before choosing it, which a
row of chips can't do.

One real fix that came out of the same work: `sizeGroups()` was being called
inside the view builder, so it re-derived every group on every body pass of a
non-lazy station list. It's pure derivation over immutable menu data — now cached
once per category.

## The rest of the menus — 471 duplicate rows removed app-wide

With the picker finally reaching the screen, the same collapse applied to
everything else that was listing sizes as separate rows:

| | before | after |
|---|---|---|
| Starbucks | 427 | 161 |
| Panda Express | 140 | 67 |
| Raising Cane's | 103 | 46 |
| Panera | 118 | 102 (8 soups × Cup/Bowl/Bread Bowl) |
| CAVA | 95 | 71 |
| Jersey Mike's | 77 | 67 (sub rolls Mini/Regular/Giant, fries 5 oz/6 oz) |
| Qdoba | 75 | 69 (scoop tiers 1/2/4 oz) |
| Chick-fil-A | 79 | 64 |
| **total** | **1476** | **1005** |

Jersey Mike's fries at 5 oz and 6 oz were on the original complaint list.

### Moe's is ungrouped on purpose

Its four rice rows are not four sizes of one thing: "Seasoned Rice (burrito
portion)" is what goes *inside* a burrito, while "(cup)" and "(bowl)" are sides
you order. Folding them into one picker would let someone choose "bowl" as the
rice in their burrito. Collapsing exists to remove duplicates, not to hide
distinctions — a test pins this so nobody "finishes the job" later.

Subway, Sweetgreen, MOD Pizza and The Halal Guys carry no size variants at all.

## Drinks, everywhere they are published

Every restaurant that publishes beverage nutrition now has a drinks station.
Sourced by a research pass with an adversarial verification stage, and the
verifiers earned their keep — **every correction below was found by a verifier,
not volunteered by the researcher who wrote the data.**

| chain | result |
|---|---|
| Chick-fil-A | 53 items / 33 rows |
| Panera | 183 / 114 |
| Jersey Mike's | 82 / 58 |
| Qdoba | 58 / 40 |
| Sweetgreen | 23 |
| Halal Guys | 20 |
| Chipotle | 18 / 16 |
| Moe's | 12 / 4 |
| Subway, MOD Pizza | **do not publish** — correctly empty |

App-wide this is now 1957 items rendering as 1342 rows.

### The failure mode was the same on every chain

Researchers asserted **fluid ounces and allergens where the source states
neither** — the two fields where "not stated" silently becomes a value.

- **Moe's invented "22 oz" and "32 oz" cups.** The strings "oz" and "ounce"
  appear ZERO times in Moe's 3-page PDF, and the calorie ratio between its own
  sizes (1.89) contradicts a 32/22 cup (1.45). Volumes stripped; Moe's own
  Kids/Regular/Large labels kept. Its macros verified exact.
- **Halal Guys shipped five 24 OZ rows with macros byte-identical to the 16 OZ
  rows** — a copy-paste defect at the source that would have logged a 24 oz drink
  at 16 oz calories. Dropped. Its serving column is also weight-ounces (grams =
  oz × 28.35 across food *and* drink), so "fl oz" was an upgrade the source never
  made.
- **Jersey Mike's "22 fl oz"/"32 fl oz" was inferred from JM's own image
  filenames**, not published. Stripped. Dr. Pepper at Giant was missing entirely
  and has been restored.
- **Panera's macros verified exact** (0 mismatches, column mapping proven
  independently — protein sits after sugars, an easy off-by-one) **but its
  allergen claims cited a guide with no allergen column at all.**
- **Chipotle's own API returns rows where calories are populated and every other
  macro is 0** — incomplete records, not published zeros. 11 excluded, proven by
  cross-checking Chipotle's printed chart where the calories agree but the carbs
  are non-zero.

### The dairy guard

`allergens: []` means "checked, contains none" in this codebase — not "unknown".
For a fountain soda that is true whatever the source says; for a latte it is
dangerous. So any drink whose name implies dairy, nuts or soy is **held back**
unless the source states its allergens. That withheld 29 Panera drinks (every
latte, smoothie, hot chocolate and the kids' milks) and 4 Jersey Mike's cream
sodas.

**27 of the 33 have since shipped.** Panera publishes allergens in a *separate*
first-party document (`c6-26-allergen-guide.pdf`, linked from the same nutrition
page) that the original pass never found — a per-product table with eight allergen
columns, beverages included. Every latte, cappuccino, mocha, chai and smoothie now
carries a sourced `milk`; the hazelnut mochas carry `milk` and `soy`; Tropical
Green Smoothie is an explicit "No Major Allergens Present". Four drinks named
"Iced …" resolve to rows the source itself labels "Hot or Iced", so that mapping
is stated rather than inferred.

Six remain held, and both reasons are the source's:

- **Panera's two kids' organic milks** are simply absent from the allergen guide.
  Obvious as it is that milk contains milk, `[]` would be a claim about a product
  the document never covers — on a children's drink.
- **Jersey Mike's four cream sodas.** Its allergen endpoint
  (`subs.jerseymikes.com/nutrition/allergens`) returns an empty
  `product_ingredients` array, and its ingredient categories are Bread, Cheese,
  Flavors, Meat, Packaging, Toppings, Add-Ons — drinks are not covered at all.

## Navigation: "what are you having?" then "how do you want it?"

The app had grown two shapes. Assembly restaurants (Chipotle, CAVA, Panda) build
on **screen 2** — the station list *is* the builder. Top-down restaurants (Cane's,
Chick-fil-A) list items on screen 2 and build on **screen 3**. On top of that, a
published preset went *straight into the tray*, which read as "done, log it"
while every other route landed somewhere you adjust first.

Every restaurant now answers the same two questions in the same two places:

1. **What are you having?** — combos and sandwiches at Cane's/Chick-fil-A;
   formats and published meals at Chipotle/CAVA/Panda.
2. **How do you want it?** — the station builder for assembly, the component
   screen for top-down.

Three concrete changes:

- **Nothing auto-opens the tray.** A preset or saved recipe lands in the builder
  with its items already in, the tray bar carrying the running total, and the
  tray one tap away. `MenuView.skipTrayAutoOpen` is gone entirely.
- **The configurator is pushed, not presented.** `ConfigureItemSheet` became
  `ConfigureItemScreen` — it occupies the same slot the station builder does,
  rather than floating over screen 1 as a sheet.
- **The size picker stays a sheet**, deliberately. Picking which cup is a
  sub-decision, not a build; giving it a whole screen would overstate it.

Watch out for: pushing that screen put "Add to meal" **behind the floating tab
bar** — as a sheet it sat above it. The commit bar now pads by
`Metrics.tabBarClearance`. The UI tests passed while it was broken, because the
button was still hittable underneath the pill.

### "On the menu" came from a hand-written file, so it was arbitrary

The landing screen's list of orderable things was driven by
`Resources/Presets/<id>.presets.json` — a file that exists for some restaurants
and not others, with no relationship to what a place actually sells:

| | presets | what you saw |
|---|---|---|
| Sweetgreen | 18 | correct |
| Jersey Mike's | 12 | correct |
| Chick-fil-A | 3 (all salads) | sandwiches, nuggets and breakfast hidden behind "Build your own" |
| **Raising Cane's** | **no file** | **landing offered only "Fit my macros" and "Build your own"** |

Now driven by the menu itself. `MenuCategory.isHeadline` marks the stations that
hold whole orderable things — Cane's `combos` + `entrees`, Chick-fil-A's
`entrees` + `mains` + `breakfast` — and the landing screen lists their items,
collapsed by size. Sides, drinks and sauces stay behind the card below, which now
reads **"Browse the full menu"** when there is a menu above it and keeps saying
"Build your own" when there isn't.

Picking one routes via `MenuRoute.configureItemId` straight into its configurator,
so "what are you having?" hands directly to "how do you want it?" with no menu
screen in between. Backing out lands on the full station list, which is a
reasonable "actually, show me everything".

`chick-fil-a.presets.json` was deleted: its three salads are now configurable menu
items carrying as-served totals, which is strictly better than a preset.

Assembly restaurants are untouched — nothing there is picked off a list, so they
keep the format picker.

### Two bugs found by looking at the screen, not the tests

- `CompleteMealCard` rendered **`^[13 item](inflect: true)` literally**.
  `Text(blurb ?? "^[…](inflect: true)")` coalesces to a `String`, which selects
  `Text(verbatim:)` — only a bare literal reaches `LocalizedStringKey`. Masked
  until now because every preset happened to carry a blurb.
- The count itself was meaningless: "13 items" on a Box Combo was counting the
  things you *could toggle*. Headline cards now show the serving line as the
  restaurant prints it ("1 combo — 4 fingers"), plus the cup count when there is
  a size choice.

## Starbucks: the guided path was not collapsing sizes

Build-your-own collapsed correctly while the *default* route into Starbucks did
not, so every drink still listed Short/Tall/Grande/Venti as separate rows. Cause:
Starbucks' formats put the drinks in **prompts**, and `guidedItems(for:)` returned
raw `category.items`, bypassing `sizeGroups()` entirely. The prompt renderer now
groups exactly like a station row. The data was never wrong — 0 ungrouped size
variants, 0 groups missing a Grande.

## Subway's named subs — 37 subs at two sizes

Subway shipped as components only: breads, proteins, cheeses, veggies, sauces.
You could build a sandwich but you could not pick an **Italian B.M.T.**, which is
how essentially everyone orders there. Now 74 rows in 37 size groups, leading the
menu as a headline station.

Macros come from Subway's own January 2026 nutrition PDF. A verifier
reconstructed the table by coordinate rather than reading order — to rule out
column drift — and matched all 30 six-inch rows exactly, Atwater deviating at
most 3.7%.

**Footlongs are Subway's arithmetic, not ours.** The PDF tabulates per 6-inch and
prints under the table: *"Double values for footlong nutrition information (one
footlong = two 6" servings)"*. A deterministic derivation from a published figure,
same class as subtracting two published totals.

Names are as Subway prints them, which is not what anyone calls them: **B.M.T.®**
(not "Italian B.M.T."), **Oven-Roasted Turkey** (not "Turkey Breast"), **Steak
Philly** (not "Steak & Cheese"), **Sweet Onion Teriyaki Chicken®**. The PDF
contains no "Subway Series" branding and no numbered subs at all.

### Every Subway sub ships with UNKNOWN allergens and diet flags

Subway publishes allergens and ingredients **per component** — Genoa Salami,
Artisan Italian bread — and never states what is on a given sandwich. The
nutrition PDF gives no build for the 33 standard subs: not the bread, not whether
cheese is on it, not which vegetables count. So a sub's allergen set is not
derivable from anything Subway publishes.

`nil` means "not checked" and renders that way in the menu; auto-build skips
unknown items entirely when restrictions are on. `[]` would mean "checked,
contains none" — a dangerous lie on a wheat- and cheese-bearing sandwich.

This also threw away the research pass's own meat/pork flags, which the verifier
caught being wrong in **both** directions: B.M.T. (Genoa salami, pepperoni, ham)
carried neither flag, while Veggie Delite asserted a hard `false` the source never
states.

### The dietary guard got stricter, not looser

`everyItemIsFlagged` used to be a bare count (`<= 1`), which conflated *forgetting
to flag an item* with *a chain that publishes nothing*. It is now
`everyUnflaggedItemExplainsItself`: an item with no dietary data must carry a
`notes` saying why. You cannot leave one unflagged by accident, because silence
fails. A second test caps app-wide unknowns at 10% so a chain-wide gap stays
noticeable. Sweetgreen's pesto vinaigrette — the original deliberate unknown —
now carries its reason too, which it never did.

## MOD Pizza publishes calories only

Checked and rejected: MOD publishes no protein, carbohydrate or fat for any menu
item, so a named pizza cannot ship without inventing three macros out of four.
Its build-your-own path already works from real component data.

## Auto-build never suggests a drink

Curating drinks immediately broke the solver: it started closing carb gaps with a
large lemonade, because to an optimiser a drink is just cheap carbs. Drinks are
now excluded from the candidate pool (`MealSolver.neverSolvedCategoryIds`) and a
test pins it. What you drink is the person's decision; the solver fits the food
around it.

### Jersey Mike's — Bowl overstates protein
Bowl is a *size*, not a format, and drops meat to the Wrap/Bowl portion tier. We
keep the full Regular portion, so a Bowl build overstates protein and calories.
Not in the flagship four, but it is a wrong number rather than a missing feature.
