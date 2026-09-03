# Curation Audit — how each restaurant actually orders

Generated from a 14-agent pass that read our menu JSON and then went and looked at
each chain's real ordering flow. This is not about nutrition numbers (those are
sourced and verified) — it is about whether the app mirrors the counter.

| Restaurant | Verdict | Size groups | House configs | Missing | Naming | Confidence |
|---|---|---|---|---|---|---|
| The Halal Guys | CORE_FORMAT_FIXED_GAPS_REMAIN | 9 | 5 | 8 | 12 | medium |
| Jersey Mike's | SIGNIFICANTLY_WRONG | 6 | 9 | 11 | 12 | medium |
| MOD Pizza | SIGNIFICANTLY_WRONG | 1 | 23 | 11 | 17 | high |
| Qdoba | SIGNIFICANTLY_WRONG | 16 | 7 | 20 | 28 | high |
| Raising Cane's | SIGNIFICANTLY_WRONG | 0 | 6 | 11 | 11 | high |
| Starbucks | SIGNIFICANTLY_WRONG | 99 | 14 | 29 | 15 | high |
| CAVA | NEEDS_WORK | 1 | 6 | 9 | 12 | high |
| Chick-fil-A | NEEDS_WORK | 9 | 9 | 23 | 13 | high |
| Chipotle | NEEDS_WORK | 3 | 10 | 23 | 16 | high |
| Moe's | NEEDS_WORK | 15 | 9 | 15 | 21 | high |
| Panda Express | NEEDS_WORK | 0 | 5 | 5 | 6 | high |
| Panera Bread | NEEDS_WORK | 18 | 8 | 18 | 16 | high |
| Subway | NEEDS_WORK | 3 | 6 | 11 | 17 | medium |
| Sweetgreen | NEEDS_WORK | 0 | 6 | 8 | 8 | high |

## The Halal Guys — SIGNIFICANTLY_WRONG

**Core flow resolved 2026-09-02.** Loadout now begins with Regular Platter,
Small Platter, and Sandwich. Each format seeds its officially published rice or
pita portion, lettuce, tomato, white sauce, and hot sauce, then offers one
published protein portion from the matching regular or small/sandwich tier. The former
generic Platter flow seeded only rice, omitted the Small Platter entirely, and
allowed incompatible protein portions to be selected together.

The remaining gaps below are deliberately unresolved. The official nutrition
guide does not publish the half-protein portions needed for a Combo, nor light
or extra sauce portions, so Loadout does not guess those values. Low-carb base
swaps and missing permanent sides also require source-backed portions before
they can ship. The detailed audit remains below as the evidence and history for
those follow-ups; descriptions of the old two-format flow are no longer the
current app behavior.

### How you actually order

The Halal Guys is a one-pass assembly line, and it is SHORT — far shorter than Chipotle. The whole thing is 3 real questions.

STEP 0 — FORMAT AND SIZE, ASKED TOGETHER AS ONE QUESTION. You do not pick a "platter" and then pick a size. You say one phrase: "regular platter", "small platter", or "sandwich". This single choice silently fixes the portion of EVERY component downstream (nutrition guide: Regular = 6 oz protein / 5 oz rice / 4 oz lettuce / 2 oz tomato / 39 g pita; Small = 4 oz / 4 oz / 3 oz / 1 oz / 28 g pita; Sandwich = 4 oz protein / 2 oz lettuce / 1 oz tomato / 79 g pita). This is the "over rice" vs "in a pita" fork plus the size dial in a single breath.

STEP 1 — PROTEIN. "Chicken, gyro, falafel, or combo?" Four answers, and combo (any two of the three) is the famous one. This is the only genuinely required choice.

STEP 2 — NOTHING. The rice, lettuce, tomato and pita go in without being discussed. Nobody is asked "do you want rice?" The container is already being built while you talk. Catering copy states it flatly: all packages include basmati rice, lettuce and tomato, warm pita.

STEP 3 — TOPPINGS. "Any toppings?" — green peppers, onions, jalapeños, olives. Usually a single yes/no or a quick list. Many people skip it entirely.

STEP 4 — SAUCE, AND THIS IS THE REAL CONVERSATION. "White sauce? Hot sauce?" White sauce is assumed yes and goes on heavily; the only negotiation is amount ("light", "extra", "on the side"). Hot sauce is the opposite — it is aggressively hot and the staff will often warn you or give you a small amount by default, so the ask is "just a little" or "on the side". This is the last thing that touches the food before the lid goes on.

STEP 5 — REGISTER. Sides (hummus, fries, extra falafel, wings) and desserts (baklava, baklava cheesecake, cookie) are grabbed or asked for at payment, not built into the container.

HONESTY NOTE: Steps 0-5 are reconstructed from the official menu descriptions, the catering page's stated defaults and selection sequence, and the nutrition guide's section structure — three official sources that agree. I was NOT able to load the live Olo ordering UI (Cloudflare 403 + session-gated SPA), so I cannot tell you the exact modifier-group names or whether the app offers discrete "Light / Regular / Extra / On the side" white-sauce radio buttons. If you want that confirmed, it needs a real browser session on order.thehalalguys.com/menu/53rd-and-6th.

### Sizes

The Halal Guys has NO per-item size picker, and that is the whole point. There are exactly three size/format tiers — Regular Platter, Small Platter, and Sandwich — chosen ONCE at the very start, and every component then scales automatically. The nutrition guide organizes itself this way: its section headings are literally 'Platters Regular', 'Platters Small' and 'SANDWICHES', and each section re-lists the SAME components at different weights (protein 6 oz vs 4 oz vs 4 oz; rice 5 oz vs 4 oz vs none; lettuce 4 oz vs 3 oz vs 2 oz; tomato 2 oz vs 1 oz vs 1 oz; pita 39 g vs 28 g vs 79 g).

Our JSON flattens all three tiers into sibling items inside the same category. The result is that a user building a platter is shown 'Chicken' AND 'Chicken (small platter / sandwich portion, 4 oz)' as two independent checkboxes in a selectMany category — they can tick both and get 10 oz of chicken. Same for lettuce (three sibling entries), rice (three), tomatoes (two), pita (three). Nobody has ever walked up to that counter and asked for '4 oz of chicken'; they say 'small platter'.

The right fix is NOT a per-row size picker. It is to make size a property of the FORMAT — add a third format 'Small Platter' alongside the existing platter/sandwich, and have each format auto-select the correct portion of every component. The groups below are the collapse targets: each is one dish whose members should never be individually visible.

One genuine duplicate worth calling out separately: halal-guys.sauces.tahini-sauce (1 oz) and halal-guys.sides.tahini-side (2 oz) are the same tahini at two portions, split across two different categories.

- **Chicken** — default Regular: Regular (`halal-guys.protein.chicken`), Small / Sandwich (`halal-guys.protein.chicken-small`)
- **Beef Gyro** — default Regular: Regular (`halal-guys.protein.beef-gyro`), Small / Sandwich (`halal-guys.protein.beef-gyro-small`)
- **Falafel** — default Regular: Regular (`halal-guys.protein.falafel`), Small / Sandwich (`halal-guys.protein.falafel-small`)
- **Chicken Wings** — default 4 pc: 4 pc (`halal-guys.sides.chicken-wings-4pc`), 5 oz (`halal-guys.protein.chicken-wings-platter`), 9 oz (`halal-guys.protein.chicken-wings-9oz`)
- **Rice** — default Regular: Regular (`halal-guys.rice.rice`), Small (`halal-guys.rice.rice-small-platter`), Side (`halal-guys.rice.rice-side-6oz`)
- **Lettuce** — default Regular: Regular (`halal-guys.veggies.lettuce`), Small (`halal-guys.veggies.lettuce-small-platter`), Sandwich (`halal-guys.veggies.lettuce-sandwich`)
- **Tomatoes** — default Regular: Regular (`halal-guys.veggies.tomatoes`), Small / Sandwich (`halal-guys.veggies.tomatoes-small`)
- **Pita** — default Platter: Platter (`halal-guys.breads.pita-side`), Sandwich (`halal-guys.breads.pita`), 1 oz (`halal-guys.breads.pita-mini`)
- **Tahini** — default Sauce: Sauce 1 oz (`halal-guys.sauces.tahini-sauce`), Side 2 oz (`halal-guys.sides.tahini-side`)

### House configurations

- **The Standard Platter (what "a chicken over rice" actually contains)** — ON by default. This is the Halal Guys equivalent of Mike's Way, except it is not even a named option — it is simply what a platter IS. You say "chicken over rice" and you receive: protein, seasoned/basmati rice, lettuce, tomato, a warm pita on the side, white sauce, and hot sauce. You do not ask for any of it and you are not asked about any of it except how much sauce. Loadout's platter format currently auto-adds ONLY the rice, so the app's baseline platter is missing 445 calories and 28 g of fat versus the real one — lettuce 17, tomatoes 9, side pita 112, white sauce 300, hot sauce 7. The white sauce alone is 300 cal / 28 g fat at its 2 oz serving, which is more fat than the entire chicken portion. Getting this default wrong is the single largest accuracy defect in the file, because it is wrong on literally every platter a user builds.
  - maps to: `halal-guys.rice.rice`, `halal-guys.veggies.lettuce`, `halal-guys.veggies.tomatoes`, `halal-guys.breads.pita-side`, `halal-guys.sauces.white-sauce`, `halal-guys.sauces.hot-sauce`
- **The Standard Sandwich** — ON by default. Same convention, sandwich form. The pita is the vessel rather than a side, the portions drop to the sandwich column (4 oz protein, 2 oz lettuce, 1 oz tomato, 79 g pita), and there is no rice. White sauce and hot sauce still go on by default. Loadout's sandwich format auto-adds the pita but not the lettuce, tomato or sauces, so it under-reports by roughly 320 cal / 28 g fat.
  - maps to: `halal-guys.breads.pita`, `halal-guys.veggies.lettuce-sandwich`, `halal-guys.veggies.tomatoes-small`, `halal-guys.sauces.white-sauce`, `halal-guys.sauces.hot-sauce`
- **Combo (two proteins, ONE portion — not two)**. The signature Halal Guys order. "Combo over rice" is half gyro, half chicken in a single platter — it is a first-class item on the menu board (Combo Platter, Combo Sandwich), not a modification. Our JSON makes protein selectMany, so a user CAN tick Chicken and Beef Gyro, but they then get 6 oz + 6 oz = 12 oz of meat and 892 calories. A real combo platter is one platter's worth of meat split between two proteins, roughly 3 oz + 3 oz, landing near 446 cal. So Loadout over-reports the most commonly ordered item in the restaurant by roughly 450 calories. This needs to be a named format or a protein-count rule that halves the portions, not two free-standing checkboxes. FLAGGED AS EXTRAPOLATION: the official menu confirms a combo is "a pairing of your choice" and catering confirms "COMBO (ANY TWO PROTEINS)", but Halal Guys publishes NO combo row in the nutrition guide and no explicit statement that the portion is split. The split is inferred from the fact that a combo platter is not sold as double meat and is priced like a single platter.
  - maps to: `halal-guys.protein.chicken-small`, `halal-guys.protein.beef-gyro-small`, `halal-guys.protein.falafel-small`
  - **gap:** A true half-portion protein (~3 oz) for each side of a Regular combo — our smallest protein entries are the 4 oz small-platter/sandwich portions, which are still too large to pair
  - **gap:** A named 'Combo Platter' / 'Combo Sandwich' format that enforces exactly two proteins and halves each
- **White sauce quantity — "extra white", "light white", "on the side"**. Because white sauce is the default and it is the most calorie-dense thing in the building, the amount is the one topic actually negotiated at the counter. "Extra white sauce" is the most common upward modification in the restaurant and doubles a 300 cal / 28 g fat line into 600 cal / 56 g fat — that swing is larger than the entire chicken portion, larger than the rice, and larger than any topping decision. Conversely "light" or "on the side" is how calorie-conscious regulars cut a platter by 150-300 cal without changing anything else. A macro app that models white sauce as a plain on/off checkbox is hiding the single highest-leverage dial on the menu. This wants a quantity stepper or Light/Regular/Extra chips, not a checkbox.
  - maps to: `halal-guys.sauces.white-sauce`
  - **gap:** A 'light white sauce' (~1 oz) portion
  - **gap:** An 'extra white sauce' / side cup of white sauce as a discrete orderable add-on
- **No rice / extra salad (the low-carb build)**. The standard way regulars cut the carbs: "no rice, extra lettuce" or "half rice half salad". The container gets built on lettuce instead of, or alongside, the rice. Dropping the rice removes 238 cal and 50 g carbs — it is the difference between a ~1200 cal platter and a ~960 cal one, and for a macro-tracking app it is the most likely modification a user actually wants to model. Our selectOne rice rule technically permits skipping rice, but there is no 'extra lettuce instead' concept, so the swap silently produces a platter with almost no volume in it.
  - maps to: `halal-guys.rice.rice`, `halal-guys.veggies.lettuce`
  - **gap:** A full 'lettuce base instead of rice' portion — the swap fills the rice's share of the container and is substantially larger than the 4 oz side lettuce we have
  - **gap:** A 'half rice, half salad' half-portion of rice

### Station order

Our order is: protein -> rice -> breads(Pita) -> veggies(Salad) -> toppings -> sauces -> sides -> extras(Dessert).

The back half is right and the front half is wrong. Toppings -> sauces -> sides -> dessert genuinely matches both the counter and the nutrition guide's own section order (TOPPINGS, then SAUCE, then DESSERTS). Protein first is also correct. Three things need to move:

1. ADD A SIZE/FORMAT STATION BEFORE PROTEIN — this is the biggest gap. The real first question is "regular platter, small platter, or sandwich?", asked and answered before any food is named. Loadout's formats.json has only `platter` and `sandwich`; `Small Platter` is missing entirely even though the nutrition guide publishes a full parallel portion set for it. Without it there is no way to express the single most common size decision, and the small-platter portions leak into the item list as sibling checkboxes instead.

2. DELETE `breads` FROM THE PLATTER FLOW — it is currently station 3, sitting between rice and salad, presented as a `selectUpTo: 2` choice. Nobody chooses pita. On a platter it is simply handed to you (auto-add `halal-guys.breads.pita-side`); on a sandwich it IS the format and is already auto-added. Asking "how many pitas, up to two?" as the third question of the build has no counterpart in reality and interrupts the flow at exactly the point where the real line is silently scooping rice.

3. DEMOTE `rice` AND `veggies` FROM DECISIONS TO DEFAULTS — keep them in the sequence for visibility and editing, but pre-checked. Right now `rice` is a selectOne the user must answer and `veggies` (Salad) is a selectMany they must tick. In the restaurant neither is spoken aloud; the rice, lettuce and tomato go in while you are still deciding on toppings. They should render as already-included rows the user can remove, the same way you'd model Mike's Way.

Recommended sequence: [Size/Format] -> Protein (with Combo) -> Rice (pre-checked) -> Salad (pre-checked) -> Toppings -> Sauces (white + hot pre-checked) -> Sides -> Dessert. Pita disappears as a station and becomes an auto-add on both formats.

One smaller note: `sauces` currently mixes the two automatic sauces (white, hot) with two that are not on the current corporate menu at all (tahini, BBQ). The two defaults should lead the station.

### Missing staples

- Falafel as a side — the official Sides category has exactly three items (Falafel, Fries, Hummus) and we have no side falafel at all. The nutrition guide prices it at 2 oz / 202 cal. Adding falafel to a chicken platter is one of the most common add-ons in the restaurant and there is currently no way to express it.
- Baklava Cheesecake — permanent item in the official Desserts category ("The delicious taste of your favorite baklava in the creamy, decadent form of cheesecake!"). Also appears as a catering premium item. We only have plain Baklava.
- Chocolate Chip Cookies — permanent item in the official Desserts category. Missing entirely.
- Chocolate Baklava Cheesecake — in both the nutrition guide DESSERTS section and the catering premium-item list. Missing entirely.
- Chicken Wings 8 pc and 12 pc — the nutrition guide SIDES section lists wings at 4, 8 and 12 pieces. We only carry the 4 pc.
- Extra pita as an orderable side — the nutrition guide lists Pita under SIDES at 2.8 oz / 79 g, separate from the pita that comes with a platter. Ordering an extra pita to mop up the sauce is routine; our three pita entries are all framed as vessels or automatic accompaniments, none as a purchasable side.
- A side cup of white sauce — the highest-frequency paid add-on at the counter and a 300 cal / 28 g fat swing. There is no discrete item for it; the only white sauce entry is the one that belongs to the build.
- A named Combo Platter / Combo Sandwich — this is a first-class item on the menu board (1 of only 4 platters and 1 of only 4 sandwiches) and is arguably the restaurant's signature order. It exists nowhere in our menu or formats file.

### Naming

- "Seasoned Rice" (halal-guys.rice.rice) — this phrase appears nowhere official. The catering page and the board call it BASMATI RICE; customers just say "rice" or "over rice". "Seasoned Rice" reads like a generic fast-casual label and loses the one thing people associate with the dish (the yellow/orange basmati).
- "Hot Sauce" (halal-guys.sauces.hot-sauce) — the official app store description calls it "legendary white and RED sauces", and in NYC it is universally "the red sauce". The menu board does say "hot sauce", so our name is not wrong, but it needs "red sauce" as a searchable alias or users will not find it.
- "BBQ Chicken" (halal-guys.protein.bbq-chicken) — two problems. The catering page calls it SPICY BBQ Chicken, and more importantly it does NOT appear on the current corporate platters or sandwiches menu at all, which lists only Beef Gyro, Chicken, Falafel and Combo. It survives in the nutrition guide and catering only. It is likely regional or discontinued at most locations, so presenting it as a peer of chicken and gyro will mislead.
- "Chicken Wings" as a protein (halal-guys.protein.chicken-wings-platter) — same issue: not on the corporate platters/sandwiches menu, only in catering and the nutrition guide. It belongs under Sides for most stores, where we already have the 4 pc.
- "Chicken Wings (9 oz platter portion)" — this name leaks a source artifact into the UI. It exists only because the nutrition guide filed a 9 oz row under its "Platters Small" heading. No board anywhere says "9 oz platter portion".
- Every portion-suffixed name reads like a spreadsheet row, not a menu item: "Chicken (small platter / sandwich portion, 4 oz)", "Falafel (small platter / sandwich portion)", "Lettuce (small platter portion, 3 oz)", "Tomatoes (small platter / sandwich portion, 1 oz)", "Seasoned Rice (6 oz side)", "Pita (1 oz piece)". These should never be user-visible names — they should be size chips under a collapsed parent, per the sizeSystem groups above.
- "Pita (Served With Platter)" and "Pita (Sandwich)" — nobody says either phrase. The board just says pita. The first is a default that should be auto-added and invisible; the second is the format itself.
- Category "Salad" (id `veggies`) containing only Lettuce and Tomatoes — at the counter this is "lettuce and tomato", never "salad", and calling it Salad implies a salad-base option exists (it does not, though "no rice, extra lettuce" is how people fake one).
- "French Fries" (halal-guys.sides.french-fries) — the official menu item is simply "Fries" ("Classic crinkle-cut fried potatoes").
- "Beef Gyro" — correct on the board, but catering copy and every customer say just "gyro". Needs an alias.
- Tahini appears twice under two different names in two different categories — "Tahini Sauce" (sauces) and "Tahini (Side)" (sides). Also worth noting tahini is not on the current corporate menu.
- Category id `extras` displaying as "Dessert" — internal mismatch that will bite whoever next edits this file, especially since a genuine "extras/add-ons" concept (extra sauce, extra pita, extra falafel) is exactly what the menu is missing.

---

## Jersey Mike's — SIGNIFICANTLY_WRONG

### How you actually order

Jersey Mike's is a numbered-menu shop first and a build-your-own second. The dominant real flow is: (1) You call out a NUMBER AND A SIZE together, as one utterance — "Number 13, giant" / "Number 7, regular." Size is chosen before anything else and is a property of the whole sandwich, not of the bread. The board is organized Favorites → Cold Subs → Hot Subs → Sides/Drinks/Desserts → Kids → Catering, and jerseymikes.com/order 302-redirects straight to /menu/cold-subs. (2) Cold and hot then split into two physically different lines. COLD: the order goes to the slicer, where bread is picked and cut, then the meat is sliced fresh to order onto it, then cheese. HOT: the meat goes on the flat-top grill with the cheese melted into it, and grilled onions + red/green peppers go on the grill at the same time — a hot sub's "toppings" are cooked with the meat, not added after. (3) Both lines converge at the prep/topping table, where the one question everybody is asked is "Mike's Way?" — a single yes/no that applies onions, lettuce, tomatoes, then the oil/vinegar/oregano/salt "juice" in one motion. (4) Any other toppings and condiments (mayo, mustards, pickles, banana peppers, jalapeños, relish) are called out at that same table. (5) Add-ons (extra meat, extra cheese, bacon, avocado) are actually called out earlier, back at the slicer/grill, because they have to be sliced or grilled with the sandwich. (6) Chips, a drink, a cookie/brownie and fries are added at the register at the end. Two structural notes: Wrap and Bowl are SIZES in Jersey Mike's own data model, chosen at step 1 alongside Mini/Regular/Giant — not separate formats; and hot subs have no Mini, only Regular/Giant/Wrap/Bowl.

### Sizes

Four orderable sizes plus two format-sizes, all living in ONE dimension in Jersey Mike's own data: Mini (id 1), Regular (id 2, the default), Giant (id 3), Wrap (id 18) and Bowl (id 20). Sizes 23/24/52/53 also appear in the API but are catering party subs (6x-18x a Regular) and are not individually orderable. Hot subs offer no Mini. THE CRITICAL POINT: size is a property of the whole sub and scales EVERY component, not just the bread. On #7 Turkey and Provolone the API returns Turkey at 56 / 111 / 186 cal for Mini / Regular / Giant, Provolone at 78 / 118 / 196, Olive Oil Blend at 125 / 250 / 500, Mayo at 172 / 261 / 522. Our menu models size only on bread, so a 'Giant' build in Loadout produces Giant bread with Regular meat, Regular cheese and a Regular pour of oil — understating a Giant sub by roughly 300-400 cal. Wrap and Bowl both use their own portion tier (~84% of Regular: Turkey 93 cal); Bowl has no bread row at all, and Wrap swaps the bread for one of five tortillas we do not carry. Collapsing the 14 bread rows into 5 bread choices is necessary but not sufficient — size needs to be promoted to a sub-level modifier that scales protein, cheese and sauces too.

- **White Bread** — default Regular: Mini (`jersey-mikes.breads.white-bread-mini`), Regular (`jersey-mikes.breads.white-bread`), Giant (`jersey-mikes.breads.white-bread-giant`)
- **Wheat Bread** — default Regular: Mini (`jersey-mikes.breads.wheat-bread-mini`), Regular (`jersey-mikes.breads.wheat-bread`), Giant (`jersey-mikes.breads.wheat-bread-giant`)
- **Rosemary Parmesan Bread** — default Regular: Mini (`jersey-mikes.breads.rosemary-parmesan-bread-mini`), Regular (`jersey-mikes.breads.rosemary-parmesan-bread`), Giant (`jersey-mikes.breads.rosemary-parmesan-bread-giant`)
- **Seeded Italian Bread** — default Regular: Mini (`jersey-mikes.breads.seeded-italian-bread-mini`), Regular (`jersey-mikes.breads.seeded-italian-bread`), Giant (`jersey-mikes.breads.seeded-italian-bread-giant`)
- **Gluten Free Bread** — default Regular: Regular (`jersey-mikes.breads.gluten-free-bread`), Giant (`jersey-mikes.breads.gluten-free-bread-giant`)
- **French Fries** — default 5 oz: 5 oz (`jersey-mikes.sides.french-fries-5oz`), 6 oz (`jersey-mikes.sides.french-fries-6oz`)

### House configurations

- **Mike's Way** — ON by default. Onions, lettuce, tomatoes, then the olive oil blend, red wine vinegar, oregano and salt. It is one yes/no question at the counter, not seven topping decisions, and it is what you get unless you say otherwise. On a Regular it adds roughly 279 cal and 28 g fat — almost all of it the olive oil blend at 250 cal / 28 g.
  - maps to: `jersey-mikes.veggies.onions`, `jersey-mikes.veggies.lettuce`, `jersey-mikes.veggies.tomatoes`, `jersey-mikes.sauces.olive-oil-blend`, `jersey-mikes.sauces.red-wine-vinegar`, `jersey-mikes.sauces.oregano`, `jersey-mikes.sauces.salt`
- **Grilled Onions and Peppers (the hot-sub default)** — ON by default. Every cheese steak and Philly comes off the grill with grilled onions and red/green pepper strips already cooked into it. Hot subs are NOT Mike's Way — the API does not even offer lettuce/tomato/oil/vinegar as options on most of them. Adds ~31 cal.
  - maps to: `jersey-mikes.veggies.grilled-onions`, `jersey-mikes.veggies.red-green-pepper-strips`
- **The Juice** — ON by default. The fan/staff name for the olive oil blend plus red wine vinegar poured together. People order 'extra juice', 'light juice', 'juice on the side' or 'no juice'. This is the highest-leverage single modification on the entire menu: the oil alone is 250 cal / 28 g fat on a Regular and 500 cal / 56 g on a Giant, so 'light juice' vs 'extra juice' can swing a sub by 400+ calories.
  - maps to: `jersey-mikes.sauces.olive-oil-blend`, `jersey-mikes.sauces.red-wine-vinegar`
  - **gap:** A light / extra / no-juice intensity control. Loadout can only add or remove the oil at full pour, but the real counter interaction is a dial, and it is the one modification a macro-tracking customer most wants to make.
- **Bowl (formerly 'Sub in a Tub')**. The whole sub built in a bowl with no bread. It is a SIZE at Jersey Mike's, not a separate format — you pick it where you'd pick Mini/Regular/Giant. Meat drops to the Wrap/Bowl portion tier (Turkey 93 cal vs 111 on a Regular), and croutons are offered as an add-on.
  - **gap:** Croutons (90 cal) — an Add-On offered on every Bowl and absent from our menu
  - **gap:** The Wrap/Bowl portion tier: picking Bowl in Loadout keeps the full Regular meat and cheese portions, so a Bowl build overstates protein and calories
- **Wrap**. Same build rolled in a tortilla. Also a SIZE, chosen alongside Mini/Regular/Giant, with its own set of five tortillas and the same reduced meat portion as a Bowl. Loadout has no representation of this at all.
  - **gap:** White Wrap (290 cal, the default)
  - **gap:** Wheat Wrap (310 cal)
  - **gap:** Tomato Basil Wrap (300 cal)
  - **gap:** Spinach Herb Wrap (290 cal)
  - **gap:** Garlic Herb Wheat Wrap (310 cal)
- **Club subs come with bacon and mayo standard** — ON by default. If you order any Club, bacon and mayo are already on it — you don't add them. That is ~65 cal of bacon plus 261 cal / 29 g fat of mayo you get without asking. The California Club swaps mayo for avocado.
  - maps to: `jersey-mikes.extras.extra-bacon`, `jersey-mikes.sauces.mayo`, `jersey-mikes.extras.avocado`
- **Cheese is on the sub already, not an add-on** — ON by default. Nearly every numbered sub is built with cheese as part of the recipe — Provolone on cold subs, White American melted into the meat on cheese steaks. Nobody 'adds cheese'; they'd say 'no cheese' to remove it.
  - maps to: `jersey-mikes.cheeses.provolone`, `jersey-mikes.cheeses.white-american-cheese`
- **White bread is the default; every other bread is a swap** — ON by default. Say nothing and you get White. Wheat, Rosemary Parmesan, Seeded Italian and Gluten Free are all explicit swaps, and Rosemary Parmesan is the well-known enthusiast upgrade.
  - maps to: `jersey-mikes.breads.white-bread`
- **Big Kahuna loadout** — ON by default. #55/#56 Big Kahuna arrive with jalapeños and mushrooms on top of the standard grilled onions and peppers — a hot-sub topping set distinct from every other cheese steak.
  - maps to: `jersey-mikes.veggies.jalapeno-peppers`, `jersey-mikes.veggies.mushrooms`, `jersey-mikes.veggies.red-green-pepper-strips`, `jersey-mikes.veggies.grilled-onions`

### Station order

Our order is breads → protein → cheeses → veggies(Toppings) → sauces(Sauces & Seasonings) → extras → chips → sides. The spine is right — bread, then meat, then cheese, then toppings, then register items — but four things are off.

1. THE BIGGEST GAP IS AT THE FRONT: there is no size step. In the real flow size is the very first thing said, bundled with the sub number ("Number 13, giant"), and it governs every portion downstream. Loadout instead buries size inside the bread list as "White Bread (Giant)". A Size step must be inserted before Bread, and it must carry Mini / Regular / Giant / Wrap / Bowl — the same five choices Jersey Mike's own API exposes as one dimension.

2. SPLIT COLD AND HOT. They are two different physical lines with two different default sets and two different size sets. Cold runs bread → slicer → cheese → Mike's Way; hot runs grill (meat + cheese + onions + peppers cooked together) → sauce, has no Mini, and is never Mike's Way by default. One undifferentiated "sub" format cannot express either correctly. This is a bigger correctness win than any reordering.

3. MOVE EXTRAS UP, from position 6 to right after Cheese. Extra meat, extra cheese, bacon and avocado are called out at the slicer or the grill because they have to be sliced or cooked with the sandwich — you cannot add them at the topping table. Jersey Mike's own taxonomy backs this: they are ingredient_type X "Add-Ons", a peer of Meat and Cheese, not a trailing category.

4. MERGE SAUCES INTO TOPPINGS. Jersey Mike's has no sauces station. The official ingredient_type list is Bread, Cheese, Flavors, Meat, Packaging, Toppings, Add-Ons — and mayo, the mustards, ranch, blue cheese, oil, vinegar, oregano and salt are all type T "Toppings", the same code as lettuce and tomatoes. Splitting them into two Loadout stations breaks the single most important interaction on the menu: Mike's Way spans both of our categories (onions/lettuce/tomatoes in veggies, oil/vinegar/oregano/salt in sauces), so the one question a real customer answers with a single word is scattered across two screens. It should be one station with a Mike's Way toggle at the top of it.

Recommended sequence: Size → Bread (skipped for Bowl) → Meat → Cheese → Add-Ons → Toppings (with a Mike's Way toggle pinned first) → Chips → Sides & Desserts.

### Missing staples

- Cappacuolo — a core deli meat, default on 4 subs including #13 The Original Italian, #2 Jersey Shore's Favorite, #5 The Super Sub and #12 Cancro Special. Its absence is why our presets file has no #13, arguably Jersey Mike's most iconic sandwich.
- Prosciuttini — default on 3 subs (#13 The Original Italian, #2 Jersey Shore's Favorite, #5 The Super Sub). Same blocker as above.
- Extra Meat — offered as an Add-On (ingredient_type X, name 'Meat') on 41 of 43 sub products. This is the most-ordered upgrade for anyone tracking protein and we have no item for it at all. Portion is recipe-specific (56 cal on #7 Turkey, 128 cal on a Philly, 143 cal on the Original Italian).
- The five wrap breads — White Wrap (290 cal, default), Wheat Wrap (310), Tomato Basil Wrap (300), Spinach Herb Wrap (290), Garlic Herb Wheat Wrap (310). Wrap is an orderable size on 34 of 43 subs and we carry none of them.
- Croutons (90 cal) — an Add-On on every Bowl. If someone builds a Bowl in Loadout there is nothing to put on it in place of bread.
- Teriyaki sauce — the default sauce on the Teriyaki Chicken Sub, a permanent hot-sub menu item.
- Halal Philly Beef and Halal Philly Chicken — permanent, not LTO, in halal-certified markets; they back 8 numbered subs (#16, #17, #31, #42, #43, #44, #55, #56 Halal variants) plus 4 halal cold subs.
- Kids' subs — Ham, Turkey and Salami at a dedicated 'Kids' size (its own size id 33). A whole permanent menu section with no representation.
- Breakfast subs — #1 Pork Roll Egg & Cheese, #2 Bacon Egg & Cheese, #3 Sausage Egg & Cheese, #4 Ham Egg & Cheese, #5 Steak Egg & Cheese, plus Egg and Cheese. Permanent at participating stores; the API exposes them as a full Breakfast category in Mini and Regular.
- Large chip bags — the API carries LG.Lays, LG.Doritos, LG.SunChips, LG.Ruffles, LG.Baked and LG.PopCorners alongside the single-serve 'Regular' bags. We only have single-serve.
- PopCorners — a chip brand present in the API's chip lineup that our 13-item chips list omits entirely.

### Naming

- 'Sub in a Tub' (our format id sub-in-a-tub, name 'Sub in a Tub') is the retired name. The board, the app and Jersey Mike's own API all say BOWL. The only place '-tub' survives is legacy image filenames. A customer looking for this in Loadout would find a term staff have stopped using.
- We have no 'Wrap' anywhere, but Wrap is a first-class option on the board sitting right next to Mini/Regular/Giant. Someone who orders wraps cannot find their order in the app.
- 'White Bread (Giant)', 'Wheat Bread (Mini)' etc. — nobody says this out loud. You say 'a giant on white'. Size belongs to the sandwich; our names attach it to the bread, which reads as a different product rather than a different size.
- 'Grilled Chicken (Philly)' — the board says '#16 Mike's Chicken Philly', staff say 'chicken philly' or just 'chicken', and the API ingredient is 'Philly Chicken'. Our parenthetical inverts the actual word order.
- 'Philly Steak' — the API and kitchen call this ingredient 'Philly Beef'; customers say 'steak' or 'cheese steak'. Ours matches neither exactly.
- 'Tuna Salad' — the board says '#10 Tuna Fish' and the API ingredient is 'Made Tuna Salad'. A customer scanning for 'tuna fish' has to translate.
- 'Ranch Dressing', 'Blue Cheese Dressing', 'Thousand Island Dressing' — the API and the board drop 'Dressing' on all three: they are just Ranch, Blue Cheese, Thousand Island.
- 'Extra Cheese' and 'Extra Pepperoni' — the Add-Ons station labels these simply 'Cheese' and 'Pepperoni'. Our 'Extra' prefix is fine as UI copy but it hides that these sit in the same add-on group as Bacon, Avocado, Meat and Hot Honey.
- Category 'Sauces & Seasonings' does not exist at Jersey Mike's. Their taxonomy is Bread / Cheese / Meat / Toppings / Add-Ons / Flavors, and every sauce and seasoning we list is ingredient_type T 'Toppings'.
- Our category 'Toppings' (internal id 'veggies') is narrower than the board's 'Toppings', which includes the sauces too. Two things named Toppings meaning different scopes is a trap for anyone editing the data.
- 'Grilled Portabella Mushrooms' — the API ingredient is singular, 'Grilled Portabella Mushroom'.
- 'Olive Oil Blend' + 'Red Wine Vinegar' as two separate rows — at the counter this is one thing called 'the juice', and it is asked about as one thing ('extra juice', 'light juice'). Neither our item names nor our structure surfaces that word.

---

## MOD Pizza — SIGNIFICANTLY_WRONG

### How you actually order

You are walked down a physical make-line by one person, and the very first question is SIZE — not crust, not sauce. The live ordering system's top-level group is literally named "Choose a Size" (min 1, max 1) and EVERY other station is nested underneath the size you picked. Nothing else can be asked until size is answered.

Real sequence for a pizza (group ordinals verbatim from the live payload):
1. "Choose a Size" — Mini (6" thin crust) / MOD (11" thin crust) / Mega Thick Crust (11"). No size is pre-selected; you must say one.
2. "Alternative Crust Option" (min 0, max 1) — Gluten-Friendly (+$3.50) or Cauliflower Crust (+$3.50). THIS GROUP EXISTS ONLY UNDER THE MOD SIZE. It is absent from Mini and from Mega. You cannot get a gluten-friendly Mini or a cauliflower Mega.
3. "Sauces" (min 1, max 8) — Creamy Alfredo, Garlic Pesto, Garlic Rub, Olive Oil, Spicy Tomato Sauce, Sweet BBQ, Tomato Sauce, and an explicit "No Sauce". Required: you must actively pick something, even if it's No Sauce.
4. "Cheeses" (min 1, max 9) — Asiago, Cheddar, Feta, Gorgonzola, Mozzarella, Parmesan, Plant-Based, Ricotta, and an explicit "No Cheese". Also required.
5. "Meats" (unlimited) — 10 options.
6. "Veggies, Herbs & Good Stuff" (unlimited) — 21 options.
7. "Finishing Sauces" (unlimited) — Balsamic Fig Glaze, Garlic Pesto, Hot Buffalo, Mike's Hot Honey, Ranch, Sriracha Ranch, Sweet BBQ, Tomato Sauce Dollops. This is a SEPARATE station at the END of the line, after the pizza comes out of the oven. It is a different list from the base sauces. Four of these (Balsamic Fig Glaze, Hot Buffalo, Mike's Hot Honey, Sriracha Ranch) are finish-only and can never be a base sauce; Ranch appears here and nowhere else on a pizza.
8. "Cooking Instructions (Optional)" (min 0, max 1) — Light Bake / Extra Crispy. Free. Employees say online "light bake" requests are widely treated as a normal bake anyway.

THE PORTION QUESTION IS ASKED PER TOPPING, NOT ONCE. Every single sauce, cheese, meat and veggie carries its own nested sub-group ("Mozzarella Amount", etc.) with Light / Regular / Extra. Regular is flagged is_default on all of them. All three cost $0. Light = 0.5x calories, Extra = 1.5x (Mozzarella 45 / 90 / 135; Crispy Bacon 70 / 140 / 210). Finishing sauces don't get Light/Regular/Extra — they get "On Top" or "Side Cup" at identical calories, which is the scripted counter question: "Would you like any finishing sauces on your pizza or on the side?"

Salads run the identical spine with two swaps: "Greens" (min 1, max 3 — Arugula, Mixed Spring Greens, Romaine, Spinach) replaces sauce+crust at the front, and "Dressings (On the side)" (min 1, max 9) replaces Finishing Sauces at the back. Sizes are Mini (side salad) / MOD (entrée) / Mega (Feeds 2). There are no Cooking Instructions on a salad.

Price tier is decided by what you built, not chosen up front: cheese-only = "Cheese (The Maddy)", one non-cheese topping = "One Topping", anything more = "Unlimited Toppings", roughly $2 apart. Employees phrase it live as "Cheese isn't counted as a topping... would you like to keep your Maddy or add the sausage". On the two cheaper tiers the veggie station is replaced by a short free list called "Seasoning, Herbs & Extras": Basil, Chopped Garlic, Oregano, Parmesan, Rosemary, Salt & Pepper.

After the build: sides / dessert / drink at the register, then they take a name for the callout ("Pizza for ___").

### Sizes

MOD runs a single named size axis — Mini / MOD / Mega — and it is the FIRST question for both pizza and salad. Our menu encodes it as five sibling crust items in a selectOne category, plus four parallel formats in mod-pizza.formats.json, which is wrong on three counts.

(1) Only three of the five crusts are sizes. Mini (6"), MOD (11") and Mega Thick (11") are the three tiers of "Choose a Size". Gluten-Friendly and Cauliflower are NOT sizes — they are a separate optional group called "Alternative Crust Option" (min 0, max 1, +$3.50 each) that hangs only off the MOD size. Their calorie figures in the live system are deltas (+220 GF, +100 cauliflower) applied to the MOD crust's 490, which is exactly how our 710 and 590 were derived. They should be a crust-swap toggle on the MOD row, not two more rows in the size picker — and the app should not offer them on Mini or Mega, because MOD's own system doesn't.

(2) Mega is not a bigger pizza. It is the same 11" diameter with double dough. Crust goes 490 -> 980, but every topping portion is byte-identical to MOD (Mozzarella Regular = 90 on both; Crispy Bacon Regular = 140 on both). A size picker that implies Mega scales the whole pizza would be misleading.

(3) THE MINI RULE IS THE REAL BUG. Choosing Mini silently halves every topping. Mozzarella Regular is 90 on a MOD and 45 on a Mini; Crispy Bacon 140 vs 70; Asiago 110 vs 55. An employee put it plainly: "If you're getting a mini that's the standard portion." Our data has no way to express this — mod-pizza.formats.json's "mini" format auto-adds the 210-cal crust and then hands the user the exact same full-size topping rows. Every Mini build in Loadout today overcounts toppings by 2x, which on a modest 5-topping Mini is roughly +250 cal and +20g protein of pure error. Collapsing the crusts into one row with a size chip is the fix, but only if picking Mini also applies a 0.5x multiplier to everything downstream.

Salads use the same three labels with DIFFERENT math: Mini 0.5x, MOD 1x, Mega 2x (Mozzarella 45 / 90 / 180), and no crust at all. So the multiplier is a property of the format, not of the label.

On the default: no size is flagged is_default in the live payload — the customer genuinely must pick one. But MOD (11") is the anchor the brand builds everything around ("a free MOD-size pizza when you buy a MOD-size pizza"), it is what a customer who just says "a pizza" gets, and it is what our formats.json already auto-adds. Pre-select MOD, but don't let the user skip past the picker without seeing it.

- **Pizza** — default MOD: Mini (`mod-pizza.crusts.mini-crust`), MOD (`mod-pizza.crusts.mod-crust`), Mega (`mod-pizza.crusts.mega-thick-crust`)

### House configurations

- **Regular — the portion nobody says out loud** — ON by default. Every sauce, cheese, meat and veggie at MOD carries its own hidden three-way portion question: Light / Regular / Extra. Regular is pre-selected on all of them and all three cost exactly $0. Light is 0.5x and Extra is 1.5x — NOT 2x, which is the intuitive guess and is wrong. Verified across dozens of items: Mozzarella 45/90/135, Crispy Bacon 70/140/210, Asiago 55/110/165, Cheddar 60/110/170, Grilled Chicken 35/70/105, Olive Oil 60/120/180. MOD's own corporate portion guide is expressed in pieces, not scoops — an employee quotes it as pepperoni '2-4-6 on mini' and '6-9-12' (another says 7-11-18) for a MOD. Because Extra is free, asking for it is the single most common macro-moving thing a regular does, and no nutrition PDF has ever printed a Light or Extra column. Our menu treats quantity 1 as Regular, which is correct — but there is no way for a user to say Light or Extra, so the two most common deviations from baseline are unrepresentable.
  - **gap:** A Light / Regular / Extra portion control on every sauce, cheese, meat and veggie row (0.5x / 1x / 1.5x). This is a per-item modifier, not an item — it needs to be a schema affordance, not eleven new menu entries.
- **Mini = half of everything, automatically** — ON by default. Ordering a Mini does not just swap a smaller crust in — it halves every topping portion, without anyone mentioning it. Regular Mozzarella is 90 cal on a MOD and 45 on a Mini. Regular Crispy Bacon is 140 vs 70. This is structural, applied by the ordering system to all 40+ toppings, and it is invisible on the nutrition page, which publishes one per-serving number per topping. It is the largest single source of error in our current model.
  - maps to: `mod-pizza.crusts.mini-crust`
  - **gap:** A 0.5x multiplier applied to every non-crust item when Mini is selected. mod-pizza.formats.json's 'mini' format currently swaps only the crust and leaves full-size topping values in place.
- **Mega = double dough only**. The Mega Thick Crust is the same 11" diameter as a MOD with twice the dough. Its topping portions are identical to MOD's, byte for byte, in the live system. So the entire delta between a MOD build and a Mega build is the crust: 490 -> 980 cal, +16g protein, +88g carb, +6g fat, and nothing else moves. Also worth knowing: the Alternative Crust Option group does not exist on Mega, so there is no gluten-friendly or cauliflower Mega.
  - maps to: `mod-pizza.crusts.mega-thick-crust`
- **Extra Everything / "the mountain"**. Because Extra costs nothing, a recognizable class of regular orders every available topping, or every topping at Extra, or both. Staff have a word for it — a mountain — and it is common enough to be a recurring complaint thread. Mechanically it is 1.5x on every selected item, free. Anyone tracking macros who orders this way is nowhere near what a per-item PDF row implies. Employees also admit they quietly under-portion these, so the true number is somewhere between 1x and 1.5x — worth a caveat in the UI rather than a hard multiplier.
  - **gap:** An 'Extra' toggle (1.5x) that can be applied across a whole build at once.
- **Red sauce and mozzarella — the reflex build** — ON by default. Both the sauce and cheese stations are required (min 1) and both carry an explicit opt-out ('No Sauce', 'No Cheese'), so nothing is genuinely automatic. But at the counter the overwhelming default answer is Signature Tomato Sauce plus Mozzarella at Regular, and staff reach for it. It matters for our app because online it is NOT pre-filled and people get burned: a customer reported getting 'literally dough, sauce and pepperoni with no cheese' because they assumed mozzarella was a given. If Loadout pre-seeds a pizza, this is the pair to seed.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`
  - **gap:** Explicit 'No Sauce' and 'No Cheese' options — the live system forces an affirmative choice at both stations, and our selectMany category lets the user simply skip, which silently means the same thing but hides that MOD asks.
- **Finishing sauces: "on your pizza or on the side?"** — ON by default. The last thing you are asked is a scripted question about finishing sauces, and it has a second half most people miss — On Top or Side Cup, at identical calories. Side cups are free and effectively unlimited, so a large share of orders carry sauce the customer never mentions when logging. Employees describe families ordering 15-25 ranch cups with three pizzas. Crucially, the finishing-sauce side cup is a 1-tbsp pour (Ranch = 50 cal), which is a DIFFERENT thing from the 3-tbsp dip cup in our 'dips' category (Ranch Dip = 160 cal) — that larger cup is what comes with Cheesy Garlic Bread. Our menu has no Ranch available on a pizza at all, in either size.
  - maps to: `mod-pizza.sauces.balsamic-fig-glaze`, `mod-pizza.sauces.garlic-pesto`, `mod-pizza.sauces.hot-buffalo-sauce`, `mod-pizza.sauces.mikes-hot-honey`, `mod-pizza.sauces.sriracha-ranch`, `mod-pizza.sauces.sweet-bbq-sauce`, `mod-pizza.sauces.signature-tomato-sauce`
  - **gap:** Ranch as a pizza finishing sauce — we only have mod-pizza.dressings.ranch-dressing filed under Salad Dressing, so it is unreachable from a pizza build. It is 1 of the 8 finishing sauces and by far the most requested.
  - **gap:** An On Top / Side Cup toggle, and the ability to take more than one cup of the same sauce.
- **Free seasonings on a Maddy or One Topping**. MOD prices in three tiers — Cheese (The Maddy), One Topping, Unlimited Toppings — and the tier is determined by what you built, not chosen up front. On the two cheap tiers the full veggie station is replaced by a short free list called 'Seasoning, Herbs & Extras': Basil, Chopped Garlic, Oregano, Parmesan, Rosemary, Salt & Pepper. Regulars use it to upgrade a cheap pizza without leaving the tier. Parmesan on that list is 130 cal / 10g protein at Regular, so 'a cheese pizza with parm and rosemary' is a real order that is materially not a plain cheese pizza. None of this tier logic exists in our menu, so there is no way to model the cheap build at all.
  - maps to: `mod-pizza.veggies.fresh-basil`, `mod-pizza.veggies.chopped-garlic`, `mod-pizza.veggies.oregano`, `mod-pizza.cheeses.parmesan`, `mod-pizza.veggies.fresh-rosemary`, `mod-pizza.veggies.sea-salt-and-pepper`
  - **gap:** The three price tiers themselves (Cheese/Maddy, One Topping, Unlimited) — our formats.json only models Unlimited.
- **Cheesy Garlic Bread comes with a required dip** — ON by default. Cheesy Garlic Bread is not a bare side — the ordering system forces exactly one dipping sauce (min 1, max 1) from a four-item list: Tomato Sauce (20), Garlic Pesto (140), Ranch (160), Sriracha Ranch (100). Ranch is the common pick, so the real-world CGB is ~1500 cal, not the 1340 on our row. It also carries its own Alternative Crust Option. Our menu exposes all eight dips as a free-floating up-to-3 pick on every pizza, which is backwards: standalone dip cups aren't orderable on a pizza online, and the one place a dip is genuinely mandatory has no dip prompt at all.
  - maps to: `mod-pizza.sides.cheesy-garlic-bread`, `mod-pizza.dips.dip-red-sauce`, `mod-pizza.dips.dip-garlic-pesto`, `mod-pizza.dips.dip-ranch`, `mod-pizza.dips.dip-sri-rancha`
  - **gap:** A required select-one dip attached to Cheesy Garlic Bread.
  - **gap:** Gluten-Friendly / Cauliflower crust swap on Cheesy Garlic Bread.
- **Salad dressing on the side, always** — ON by default. The salad dressing station is literally named 'Dressings (On the side)' in the ordering system, and every to-go salad ships with dressing in a cup rather than tossed. Dressings get Regular / Extra only — no Light — and Extra is a clean 2x, unlike toppings' 1.5x (Caesar 100/200, Olive Oil 120/240, Balsamic 60/120). At least one dressing is required, with an explicit 'No Dressing' opt-out. Our category is capped at selectUpTo 2; the real cap is 9.
  - maps to: `mod-pizza.dressings.balsamic-vinaigrette`, `mod-pizza.dressings.caesar-dressing`, `mod-pizza.dressings.greek-vinaigrette`, `mod-pizza.dressings.oil-and-vinegar`, `mod-pizza.dressings.sherry-dijon-vinaigrette`, `mod-pizza.dressings.zesty-tomato-vinaigrette`, `mod-pizza.dressings.ranch-dressing`, `mod-pizza.dressings.extra-virgin-olive-oil`
  - **gap:** Olive Oil as a salad dressing — it is on the live dressing list but our only olive oil row is mod-pizza.sauces.extra-virgin-olive-oil, filed under pizza sauces. (Same 120 cal, so the numbers work; it just isn't reachable from a salad.)
  - **gap:** A 'No Dressing' option.
  - **gap:** Regular / Extra (2x) portion control on dressings.
- **Mad Dog**. MOD's signature meat pizza and, per staff, one of the two most-ordered named pies. Arrives as a pre-checked build you tap to modify. All components at Regular.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.meats.pepperoni`, `mod-pizza.meats.mild-italian-sausage`, `mod-pizza.meats.seasoned-ground-beef`
- **The Maddy (Cheese)**. The starter pizza and the cheapest tier — sauce and cheese only, with a select-one sauce and select-one cheese rather than the multi-select of a full build. The other of the two highest-volume named orders. Historically tied to MOD's charitable 'Maddy button'.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`
  - **gap:** The Maddy tier itself — sauce and cheese become min 1 / max 1 rather than max 8, and the veggie station collapses to the six free seasonings.
- **Caspian**. The BBQ chicken pie. Note it uses Sweet BBQ twice — once as the base sauce and again as a finishing drizzle — so a faithful build needs two servings of mod-pizza.sauces.sweet-bbq-sauce, not one.
  - maps to: `mod-pizza.sauces.sweet-bbq-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.gorgonzola`, `mod-pizza.meats.grilled-chicken`, `mod-pizza.veggies.red-onion`, `mod-pizza.sauces.sweet-bbq-sauce`
- **Mike's Favorite Pizza**. The hot-honey pie — currently promoted and on the live board, but absent from our menu entirely. Three cheeses plus spicy chicken sausage and a Mike's Hot Honey finish.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.parmesan`, `mod-pizza.cheeses.ricotta`, `mod-pizza.meats.spicy-chicken-sausage`, `mod-pizza.veggies.jalapenos`, `mod-pizza.sauces.mikes-hot-honey`
- **Calexico**. Buffalo chicken pie. The Hot Buffalo is a finishing sauce, not a base — the base is red sauce.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.gorgonzola`, `mod-pizza.meats.grilled-chicken`, `mod-pizza.veggies.jalapenos`, `mod-pizza.sauces.hot-buffalo-sauce`
- **Tristan**. The one signature pizza with NO base sauce — it starts on bare dough and gets a Garlic Pesto finish instead. Worth modelling precisely because a builder that requires a base sauce cannot express it.
  - maps to: `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.asiago`, `mod-pizza.veggies.mushrooms`, `mod-pizza.veggies.roasted-red-peppers`, `mod-pizza.sauces.garlic-pesto`
- **Dominic**. Alfredo-base sausage pie.
  - maps to: `mod-pizza.sauces.creamy-alfredo-sauce`, `mod-pizza.cheeses.asiago`, `mod-pizza.meats.mild-italian-sausage`, `mod-pizza.veggies.fresh-basil`, `mod-pizza.veggies.red-onion`, `mod-pizza.veggies.sliced-tomatoes`
- **Jasper**. The simplest signature — four components, spicy chicken sausage and mushroom.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.meats.spicy-chicken-sausage`, `mod-pizza.veggies.mushrooms`
- **Dillon James**. The margherita-adjacent one — no meat.
  - maps to: `mod-pizza.sauces.signature-tomato-sauce`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.asiago`, `mod-pizza.veggies.fresh-basil`, `mod-pizza.veggies.chopped-garlic`, `mod-pizza.veggies.sliced-tomatoes`
- **Lucy Sunshine**. Garlic Rub base with red sauce applied as dollops at the finish rather than spread as a base — the only build that uses the 'Tomato Sauce Dollops' finishing option.
  - maps to: `mod-pizza.sauces.garlic-rub`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.parmesan`, `mod-pizza.veggies.artichokes`, `mod-pizza.sauces.signature-tomato-sauce`
  - **gap:** 'Tomato Sauce Dollops' as a distinct finishing-station option (same 5 cal as the base sauce, but a different station and a different name on the board).
- **Caesar Salad**. Signature salad, dressing included, sold at Mini / MOD / Mega. Also exists as a fixed 'Side Caesar' (410 cal, no modifications allowed). We have no salad format, so neither is buildable.
  - maps to: `mod-pizza.veggies.romaine`, `mod-pizza.cheeses.parmesan`, `mod-pizza.cheeses.asiago`, `mod-pizza.dressings.caesar-dressing`
  - **gap:** Croutons — on the live salad topping list, absent from our menu entirely.
- **Greek Salad**. Signature salad, the most-loaded of the four.
  - maps to: `mod-pizza.veggies.romaine`, `mod-pizza.cheeses.feta`, `mod-pizza.veggies.red-onion`, `mod-pizza.veggies.black-olives`, `mod-pizza.veggies.mama-lils-sweet-hot-peppas`, `mod-pizza.veggies.diced-tomatoes`, `mod-pizza.veggies.chickpeas`, `mod-pizza.veggies.cucumbers`, `mod-pizza.dressings.greek-vinaigrette`
- **Italian Chop Salad**. Signature salad — the only one with meat.
  - maps to: `mod-pizza.veggies.romaine`, `mod-pizza.veggies.arugula`, `mod-pizza.cheeses.mozzarella`, `mod-pizza.cheeses.parmesan`, `mod-pizza.meats.salami`, `mod-pizza.veggies.red-onion`, `mod-pizza.veggies.black-olives`, `mod-pizza.veggies.chickpeas`, `mod-pizza.veggies.green-bell-peppers`, `mod-pizza.dressings.zesty-tomato-vinaigrette`
- **Garden Salad**. Signature salad; also the fixed 'Side Garden' (140 cal, no modifications).
  - maps to: `mod-pizza.veggies.mixed-spring-greens`, `mod-pizza.veggies.romaine`, `mod-pizza.veggies.diced-tomatoes`, `mod-pizza.veggies.cucumbers`, `mod-pizza.dressings.sherry-dijon-vinaigrette`

### Station order

Close, but two stations are in the wrong place and two don't belong on a pizza at all.

Real order (verbatim group descriptions and ordinals from the live payload, under the MOD size):
  0 Alternative Crust Option (MOD size only)
  1 Sauces
  2 Cheeses
  3 Meats
  4 Veggies, Herbs & Good Stuff
  5 Finishing Sauces
  6 Cooking Instructions (Optional)

Ours: crusts -> sauces ("Sauces & Finishes") -> cheeses -> meats -> veggies -> dressings ("Salad Dressing") -> dips ("Dipping Sauce (side cup)") -> sides -> extras ("Sweets").

The spine — crust, sauce, cheese, meat, veggies — is right, and that matters. What should move:

1. SPLIT "Sauces & Finishes" IN TWO. This is the main structural error. Our single 11-item category fuses two stations that sit at opposite ends of the line. MOD asks for a base sauce second (7 options + No Sauce) and asks about finishing sauces last, after the pizza is out of the oven (8 options, each On Top or Side Cup). Four items are finish-only and can never be a base — Balsamic Fig Glaze, Hot Buffalo, Mike's Hot Honey, Sriracha Ranch. Two appear in both lists — Garlic Pesto and Sweet BBQ. Signature Tomato Sauce appears as base sauce AND, under a different board name, as "Tomato Sauce Dollops" at the finish. Presenting all eleven at once lets a user put hot honey under the cheese, which isn't a thing MOD will do, and hides the fact that Caspian takes BBQ twice.

2. MOVE "dressings" OFF THE PIZZA FLOW. mod-pizza.formats.json lists "dressings" in optionalCategoryIds for all four pizza formats. Salad dressing is not offered on a pizza. It belongs to a salad format that doesn't exist yet. The one exception is Ranch, which IS a pizza finishing sauce — but that argues for adding Ranch to the finishing station, not for exposing the whole dressing rack.

3. MOVE "dips" ONTO CHEESY GARLIC BREAD. Same problem: "dips" is offered on every pizza at up to 3. The live system has exactly one dipping-sauce prompt in the entire menu, attached to Cheesy Garlic Bread, min 1 max 1, four choices. Nothing else in the app should surface a 3-tbsp dip cup.

4. ADD A COOKING INSTRUCTIONS STEP AT THE VERY END. Light Bake / Extra Crispy, pick at most one, free. It changes no macros, so it doesn't affect the number — but it is the literal last question asked and its absence makes the walkthrough end one beat early. Low priority; treat as a garnish, and note that employees say online light-bake requests are usually baked normally anyway.

5. GATE THE ALT CRUSTS TO MOD SIZE. Gluten-Friendly and Cauliflower are ordinal 0 under MOD only — not under Mini, not under Mega. Our "alt-crust" format lets a user build them free-standing with no size context.

6. Sides and Sweets last is correct — those are register add-ons after the build is done. Leave them.

### Missing staples

- SALADS — THE ENTIRE FORMAT. This is the biggest gap by volume. Salads are a co-equal category with pizza at MOD: same three sizes (Mini side salad / MOD entrée / Mega feeds 2), same price, same unlimited-toppings promise, same make-line. The flow is Greens (min 1, max 3: Arugula, Mixed Spring Greens, Romaine, Spinach) -> Cheeses -> Meats -> Veggies, Herbs & Good Stuff -> Dressings (On the side). Our menu has a 'Salad Dressing' category with nowhere to put it and no greens station, so a salad is literally unbuildable in Loadout today. Topping portions scale Mini 0.5x / MOD 1x / Mega 2x — note that is a DIFFERENT multiplier set than pizza, where Mega is 1x.
- THE TEN SIGNATURE PIZZAS as one-tap presets: Mad Dog, Cheese (The Maddy), Caspian, Calexico, Tristan, Dominic, Jasper, Dillon James, Lucy Sunshine, Mike's Favorite Pizza. Staff report these dominate the order mix ('most were Maddogs & Maddys'). Exact component lists for all ten are in houseConfigs above, mapped to our ids. Nutrition totals already cross-check against modpizza.com.
- THE FOUR SIGNATURE SALADS as presets: Caesar, Greek, Garden, Italian Chop. Component lists mapped in houseConfigs.
- CROUTONS — a permanent salad topping in 'Veggies, Herbs & Good Stuff' on the salad side. Not in our menu at all, and it's the one Caesar component we can't express.
- SIDE CAESAR (410 cal) and SIDE GARDEN (140 cal) — permanent fixed-recipe items in the Sides category, explicitly marked 'No modifications or substitutions'. Neither is in our menu; our Sides category has exactly one item.
- KIDS MEAL — a permanent category of its own: a Mini (6") cheese or one-topping pizza plus a kids drink (Milk 8 oz or Apple Juice 6 oz). Marked no modifications.
- RANCH AS A PIZZA FINISHING SAUCE — we have mod-pizza.dressings.ranch-dressing but it's filed under Salad Dressing, so it cannot be added to a pizza. Ranch is one of the eight finishing sauces and, per staff, the single most-requested side cup in the building.
- OLIVE OIL AS A SALAD DRESSING — on the live 9-item dressing list. We have it only as mod-pizza.sauces.extra-virgin-olive-oil under pizza sauces. Same 120 cal, wrong station.
- THE THREE PRICE TIERS — Cheese (The Maddy), One Topping, Unlimited Toppings. Only Unlimited is modelled. The cheap tiers have a genuinely different build (select-one sauce, select-one cheese, and a six-item free 'Seasoning, Herbs & Extras' list in place of the 21-item veggie station), so they aren't just a price label.
- FREE PACKET EXTRAS at the register — Red Pepper Flakes, Parmesan Cheese, Salt, Pepper. Macro-trivial individually but they're a real permanent category ('Extras') and the parmesan packet isn't nothing.
- NOT MISSING — correctly excluded: beverages (16 permanent SKUs) are out of scope per the food-only rule, and Strawberry Lemonade No Name Cake is explicitly an LTO ('a returning favorite', 'limited edition').

### Naming

- 'Sauces & Finishes' is a category name MOD never uses and that no employee would say. The board and the ordering system have two separate stations: 'Sauces' and 'Finishing Sauces'. Fusing them into one label is what causes the station-order problem above.
- Our sauce names are the nutrition-PDF long forms, not the board forms. Board / spoken -> ours: 'Tomato Sauce' -> 'Signature Tomato Sauce'; 'Spicy Tomato Sauce' -> 'Spicy Calabrian Chili Tomato Sauce'; 'Creamy Alfredo' -> 'Creamy Alfredo Sauce'; 'Sweet BBQ' -> 'Sweet BBQ Sauce'; 'Hot Buffalo' -> 'Hot Buffalo Sauce'; 'Olive Oil' -> 'Extra Virgin Olive Oil'. Nobody at the counter says 'Spicy Calabrian Chili Tomato Sauce'.
- 'Jalapenos' should be 'Pickled Jalapenos' — that's the board name and it's what distinguishes them from the fresh Serranos.
- 'Red Onion' should be 'Red Onions - Sliced'. Every signature-pizza description uses the plural sliced form.
- 'Vine-Ripened Tomatoes - Sliced' / '- Diced' are the PDF names. The board and ordering system say 'Tomatoes - Sliced' / 'Tomatoes - Diced'. Ours will sort under V instead of T, which is where a user will look.
- 'Plant-Based Cheese' is 'Plant-Based' on the cheese board (the station already says cheese). Minor, but it also appears as 'dairy-free cheese' on the nutrition page — three names for one item.
- 'Seasoned Ground Beef' is just 'Ground Beef' everywhere in the ordering system.
- 'Sea Salt & Pepper' is 'Salt & Pepper' on the live topping list. More importantly, standalone 'Sea Salt' (mod-pizza.veggies.sea-salt) does not exist as a separate topping in the current build — there is one combined Salt & Pepper option. Two rows where the line has one.
- Four of our veggies are not on the live pizza OR salad topping list at all: Cilantro, Banana Peppers, Serrano Peppers, Scrambled Egg. Three are already flagged '(limited locations)' in our data, but Cilantro is not flagged and appears to be gone. Consider marking or retiring.
- Four of our 'Veggies & Good Stuff' entries are salad-only and would confuse a pizza build: Chickpeas, Cucumbers, Croutons (missing), and the greens — Romaine and Mixed Spring Greens are a required Greens station on a salad, not toppings you scatter on a pizza. Arugula and Spinach are on both lists, so they're fine either way.
- Our category label 'Veggies & Good Stuff' drops a word. The station is 'Veggies, Herbs & Good Stuff' — and the herbs matter, because they're the free items on the cheap tiers.
- 'Salad Dressing' should read 'Dressings (On the side)' — the on-the-side part is the station's actual name and encodes the default.
- 'Dipping Sauce (side cup)' collides with the finishing-sauce side cup. Two different things share the phrase 'side cup': a 1-tbsp finishing sauce poured into a cup (Ranch = 50 cal) and the 3-tbsp dip cup that comes with garlic bread (Ranch Dip = 160 cal). Our dip names ('Red Sauce Dip', 'Sri-Rancha Dip') are also PDF-speak; the CGB prompt just says Tomato Sauce, Garlic Pesto, Ranch, Sriracha Ranch.
- Crust names carry the size inside the item name — 'Mini Crust (6" thin)', 'MOD Crust (11" thin)'. Once these collapse into one row with a size chip the word 'Crust' should drop out: the chips are Mini / MOD / Mega, and the board never says 'MOD Crust'.
- 'Mega Thick Crust (11")' will read as a bigger pizza to anyone who hasn't been. It's the same 11" with double dough. The chip should be 'Mega' with a subtitle that says double dough, same size.
- Our 'Sweets' category id is 'extras', but MOD has a real category called 'Extras' (the free packets) and a separate one called 'Desserts'. If we ever add the packets the id will fight the label.
- Pepperoni's serving description says 'per 1/4 cup (5 slices)'. MOD's own operational portion guide, per employees, is 9-11 slices for a Regular MOD (quoted variously as '6-9-12' and '7-11-18'; 'Mad dog runs 9'). Mini is 2-4-6. The calorie figure is MOD's own so I'm not disputing it, but '5 slices' will not match what a user counts on their pizza, and same-shaped counts appear on Salami, Canadian Bacon, Sliced Tomatoes and Anchovies.

---

## Qdoba — SIGNIFICANTLY_WRONG

### How you actually order

You are walked down a glass line and the FIRST question is always protein — not rice. Qdoba is not Chipotle in this respect, and the online builder makes the same ask in the same order.

Create Your Own Bowl (the canonical build), exactly as the builder presents it:
1. CHOOSE YOUR PROTEIN — Choose One, REQUIRED. Options: Flame-Grilled Adobo Chicken, Flame-Grilled Steak, Brisket Birria, Pork Carnitas, Ground Beef, Cholula Hot & Sweet Chicken, NEW Spicy Tequila Lime Steak, Vegetarian (No Protein). Once you pick one, an "ADD DOUBLE PROTEIN" modifier expands underneath that specific protein, and the step is badged "DOUBLE PROTEIN — TRY IT TODAY!". The line summary then reads e.g. "Flame-Grilled Adobo Chicken (No Additional Protein)".
2. CHOOSE YOUR RICE — Choose One, REQUIRED: Cilantro Lime Rice / Seasoned Brown Rice / Half Cilantro and Half Brown Rice / No Rice.
3. CHOOSE YOUR BEANS — Choose One, REQUIRED: Black Beans / Pinto Beans / Half Black and Half Pinto Beans / No Beans.
4. SIGNATURE QUESOS — Choose up to ONE: 3-Cheese Queso / Queso Diablo. This is its own station, poured, and mutually exclusive.
5. FLAVORFUL TOPPINGS — Choose up to SIX, one combined rail: Hand-Crafted Guacamole, Pickled Red Onions, Pickled Jalapenos, Fajita Veggies, Shredded Cheese, Sour Cream, Romaine Lettuce, Cotija (Crumbled White Cheese), Crispy Tortilla Strips, Cilantro. Note guac lives HERE, not with the queso.
6. SALSAS & SAUCES — Choose up to THREE, one combined list with heat labels printed: Roasted Tomato Salsa (Mild), Freshly Made Pico de Gallo (Mild), Chile Corn Salsa (Mild), Citrus Lime Vinaigrette (Mild), Salsa Verde (Medium), Chile Crema (Medium), Picante Ranch Dressing (Medium), Salsa Roja (Hot), Fiery Habanero Salsa (Hot). The dressings/cremas are in this list, sharing the cap of three.
7. ADD EXTRAS — drinks, CHIPS DIPS & SIDES, desserts, and a "MAKE IT A MEAL" button.

Format variants, all of which keep protein first:
- BURRITO: protein -> INCLUDED TORTILLA (Choose One, Required — the only option is "Warm Flour Tortilla"; the customer is never asked a tortilla size) -> rice -> beans -> quesos -> toppings -> salsas -> extras.
- 3 TACOS: protein -> CHOOSE YOUR TORTILLA (Required: Warm Flour Tortilla / Crispy Corn Tortilla) -> quesos -> toppings -> salsas -> extras. There is NO rice step and NO beans step for tacos.
- SALAD: protein -> BOWL OR CRISPY TORTILLA SHELL (Required: Bowl / CRUNCHY Tortilla Shell) -> CHOOSE YOUR DRESSING (SERVED ON THE SIDE) (Choose One, REQUIRED: Picante Ranch Dressing (Medium) / Citrus Lime Vinaigrette / No Dressing) -> beans (Required) -> quesos -> toppings -> salsas (with the two dressings removed, since they were chosen above) -> extras. NO rice step.
- 3-CHEESE NACHOS: protein -> beans (Required) -> SIGNATURE QUESOS (Choose One, REQUIRED here, with an explicit "No Queso") -> FRESHLY MADE TORTILLA CHIPS ON THE SIDE (Required) -> toppings -> salsas -> extras. NO rice step.

Every single builder page carries the same closing line in its description: "Top it with guacamole and queso for FREE!"

### Sizes

Qdoba has no named size tiers on the build-your-own line — no small/medium/large, no Grande/Venti. You order a format (Bowl, Burrito, Tacos, Salad, Nachos, Quesadilla) and every portion inside it is a fixed scoop. There are only three real size axes on the actual menu board: (a) entree vs mini — the Bowls category lists both 'Create Your Own Bowl' and 'Create Your Own Mini Bowl'; (b) taco COUNT — 'Create Your Own 3 Tacos' vs 'Create Your Own Taco'; (c) the chips-and-dip portions, where guac and both quesos are sold as a regular scoop or a double. None of these are a size picker inside a build. What our JSON has instead is fourteen hidden portion-duplicate pairs — kids portions, half portions and double scoops shipped as sibling rows in the same picker. Those are the real collapse targets: nobody at the counter chooses between 'Black Beans' and 'Black Beans (kids, 2 oz)' as if they were two different foods. Note also that the flour tortilla sizes are NOT a customer choice — the burrito builder offers only 'Warm Flour Tortilla' with no size question, so tortilla size should be format-driven, not user-facing.

- **Hand-Crafted Guacamole** — default 2 oz: 1 oz (`qdoba.dips.hand-smashed-guac-kids-1oz`), 2 oz (`qdoba.dips.hand-crafted-guacamole`), 4 oz (`qdoba.dips.hand-crafted-guacamole-4oz`)
- **3-Cheese Queso** — default 2 oz: 1 oz (`qdoba.dips.three-cheese-queso-kids-1oz`), 2 oz (`qdoba.dips.three-cheese-queso`), 4 oz (`qdoba.dips.three-cheese-queso-4oz`)
- **Queso Diablo** — default 2 oz: 2 oz (`qdoba.dips.queso-diablo`), 4 oz (`qdoba.dips.queso-diablo-4oz`)
- **Cilantro Lime Rice** — default 4 oz: Kids 2 oz (`qdoba.rice.cilantro-lime-rice-kids-2oz`), 4 oz (`qdoba.rice.cilantro-lime-rice`)
- **Seasoned Brown Rice** — default 4 oz: Kids 2 oz (`qdoba.rice.seasoned-brown-rice-kids-2oz`), 4 oz (`qdoba.rice.seasoned-brown-rice`)
- **Black Beans** — default 4 oz: Kids 2 oz (`qdoba.beans.black-beans-kids-2oz`), 4 oz (`qdoba.beans.black-beans`)
- **Pinto Beans** — default 4 oz: Kids 2 oz (`qdoba.beans.pinto-beans-kids-2oz`), 4 oz (`qdoba.beans.pinto-beans`)
- **Shredded Cheese** — default 1 oz: Kids 0.5 oz (`qdoba.cheeses.shredded-cheese-kids-0-5oz`), 1 oz (`qdoba.cheeses.shredded-cheese`)
- **Flame-Grilled Adobo Chicken** — default 3.5 oz: Kids 1.75 oz (`qdoba.protein.grilled-adobo-chicken-kids`), 3.5 oz (`qdoba.protein.grilled-adobo-chicken`)
- **Flame-Grilled Steak** — default 3.5 oz: Kids 1.75 oz (`qdoba.protein.grilled-steak-kids`), 3.5 oz (`qdoba.protein.grilled-steak`)
- **Pork Carnitas** — default 3.5 oz: Kids 2 oz (`qdoba.protein.pork-carnitas-kids`), 3.5 oz (`qdoba.protein.pork-carnitas`)
- **Chorizo** — default 3 oz: 1.5 oz (`qdoba.protein.chorizo-1-5oz`), 3 oz (`qdoba.protein.chorizo`)
- **Bacon** — default 2 oz: 1 oz (`qdoba.protein.bacon-1oz`), 2 oz (`qdoba.protein.bacon`)
- **Tortilla Chips** — default Regular: Small (`qdoba.chips.tortilla-chips-small`), Regular (`qdoba.chips.tortilla-chips`)
- **Romaine Lettuce** — default Topping: Topping (`qdoba.veggies.romaine-lettuce`), Salad bed (`qdoba.veggies.romaine-lettuce-salad-base`)
- **Warm Flour Tortilla** — default 12.5 in: 5.5 in (`qdoba.tortilla.flour-tortilla-5-5`), 10 in (`qdoba.tortilla.flour-tortilla-10`), 12.5 in (`qdoba.tortilla.flour-tortilla-12-5`)

### House configurations

- **Free Guac and Queso**. Qdoba's defining convention and the thing they market hardest: guacamole and queso cost nothing on any entree. This is the opposite of Chipotle, where guac is a visible upcharge and most people therefore skip it. Because there is zero price friction, guac and queso go on a very large share of Qdoba orders — the counter staff actively offer both, and the builder page pushes it. For a macro app this is the single most consequential fact about Qdoba: the 'default-ish' bowl a regular walks out with is roughly 160 cal and 16 g fat heavier than the same bowl anywhere else, and users will not think to log it because it was free and they didn't ask for it by name. Adding a 2 oz guac scoop plus a 2 oz 3-Cheese Queso scoop is +160 cal / +4 g protein / +8 g carb / +16 g fat.
  - maps to: `qdoba.dips.hand-crafted-guacamole`, `qdoba.dips.three-cheese-queso`
- **Double Protein**. Not a special request — a first-class modifier. On the protein step the builder shows a "DOUBLE PROTEIN — TRY IT TODAY!" badge, and the moment you select a protein an "ADD DOUBLE PROTEIN" control expands directly beneath that protein; the summary line then reads "Flame-Grilled Adobo Chicken (No Additional Protein)" until you toggle it. Qdoba also merchandises it as a standing menu item, the "Double Protein Post-Workout Bowl". This is the macro-tracker's order at Qdoba and our app has no way to express it inside a build — we only have two fixed pre-built entrees. Effect is exactly one additional protein portion (e.g. chicken: +190 cal / +19 g protein / +2 g carb / +12 g fat).
  - maps to: `qdoba.protein.grilled-adobo-chicken`, `qdoba.protein.grilled-steak`, `qdoba.protein.brisket-birria`, `qdoba.protein.pork-carnitas`, `qdoba.protein.ground-beef`
  - **gap:** A quantity/x2 mechanic on the chosen protein — the correct model is one protein item at quantity 2, not a separate 'double' item
- **Half-and-Half Rice / Half-and-Half Beans**. Explicit, named, non-negotiable options in the builder — not a favour you ask for. The rice step offers "Half Cilantro and Half Brown Rice" and the beans step offers "Half Black and Half Pinto Beans", each sitting as a fourth radio button alongside the two singles and the 'No' option. Macro impact is real and our model gets it actively wrong in the dangerous direction: our rice and beans categories are selectMany, so a user who wants half-and-half will tick both rows and be charged two full 4 oz portions — 8 oz of rice (+360 cal) where the restaurant gives 4 oz total (+180 cal). That is a ~180 cal overcount on one of the most common Qdoba orders.
  - maps to: `qdoba.rice.cilantro-lime-rice`, `qdoba.rice.seasoned-brown-rice`, `qdoba.beans.black-beans`, `qdoba.beans.pinto-beans`
  - **gap:** Half Cilantro and Half Brown Rice (2 oz + 2 oz, ~180 cal)
  - **gap:** Half Black and Half Pinto Beans (2 oz + 2 oz, ~135 cal)
- **Salad dressing, served on the side** — ON by default. On a Qdoba salad the dressing step is REQUIRED and single-choice, and the step is literally titled 'served on the side'. So unless you actively pick 'No Dressing', you leave with a full sealed 1.5 oz cup — you get it by default. Two consequences a nutrition PDF will never surface: (1) the app should auto-attach a dressing to every salad build rather than treating it as an optional extra, and (2) because it arrives in a cup rather than tossed, the person who pours half is logging roughly 50 calories they never ate — an all-or-nothing 80–100 cal / 8 g fat line that is worth a portion control. Note our dressings category also wrongly allows two at once; the real salad step is choose exactly one.
  - maps to: `qdoba.dressings.citrus-vinaigrette`, `qdoba.dressings.picante-ranch-dressing`
  - **gap:** 'No Dressing' as an explicit zero-macro choice
- **Nachos always come with chips on the side** — ON by default. Qdoba's nachos are not assembled — the chips are bagged separately so they stay crisp, and 'FRESHLY MADE TORTILLA CHIPS ON THE SIDE' is a required step with only one option, so it is not skippable. That means a nacho order silently carries a full chip portion, which is by far the largest macro line in the dish (a 4 oz regular chip portion is 560 cal / 75 g carb / 26 g fat — more than the protein, rice and queso combined). Anyone building nachos in our app today gets no chips at all, because we have no nachos format.
  - maps to: `qdoba.chips.tortilla-chips`
  - **gap:** The exact chip weight served with a nachos entree — the builder does not state ounces, so whether it is the 4 oz regular or a smaller nacho-specific portion is unverified
- **Queso is one-or-none, and it is not the same station as guac**. At the counter the queso is ladled from two warmers at a dedicated station and you get ONE of them — 3-Cheese or Diablo, never both. Guacamole is a separate scoop from the cold toppings rail. Our JSON fuses them into a single 'Queso & Guac' category with selectUpTo max 3 drawn from a pool of eight rows, which means the app will happily let someone build 3-Cheese Queso + Queso Diablo together (an order Qdoba will not make, worth a phantom +80–90 cal / +8 g fat), or stack a 2 oz and a 4 oz guac on the same bowl. On the nachos build the constraint is even stronger: queso becomes REQUIRED choose-one, with an explicit 'No Queso' opt-out.
  - maps to: `qdoba.dips.three-cheese-queso`, `qdoba.dips.queso-diablo`, `qdoba.dips.hand-crafted-guacamole`
  - **gap:** 'No Queso' as an explicit choice on the nachos build
- **Make It a Meal**. A dedicated button at the end of every build that bolts chips and a drink onto the entree. It is the standard upsell every customer is walked through, and the chips half of it is a 560 cal / 26 g fat addition that people routinely forget was part of the combo rather than a separate purchase. Our formats expose chips as just another optional category rather than as the end-of-line meal upgrade it actually is.
  - maps to: `qdoba.chips.tortilla-chips`
  - **gap:** The fountain drink component (out of scope — menus ship food only)

### Station order

Our order does not match, and the mismatch starts at station one.

OURS: tortilla -> rice -> beans -> protein -> veggies -> salsa -> cheeses -> dips -> toppings -> dressings -> chips -> sides -> extras
REAL: protein -> vessel -> rice -> beans -> queso -> toppings -> salsas & sauces -> extras

What should move, most important first:

1. PROTEIN MOVES TO FIRST. Every one of the five builders I opened asks protein before anything else, and it is the only step marked Required on all five. We currently ask it fourth, after rice and beans, which is the Chipotle sequence, not the Qdoba one. This is the single biggest correction. It also matters functionally: the ADD DOUBLE PROTEIN modifier and the per-protein pricing hang off this step, so it has to come first for those to make sense.

2. THE VESSEL STEP MOVES TO SECOND AND BECOMES FORMAT-SPECIFIC. It is not a generic 'tortilla' station. Burrito asks "INCLUDED TORTILLA" with exactly one option (Warm Flour Tortilla — no size question). Tacos ask "CHOOSE YOUR TORTILLA": Warm Flour Tortilla or Crispy Corn Tortilla. Salad asks "BOWL OR CRISPY TORTILLA SHELL": Bowl or CRUNCHY Tortilla Shell. Bowls and Nachos have no vessel step at all. Our formats put the tortilla category first and offer the Crunchy Tortilla Shell as a TACO shell — it is a SALAD vessel, which is why the salads page is titled "Fresh Mexican Salads in a Crunchy Tortilla Shell".

3. COLLAPSE FOUR CATEGORIES INTO ONE. Our veggies, cheeses, dips(guac) and toppings are a single real station: "FLAVORFUL TOPPINGS — Choose up to Six", containing Hand-Crafted Guacamole, Pickled Red Onions, Pickled Jalapenos, Fajita Veggies, Shredded Cheese, Sour Cream, Romaine Lettuce, Cotija, Crispy Tortilla Strips, Cilantro. One rail, one cap of six. Right now we present those same ten things across four screens with no shared limit.

4. SPLIT QUESO OUT AND PUT IT BEFORE TOPPINGS. "SIGNATURE QUESOS — Choose up to One" is its own station sitting between beans and toppings. Pull the two quesos out of our dips category, leave guac in the toppings rail, and enforce one-of-two (required-with-No-Queso on nachos).

5. FOLD DRESSINGS INTO SALSAS AND MOVE SALSAS LAST. There is no separate dressings station on a bowl/burrito/taco/nachos build — Citrus Lime Vinaigrette, Chile Crema and Picante Ranch Dressing are rows inside "SALSAS & SAUCES — Choose up to Three", sharing that cap with the six salsas, and the whole thing comes AFTER toppings. We currently run salsa third-from-protein and dressings as a separate later station with its own cap of two. The one exception is the salad, where dressing is promoted to its own required choose-one step placed right after the vessel and before beans, and is then removed from the salsa list.

6. RICE AND BEANS BECOME REQUIRED WITH EXPLICIT 'NO' OPTIONS, AND DISAPPEAR ENTIRELY ON SOME FORMATS. Both are "Choose One - Required" with a No Rice / No Beans row, not our optional selectMany. Tacos have neither station. Salad and Nachos have beans but no rice. Our tacos format offers both as optional categories and our salad format offers beans — the salad is right, the tacos are wrong.

7. COLLAPSE CHIPS / SIDES / DESSERTS INTO ONE TRAILING 'ADD EXTRAS' STEP with the MAKE IT A MEAL action, which is how the builder presents them.

### Missing staples

- Pickled Jalapenos — a permanent, free row in FLAVORFUL TOPPINGS on every single build; the only spicy topping on the rail and we have no item for it at all
- Half Cilantro and Half Brown Rice — a named radio option in the rice step, not a special request
- Half Black and Half Pinto Beans — a named radio option in the beans step
- Vegetarian (No Protein) — an explicitly priced choice in the protein step ($10.49); our only meatless protein is Plant-Based Impossible, which was not offered at this location
- Crispy Corn Tortilla — the actual second taco shell on the board (we ship 'Crispy Taco Shell' and, wrongly, 'Crunchy Tortilla Shell' as taco options)
- Create Your Own Quesadilla — an entire build format we do not have
- Create Your Own Cheese-Crusted Quesadilla — a second, distinct quesadilla format with a baked-on cheese crust (a real, non-trivial macro difference from a plain quesadilla)
- Create Your Own 3-Cheese Nachos — an entire build format we do not have, and one where queso and chips are both required components
- Create Your Own Mini Bowl — the smaller entree size, permanently listed in the Bowls category
- Create Your Own Taco (single taco) — permanently listed alongside Create Your Own 3 Tacos; our format hardcodes quantityPerPick 3
- Kids Meals as a format — Quesadilla Kids Meal, 3-Cheese Nachos Kids Meal, Taco Kids Meal, each 'served with choice of a side and drink'. We have the kids-portion ingredients but no kids meal, so those kids rows just pollute the adult pickers
- QuesaBirria Burrito — permanent signature ($13.49)
- QuesaBirria Quesadilla — permanent signature ($13.49)
- Smoky Chicken Cheese-Crusted Quesadilla — permanent signature ($11.89)
- Steak Fajita Quesadilla — permanent signature ($12.99)
- Side of Cilantro Lime Rice ($2.39), Side of Brown Rice ($2.39), Side of Black Beans ($2.39) — standing a la carte sides; our only 'sides' item is 'Side of Black Beans with Cheese', which is not on the current board
- Side of Guacamole, Side of 3-Cheese Queso, Side of Queso Diablo, Side of Salsa — standing a la carte dips
- Hand-Crafted Guacamole & Chips, 3-Cheese Queso & Chips, Queso Diablo & Chips, Salsa & Chips — the four permanent chips-and-dip combos, which are the most-ordered items in the Chips, Dips & Sides category
- Make It a Meal / Burrito Meal Deal / the Signature Deals With A Drink category — the standard end-of-line combo upsell
- Cholula Hot & Sweet Chicken and Spicy Tequila Lime Steak as PROTEINS — we only have them baked into fixed signature entrees, but both are selectable proteins in every Create Your Own build

### Naming

- 'Grilled Adobo Chicken' -> the board and the app both say 'Flame-Grilled Adobo Chicken'
- 'Grilled Steak' -> 'Flame-Grilled Steak'
- 'Three Cheese Queso' -> '3-Cheese Queso' (numeral, hyphen). Qdoba uses the numeral everywhere, including in product names like '3-Cheese Nachos'
- 'Hand Crafted Guacamole' -> 'Hand-Crafted Guacamole' (hyphenated)
- 'Hand Smashed Guac (kids, 1 oz)' -> Qdoba has no product called Hand Smashed Guac; it is the same Hand-Crafted Guacamole at a kids portion
- 'Pickled Red Onion' -> 'Pickled Red Onions' (plural on the board)
- 'Tortilla Strips' -> 'Crispy Tortilla Strips'
- 'Cotija Cheese' -> 'Cotija (Crumbled White Cheese)' — the parenthetical is on the board because most customers do not know the word
- 'Pico de Gallo' -> 'Freshly Made Pico de Gallo (Mild)'
- 'Habanero Salsa' -> 'Fiery Habanero Salsa (Hot)'
- 'Citrus Vinaigrette' -> 'Citrus Lime Vinaigrette (Mild)' — we dropped 'Lime', which is the word people actually say
- EVERY salsa and sauce is labelled with a heat level on the board and that is how customers pick: Roasted Tomato Salsa (Mild), Pico de Gallo (Mild), Chile Corn Salsa (Mild), Citrus Lime Vinaigrette (Mild), Salsa Verde (Medium), Chile Crema (Medium), Picante Ranch Dressing (Medium), Salsa Roja (Hot), Fiery Habanero Salsa (Hot). None of our nine sauce items carry a heat label
- 'Double Chocolate Brownie' -> the ordering site sells it as 'Chocolate Brownie'
- 'Double Protein Bowl - Chicken' / '- Steak' -> the menu name is 'Double Protein Post-Workout Bowl'; the protein is chosen inside it, not baked into the title
- 'Fajita Vegan Bowl' -> the menu says 'Fajita Veggie Post-Workout Bowl'. 'Vegan' vs 'Veggie' is a meaningful mismatch and 'Post-Workout' is the part a regular would say
- 'Street Style Chicken Tacos (3, Flour)' -> the board says just 'Street Style Chicken Tacos'; our parenthetical spec is not something anyone says or sees
- 'Crispy Taco Shell' -> the taco builder calls it 'Crispy Corn Tortilla'
- 'Crunchy Tortilla Shell' -> the board renders it 'CRUNCHY Tortilla Shell' and, more importantly, it is a SALAD vessel ('Bowl or Crispy Tortilla Shell'), not a taco shell as our formats have it
- 'Flour Tortilla (5.5")' / '(10")' / '(12.5")' -> the customer is never shown a size; the burrito builder says only 'Warm Flour Tortilla'. Nobody orders a 12.5-inch tortilla out loud
- 'Romaine Lettuce (Salad Base)' -> not a menu name; the salad bed is implied by choosing the Salad format, and 'Romaine Lettuce' separately exists as a topping
- Our category name 'Queso & Guac' -> the board splits these into 'SIGNATURE QUESOS' and 'FLAVORFUL TOPPINGS'; no station is called Queso & Guac
- Our category names 'Veggies & Add-Ins', 'Cheese', 'Toppings', 'Dressings & Cremas' -> none of these appear on the board. There are only two topping-side stations: 'FLAVORFUL TOPPINGS' and 'SALSAS & SAUCES'
- Our category 'Signature Eats (Complete Entrees)' -> the ordering site never uses 'Signature Eats'. Named entrees are filed under their format category (Bowls, Burritos, Quesadillas & Nachos, Salads, Tacos)
- 'Side of Black Beans with Cheese' -> not on the current board; the side is 'Side of Black Beans'
- 'Plant-Based Impossible' -> not offered at the location I checked; the meatless option presented is 'Vegetarian (No Protein)'
- 'Keto Bowl - Chicken / Steak / Brisket Birria' -> these appear in the nutrition guide but not in the online ordering menu at all; a customer will not find them on the board
- We drop the registered marks Qdoba uses in-store: 'Cholula(R) Hot & Sweet Chicken'
- Chorizo, Scrambled Eggs, Bacon and Seasoned Potatoes are breakfast/select-location items and did not appear in any builder at this location — showing them in the main protein and veggie pickers will not match what most users see on the board

---

## Raising Cane's — SIGNIFICANTLY_WRONG

### How you actually order

Cane's is NOT a build-your-own line. There is no counter you walk and no person adding components in sequence. It is a five-item combo menu where you say a combo name and then answer at most two follow-up questions. The real sequence:

1. PICK A COMBO BY NAME (this is the whole order for most people). Cane's own menu section is titled "Chicken, Chicken, Chicken. Which Combo are you Pickin'?" The five, verbatim from Cane's feed with their exact composition:
   - The Box Combo — 4 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Texas Toast, Coleslaw, 22 oz drink. 1290-1720 cal. (#1 most-ordered)
   - The Caniac Combo — 6 Chicken Fingers, 2 Cane's Sauces, Crinkle-Cut Fries, Texas Toast & Coleslaw, 32 oz drink. 1840-2470 cal.
   - The 3 Finger Combo — 3 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Texas Toast, 22 oz drink. 1050-1480 cal. (no coleslaw)
   - The Sandwich Combo — 3 Chicken Fingers, Cane's Sauce & Lettuce on a Toasted Bun, Crinkle-Cut Fries, 22 oz drink. 1140-1570 cal. (no toast, no coleslaw)
   - The Kids' Combo — 2 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Kids drink. 760-990 cal.
   Finger counts independently confirmed by protein arithmetic against the PDF: 3 Finger 48g published vs 48g computed exact; Box 62 vs 62 exact; Sandwich 51 vs 52.

2. DRINK — the only REQUIRED question. Cane's POS gates the combo behind "Make 1 required selection," and that group is the drink list (Regular tier first, then Large at +$0.30/+$0.50). This is why crew describe reading orders back as "a box combo the way it comes with a dr.pepper."

3. "PREPARATION CHOICE" — the one substitution, optional, select up to 1, default "Regular." This is the single most important interaction at Cane's and it is a SWAP, not an addition. Cane's enumerates exactly nine legal pairs, each with its own calorie delta printed in the POS. You may drop one included side and take one other in its place, free of charge. You may NOT swap a side for more chicken ("Only sides for sides or sauce").

4. CONDIMENTS — optional, ketchup.

5. UPSELLS, in this order: "Recommended Beverages" (Fountain Drink / Freshly Squeezed Lemonade / Tea, up to 3), then "Recommended Sides And Apps" (Crinkle-Cut Fries / Chicken Finger / Coleslaw, up to 3).

6. SPECIAL INSTRUCTIONS — free text. This is where "extra crispy" and "BOB" actually live; they are not selectable options anywhere in the POS.

A real regular's full order, verbatim from a customer of 8 years, shows how compressed this is: "Caniac combo no coleslaw extra toast butter on both sides extra crispy everything with sprite." Another: "I want a Box Combo, make the fries extra crispy, one extra Cane's sauce, and I would like to substitute a piece of Texas toast for the coleslaw. BOB both pieces of toast. No drink!" Both are ONE combo name plus a substitution plus prep notes — never a walk down a line.

### Sizes

Cane's food has essentially NO size system, and this is the rare case where our flat model is right. Every food row in the first-party July 2025 PDF is a single fixed serving: Chicken Finger 1.9 oz, Crinkle-Cut Fries 5.1 oz, Texas Toast 1 slice, Coleslaw 3.1 oz, Cane's Sauce 1.5 oz, Sandwich 1 each. There are no small/medium/large fries, no sauce sizes, no toast sizes. The ONLY size axis in the entire document is drinks (Kid's 12 oz / Regular 22 oz / Large 32 oz / Jug 1 gal), and drinks are deliberately out of scope for our fast-food menus. So there is nothing among our six food items to collapse into a size picker.

What plays the role of 'size' at Cane's is FINGER COUNT, and it is expressed as combo names rather than a size chip: Kids' = 2, 3 Finger = 3, Box = 4, Caniac = 6, then Tailgates at 25 / 50 / 75 / 100. Since we model fingers as a single repeatable 130-cal unit, the count is representable — but only if the UI actually lets the user choose the count, which today it does not (see stationOrder).

ONE REAL PORTION GAP, and it resolves the open question in our own dataSource notes. Cane's POS prices the combo's sides at DIFFERENT portions than the a la carte items: 'No Fries (NF) (300 Cal)' and 'No Toast (NT) (140 Cal)' — versus our a la carte Crinkle-Cut Fries at 400 cal and Texas Toast at 150 cal. Our notes flagged 'a recurring -11 g carb / -4.5 g fat offset across three combos suggests a smaller combo fries or toast portion that Cane's does not publish separately.' That is exactly it, and Cane's does publish it, just inside the modifier group rather than the nutrition PDF: combo fries are 300 cal, not 400. Separately, 'Extra Fries (XF)' is only +180 cal, not a second full order — crew confirm it is roughly 1.5x ('it is only 2 oz more, not 4 oz'), and they correct customers who say 'double fries.' These are missing portion variants, not a mis-grouping, so no size group is needed — but the numbers should exist somewhere.


### House configurations

- **The Side Substitution ("Preparation Choice") — NSL / NT / NF paired with XT / XF / XSL / XS**. The defining Cane's convention and the one a nutrition PDF will never show you. Every combo ships with a fixed set of sides, and you are allowed exactly ONE free swap: drop one included side, take one other in its place. Cane's POS calls the group "Preparation Choice" (Optional, select up to 1) and enumerates nine legal pairs, each with its calorie delta printed right in the option label: No Toast (NT) -140 with Extra Fries (XF) +180, or Extra Slaw (XSL) +100, or Extra Sauce (XS) +190; No Fries (NF) -300 with Extra Toast (XT) +140, or Extra Slaw +100, or Extra Sauce +190; No Slaw (NSL) -100 with Extra Toast (XT) +140, or Extra Fries (XF) +180, or Extra Sauce (XS) +190. Swaps are free — a crew member states flatly "substitutions do not change the price." You cannot swap a side for more chicken: "Only sides for sides or sauce." Dropping the slaw for extra toast is far and away the dominant version; the regulars' shorthand is NSLXT, NSLXF, NTXSL, NSXFXS, and it is common enough that the subreddit's user flairs are literally these configurations ("No Slaw, Extra Toast", "No Slaw, Extra Fries", "No Slaw, Extra Sauce", "Double Toast").
  - maps to: `raising-canes.sides.coleslaw`, `raising-canes.sides.texas-toast`, `raising-canes.sides.crinkle-cut-fries`, `raising-canes.dips.canes-sauce`
  - **gap:** Any combo item at all to subtract a side FROM — we have zero combos, so there is nothing to remove and this entire convention is currently inexpressible
  - **gap:** A removal/negative mechanic — every one of our four stations is additive only
  - **gap:** Combo-portion Crinkle-Cut Fries at 300 cal (our only fries item is the 400-cal a la carte portion)
  - **gap:** Combo-portion Texas Toast at 140 cal (ours is the 150-cal a la carte slice)
  - **gap:** "Extra Fries (XF)" as a +180 cal increment — roughly 1.5x, explicitly not a second 400-cal order
  - **gap:** "Extra Toast (XT)" at +140 cal and "Extra Slaw (XSL)" at +100 cal as swap-in portions
- **BOB — Butter on Both Sides**. Texas Toast griddled with butter on both faces instead of the standard one. Pure fat added to a 140-150 cal slice; Cane's publishes no macro for it. Requested by name as an acronym, and it is not a selectable POS option — it goes in special instructions, which is why crew find it irritating during a rush. Frequently combined with an extra toast, so a regular may be taking two slices both double-buttered.
  - maps to: `raising-canes.sides.texas-toast`
  - **gap:** The extra butter itself — we have no butter/spread item and no 'BOB' variant of Texas Toast, so the added fat is silently uncounted
- **Extra Cane's Sauce**. The single most common add at Cane's, and it is a genuinely large macro event — 190 cal and 18 g fat per 1.5 oz cup, which is more fat than a whole chicken finger. There are two distinct routes and they cost different things: take it FREE as a Preparation Choice swap (give up the slaw, toast or fries for Extra Sauce +190 cal), or buy it as an Extra for $0.39. A crew member points out the price asymmetry regulars exploit: "no coleslaw extra toast with an extra sauce is cheaper than no coleslaw extra sauce with an extra toast." Note the Caniac already ships with TWO sauces as standard.
  - maps to: `raising-canes.dips.canes-sauce`
  - **gap:** Nothing — our Cane's Sauce item at 190 cal / 18 g fat matches Cane's "Extra Sauce (XS) (190 Cal)" exactly. But our dips category is capped at selectUpTo 3, which cannot represent a Caniac's 2 included sauces plus 2 extras, and there is no way to mark sauce as INCLUDED rather than chosen.
- **Honey Mustard instead of Cane's Sauce**. A straight sauce substitution rather than an addition — you decline the included Cane's Sauce and take Honey Mustard in its place. Meaningful macro swing in both directions: 190 -> 140 cal, 18 g -> 8 g fat, but 6 g -> 16 g carbs and 5 g -> 13 g sugar. Cane's makes only two sauces in-house (Cane's Sauce and Honey Mustard); everything else is a packet.
  - maps to: `raising-canes.dips.honey-mustard`, `raising-canes.dips.canes-sauce`
  - **gap:** No swap/replace mechanic — our dips station is additive, so choosing Honey Mustard adds 140 cal on top of a Cane's Sauce that the combo already includes rather than replacing it
- **NKD BRD — the Naked Bird (unbreaded chicken finger)**. Chicken fingers cooked without breading. Roughly halves the finger: crew put it at "70ish for a naked" against the published 130 cal for a standard finger, and it strips most of the 5 g carbs. The health-and-gluten-avoidance order. Important caveat that crew volunteer unprompted: it is fried in the SAME oil as breaded fingers, so it is lower-gluten, not gluten-free.
  - maps to: `raising-canes.entrees.chicken-finger`
  - **gap:** A naked/unbreaded chicken finger item (~70 cal) — we have no variant and no way to express it
  - **gap:** Availability is location-dependent, so it may not belong in a national menu at all
- **Box Combo — The Posty Way**. A first-party NAMED configuration from the Post Malone collaboration that Cane's publishes its own full nutrition row for — the rare case where the house config IS in the PDF. Against a standard Box Combo (1290 cal / 72 g fat / 98 g carb / 62 g protein) it lands at 1740 / 89 / 173 / 66: about +450 cal, +17 g fat, +75 g carb and +54 g sugar.
  - maps to: `raising-canes.dips.canes-sauce`
  - **gap:** The base Box Combo itself — we have no combo item
  - **gap:** The sweet component driving +69 g carb and +54 g sugar. I could NOT confirm what it is. The +17 g fat matches one extra Cane's Sauce (18 g) almost exactly, and the residual +260 cal / +69 carb is close to a Regular Lemonade (290 cal / 76 carb) — but that is my arithmetic inference, not a sourced component list, and if it is a lemonade it falls under our drinks exclusion anyway.

### Station order

NO — our station order is not just mis-sequenced, it is the wrong shape entirely, because Cane's has no line to sequence.

OURS: Entrées -> Sides -> Dipping Sauces -> Condiment Packets. That is a Chipotle metaphor: four additive stations where the user accumulates components.

CANE'S ACTUAL MENU SECTIONS, in order, from their own feed: Combos -> Extras -> Drinks -> Tailgates -> Sandwich. And within a combo, the option groups fire in this order: [Drink] (REQUIRED) -> Preparation Choice (the one substitution) -> Condiments -> Recommended Beverages -> Recommended Sides And Apps -> Special Instructions.

WHAT SHOULD MOVE:

1. A COMBOS STATION MUST COME FIRST AND BE THE PRIMARY PATH. Cane's leads with "Chicken, Chicken, Chicken. Which Combo are you Pickin'?" The five combos are the menu; the a la carte items are the "Extras" section that exists to top them up. Today we have no combos at all, so the #1 most-ordered item in the restaurant — The Box Combo — cannot be expressed as a single choice. A user must instead hand-assemble 4 fingers + fries + toast + coleslaw + sauce and, per our own dataSource notes, overshoot the published total by 5-8%.

2. SIDES SHOULD NOT BE AN ADDITIVE STATION. In the real flow every combo ARRIVES with its sides and the only decision is which one to REMOVE and what to take instead. Our Sides station asks "what do you want to add"; the counter asks, in effect, "keeping the slaw?" These are opposite questions. Without a removal mechanic the single most common Cane's order — Box Combo, no slaw, extra toast — is unrepresentable.

3. DIPPING SAUCES SHOULD NOT BE A TERMINAL STATION. Cane's Sauce is INCLUDED (1 in Box/3 Finger/Kids, 2 in Caniac), not chosen at the end. It needs to be pre-populated by the combo, with the user choosing to add more or swap to Honey Mustard.

4. CONDIMENT PACKETS IS CORRECTLY LAST. Louisiana hot sauce and mayo genuinely are the ask-at-the-window caddy items. Keep it there.

5. DRINK IS THE ONLY REQUIRED QUESTION IN THE REAL FLOW and we omit it by policy. That is the right call for macros, but it means our flow has no required step at all, which is worth knowing when designing the combo prompt.

BUG WORTH FIXING IN /Volumes/dayossd/Projects/Loadout/Loadout/Loadout/Resources/Formats/raising-canes.formats.json: the "fingers" format asks "How many fingers?" but the prompt is `"choose": "one"` over a `subsetItemIds` array containing exactly ONE id (raising-canes.entrees.chicken-finger) with a hardcoded `"quantityPerPick": 3`. The user is asked a question they cannot answer — there is only one option and it always yields exactly 3 fingers. Cane's real counts are 2 / 3 / 4 / 6 (plus 25/50/75/100 for Tailgates). This should be a count picker, not a single-item single-choice.

### Missing staples

- The Box Combo — 4 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Texas Toast, Coleslaw, 22 oz drink. Cane's #1 most-ordered item and the single biggest gap in our menu.
- The Caniac Combo — 6 Chicken Fingers, 2 Cane's Sauces, Crinkle-Cut Fries, Texas Toast & Coleslaw, 32 oz drink. The big-appetite default; published 1840 cal food-only.
- The 3 Finger Combo — 3 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Texas Toast, 22 oz drink. No coleslaw. The entry-level combo.
- The Sandwich Combo — Sandwich plus Crinkle-Cut Fries and a 22 oz drink. No toast, no coleslaw.
- The Kids' Combo — 2 Chicken Fingers, 1 Cane's Sauce, Crinkle-Cut Fries, Kids drink.
- Tailgates — permanent catering line, not an LTO: 25 Finger ($44.99, 8 Cane's Sauces included), 50 Finger ($81.99, 16 sauces), 75 Finger ($122.99, 25 sauces), and a 100 Finger tier crew reference. Its own section on the menu board.
- Combo-portion Crinkle-Cut Fries at 300 cal — distinct from our 400-cal a la carte fries. This is the missing number that explains the reconciliation gap already flagged in our own dataSource notes.
- Combo-portion Texas Toast at 140 cal — distinct from our 150-cal a la carte slice.
- "Extra Fries (XF)" as a +180 cal upsize increment — the 1.5x bump, explicitly NOT a second full 400-cal order. Crew actively correct customers who call it 'double fries'.
- Naked / unbreaded Chicken Finger, roughly 70 cal versus 130 — real and regularly ordered, but location-dependent and absent from the national nutrition PDF, so treat as optional.
- Box Combo - The Posty Way — a first-party named combo with its own published nutrition row in the July 2025 PDF (1740 cal / 89 f / 173 c / 66 p).

### Naming

- "Chicken Sandwich" (raising-canes.entrees.chicken-sandwich) — the menu board just says "Sandwich", and the combo is "The Sandwich Combo". Nobody at Cane's says 'chicken sandwich'; in a chicken-only restaurant the word is redundant. Also worth carrying its real description, which we omit entirely: it is not a chicken patty, it is "3 Chicken Fingers, Cane's Sauce and lettuce on a toasted bun" — that changes how a user reasons about it. And the 780 vs 830 cal conflict our notes flag is still live: Cane's menu listing says 780 cal, the nutrition PDF says 830.
- Combo names all carry a definite article on the board — "The Box Combo", "The Caniac Combo", "The 3 Finger Combo", "The Sandwich Combo", "The Kids' Combo". If we add combos, match that.
- "Coleslaw" (raising-canes.sides.coleslaw) — spoken and POS-coded as "slaw" everywhere: NSL (No Slaw), XSL (Extra Slaw). Every regular and every crew member says 'slaw'. Needs at least a search alias.
- "Texas Toast" (raising-canes.sides.texas-toast) — correct on the board, but spoken as just "toast" and coded NT / XT. Same alias issue.
- "Crinkle-Cut Fries" (raising-canes.sides.crinkle-cut-fries) — correct on the board, spoken as "fries", coded NF / XF.
- "Chicken Finger" (raising-canes.entrees.chicken-finger) — the board and Extras list say "Chicken Finger", but crew and a large share of customers say "tender" ("Ya'll getting small tenders?", "Asked for just one extra tender in a box combo"). Some say "strip". Worth aliasing tender/strip.
- "Louisiana Hot Sauce" (raising-canes.sauces.louisiana-hot-sauce) — customers order it as just "Louisiana" (it is the brand name), and crew in Louisiana itself say plain "hot sauce" because the store carries only one kind. A crew member: "Never heard anyone refer to hot sauce as 'Louisiana' before this thread." Both forms should resolve.
- "Kraft Mayonnaise" (raising-canes.sauces.kraft-mayonnaise) — nobody says the brand. It is "mayo", and it is genuinely rare (a crew member logged 2 requests in 600 hours).
- "Dipping Sauces" as a category name — Cane's calls this section "Extras", and framing Cane's Sauce as one option among three misrepresents it: it is the default included sauce, not a pick. Honey Mustard and Ketchup are the alternates to it.
- "Condiment Packets" — accurate as a concept but not language anyone uses; in store these are just the packets you ask for at the window.
- Missing the shorthand vocabulary entirely. Regulars and crew transact in acronyms — NSL, NT, NF, XT, XF, XSL, XS, BOB, NKD BRD, and compounds like NSLXT and NTXSL. Cane's own POS prints them in the option labels ("No Slaw (NSL) (100 Cal) - Extra Toast (XT) (140 Cal)"). If search or labels recognized these, the app would speak the same language as the menu board.

---

## Starbucks — SIGNIFICANTLY_WRONG

### How you actually order

Starbucks is NOT a walk-the-line restaurant. There is no station sequence and nobody hands you a bowl. The flow is one drink, then a deep vertical dive into that one drink's options, then a single food upsell. Concretely, in the app and at the register:

STEP 1 — Pick ONE beverage by browsing a category tree. Real top-level order: The Latest/Trending → Protein → Coffee & Espresso (Hot, then Cold) → Tea (Chai → Matcha → Hot Tea → Iced Tea) → Refreshment (Refreshers → Energy Refreshers) → Frappuccino Blended Beverage (Coffee Frapp → Crème Frapp) → Other Sips (Hot Chocolate / Lemonade / Milk & Steamers, then Bottled Beverages) → Food → At Home Coffee.

STEP 2 — SIZE, chosen on the product page, not before it. The size chips sit at the top of the drink detail screen. Grande is preselected (`default: true` in the payload).

STEP 3 — CUSTOMIZE. This is the actual Starbucks ordering experience and it is the entire thing our app is missing. The product page opens an accordion of option groups, which for a Caffè Latte are literally: Espresso & Shot Options (roast: Signature/Blonde/Decaf/½-⅓-⅔ decaf; Ristretto or Long Shot; shot count) → Milk (Milk Foam extra/regular/light/none; 12 Milk Options; Milk Temperature warm/hot/extra hot) → Flavors (4 Sauces, 4 Powders, 14 Syrups, each with a per-size pump count) → Sweeteners (2 liquid, 5 packets) → Toppings (Cinnamon powder, 5 topping options, 2 Drizzles, Whipped Cream) → Cold Foams (16 Cold Foam, 15 Nondairy Cold Foam, 16 Protein Cold Foam "+15g") → Add-ins (Ice level, Line the Cup, Flavored Pearls) → Preparation ("No water — prepared with <milk>", 11 variants) → Cup Options. Cold drinks swap Milk Temperature for Ice level; Frappuccinos add a Blended Options group (Frappuccino Roast, Frappuccino Chips, Double Blended, Affogato-Style Shots).

STEP 4 — Verbally this collapses to one compressed sentence said in a fixed grammar: size → temperature/iced → milk → shots/decaf → syrup count → drink name → toppings. "Grande iced oat milk latte, two pumps vanilla, light ice, no whip." A barista writes it on the cup in that order.

STEP 5 — "Anything else?" — the food upsell. Food is a flat pick-N list off the pastry case, not a station walk. Food items then get their OWN small option step: bagels ask Warmed/Not Warmed + Butter/Cream Cheese, oatmeal asks which topping packets, sandwiches and wraps offer Avocado Spread, egg bites offer Sriracha.

Our formats file gets steps 1 and 5 structurally right (selectOne drink, then optional food categories). Steps 2 and 3 — the size picker and the entire customization accordion — do not exist in our model at all.

### Sizes

Named tiers, and the ladder is different for every beverage family — this is the thing generic size models get wrong at Starbucks. HOT: Short 8 / Tall 12 / Grande 16 / Venti 20. COLD: Tall 12 / Grande 16 / Venti 24 / Trenta 30 — note Venti means 24 oz iced but 20 oz hot, and Trenta exists ONLY for cold brew, iced coffee, iced tea, refreshers and lemonade (never a milk drink). FRAPPUCCINO: Tall 12 / Grande 16 / Venti 24, no Short, no Trenta. ESPRESSO SHOTS use a different vocabulary entirely: Solo / Doppio / Triple / Quad. KIDS (8 oz hot, 12 oz cold) exists only for Hot Chocolate, Steamed Milk and Lemonade. Special cases: Cortado is Short-only; Nitro Cold Brew is Tall and Grande only (nitrogen doesn't hold in bigger cups); Flat White and Iced Flat White default to TALL, not Grande, because of the ristretto shot ratio; Espresso and Iced Espresso default to Doppio. DEFAULT IF YOU SAY NOTHING: Grande — Starbucks flags it `default: true` on every product that has it. Critically, size is picked ON the product page as a chip row above the customization accordion, and the pump count and shot count of the whole drink scale off it (hot syrup: Short 2 / Tall 3 / Grande 4 / Venti 5; iced: Tall 3 / Grande 4 / Venti 6; Frappuccino: Tall 2 / Grande 3 / Venti 4; latte shots: Short 1 / Tall 1 / Grande 2 / Venti 2 hot, 3 iced).

- **Pike Place Roast (Medium)** — default Grande: Short (`starbucks.hot-coffee.pike-place-roast-medium-short`), Tall (`starbucks.hot-coffee.pike-place-roast-medium-tall`), Grande (`starbucks.hot-coffee.pike-place-roast-medium`), Venti (`starbucks.hot-coffee.pike-place-roast-medium-venti`)
- **Sunsera Blonde Roast** — default Grande: Short (`starbucks.hot-coffee.sunsera-blonde-roast-short`), Tall (`starbucks.hot-coffee.sunsera-blonde-roast-tall`), Grande (`starbucks.hot-coffee.sunsera-blonde-roast`), Venti (`starbucks.hot-coffee.sunsera-blonde-roast-venti`)
- **Caffè Verona Dark Roast** — default Grande: Short (`starbucks.hot-coffee.caffe-verona-dark-roast-short`), Tall (`starbucks.hot-coffee.caffe-verona-dark-roast-tall`), Grande (`starbucks.hot-coffee.caffe-verona-dark-roast`), Venti (`starbucks.hot-coffee.caffe-verona-dark-roast-venti`)
- **Decaf Pike Place Roast** — default Grande: Short (`starbucks.hot-coffee.decaf-pike-place-roast-short`), Tall (`starbucks.hot-coffee.decaf-pike-place-roast-tall`), Grande (`starbucks.hot-coffee.decaf-pike-place-roast`), Venti (`starbucks.hot-coffee.decaf-pike-place-roast-venti`)
- **Caffè Misto** — default Grande: Short (`starbucks.hot-coffee.caffe-misto-short`), Tall (`starbucks.hot-coffee.caffe-misto-tall`), Grande (`starbucks.hot-coffee.caffe-misto`), Venti (`starbucks.hot-coffee.caffe-misto-venti`)
- **Caffè Americano** — default Grande: Short (`starbucks.hot-coffee.caffe-americano-short`), Tall (`starbucks.hot-coffee.caffe-americano-tall`), Grande (`starbucks.hot-coffee.caffe-americano`), Venti (`starbucks.hot-coffee.caffe-americano-venti`)
- **Caffè Latte** — default Grande: Short (`starbucks.hot-coffee.caffe-latte-short`), Tall (`starbucks.hot-coffee.caffe-latte-tall`), Grande (`starbucks.hot-coffee.caffe-latte`), Venti (`starbucks.hot-coffee.caffe-latte-venti`)
- **Cappuccino** — default Grande: Short (`starbucks.hot-coffee.cappuccino-short`), Tall (`starbucks.hot-coffee.cappuccino-tall`), Grande (`starbucks.hot-coffee.cappuccino`), Venti (`starbucks.hot-coffee.cappuccino-venti`)
- **Flat White** — default Tall: Short (`starbucks.hot-coffee.flat-white-short`), Tall (`starbucks.hot-coffee.flat-white-tall`), Grande (`starbucks.hot-coffee.flat-white`), Venti (`starbucks.hot-coffee.flat-white-venti`)
- **Caffè Mocha** — default Grande: Short (`starbucks.hot-coffee.caffe-mocha-short`), Tall (`starbucks.hot-coffee.caffe-mocha-tall`), Grande (`starbucks.hot-coffee.caffe-mocha`), Venti (`starbucks.hot-coffee.caffe-mocha-venti`)
- **White Chocolate Mocha** — default Grande: Short (`starbucks.hot-coffee.white-chocolate-mocha-short`), Tall (`starbucks.hot-coffee.white-chocolate-mocha-tall`), Grande (`starbucks.hot-coffee.white-chocolate-mocha`), Venti (`starbucks.hot-coffee.white-chocolate-mocha-venti`)
- **Caramel Macchiato** — default Grande: Short (`starbucks.hot-coffee.caramel-macchiato-short`), Tall (`starbucks.hot-coffee.caramel-macchiato-tall`), Grande (`starbucks.hot-coffee.caramel-macchiato`), Venti (`starbucks.hot-coffee.caramel-macchiato-venti`)
- **Cinnamon Dolce Latte** — default Grande: Short (`starbucks.hot-coffee.cinnamon-dolce-latte-short`), Tall (`starbucks.hot-coffee.cinnamon-dolce-latte-tall`), Grande (`starbucks.hot-coffee.cinnamon-dolce-latte`), Venti (`starbucks.hot-coffee.cinnamon-dolce-latte-venti`)
- **Blonde Vanilla Latte** — default Grande: Short (`starbucks.hot-coffee.blonde-vanilla-latte-short`), Tall (`starbucks.hot-coffee.blonde-vanilla-latte-tall`), Grande (`starbucks.hot-coffee.blonde-vanilla-latte`), Venti (`starbucks.hot-coffee.blonde-vanilla-latte-venti`)
- **Caramel Protein Latte** — default Grande: Short (`starbucks.hot-coffee.caramel-protein-latte-short`), Tall (`starbucks.hot-coffee.caramel-protein-latte-tall`), Grande (`starbucks.hot-coffee.caramel-protein-latte`), Venti (`starbucks.hot-coffee.caramel-protein-latte-venti`)
- **Vanilla Protein Latte** — default Grande: Short (`starbucks.hot-coffee.vanilla-protein-latte-short`), Tall (`starbucks.hot-coffee.vanilla-protein-latte-tall`), Grande (`starbucks.hot-coffee.vanilla-protein-latte`), Venti (`starbucks.hot-coffee.vanilla-protein-latte-venti`)
- **Sugar-Free Vanilla Protein Latte** — default Grande: Short (`starbucks.hot-coffee.sugar-free-vanilla-protein-latte-short`), Tall (`starbucks.hot-coffee.sugar-free-vanilla-protein-latte-tall`), Grande (`starbucks.hot-coffee.sugar-free-vanilla-protein-latte`), Venti (`starbucks.hot-coffee.sugar-free-vanilla-protein-latte-venti`)
- **Sugar-Free Caramel Protein Latte** — default Grande: Short (`starbucks.hot-coffee.sugar-free-caramel-protein-latte-short`), Tall (`starbucks.hot-coffee.sugar-free-caramel-protein-latte-tall`), Grande (`starbucks.hot-coffee.sugar-free-caramel-protein-latte`), Venti (`starbucks.hot-coffee.sugar-free-caramel-protein-latte-venti`)
- **Hot Chocolate** — default Grande: Kids (`starbucks.hot-coffee.hot-chocolate-kids`), Short (`starbucks.hot-coffee.hot-chocolate-short`), Tall (`starbucks.hot-coffee.hot-chocolate-tall`), Grande (`starbucks.hot-coffee.hot-chocolate`), Venti (`starbucks.hot-coffee.hot-chocolate-venti`)
- **Steamed Milk** — default Grande: Kids (`starbucks.hot-coffee.steamed-milk-kids`), Short (`starbucks.hot-coffee.steamed-milk-short`), Tall (`starbucks.hot-coffee.steamed-milk-tall`), Grande (`starbucks.hot-coffee.steamed-milk`), Venti (`starbucks.hot-coffee.steamed-milk-venti`)
- **Espresso** — default Doppio: Solo (`starbucks.hot-coffee.espresso-solo`), Doppio (`starbucks.hot-coffee.espresso-doppio`), Triple (`starbucks.hot-coffee.espresso-triple`), Quad (`starbucks.hot-coffee.espresso-quad`)
- **Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.cold-brew-tall`), Grande (`starbucks.cold-coffee.cold-brew`), Venti (`starbucks.cold-coffee.cold-brew-venti`), Trenta (`starbucks.cold-coffee.cold-brew-trenta`)
- **Nitro Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.nitro-cold-brew-tall`), Grande (`starbucks.cold-coffee.nitro-cold-brew`)
- **Vanilla Sweet Cream Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.vanilla-sweet-cream-cold-brew-tall`), Grande (`starbucks.cold-coffee.vanilla-sweet-cream-cold-brew`), Venti (`starbucks.cold-coffee.vanilla-sweet-cream-cold-brew-venti`), Trenta (`starbucks.cold-coffee.vanilla-sweet-cream-cold-brew-trenta`)
- **Vanilla Sweet Cream Nitro Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.vanilla-sweet-cream-nitro-cold-brew-tall`), Grande (`starbucks.cold-coffee.vanilla-sweet-cream-nitro-cold-brew`)
- **Salted Caramel Cream Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.salted-caramel-cream-cold-brew-tall`), Grande (`starbucks.cold-coffee.salted-caramel-cream-cold-brew`), Venti (`starbucks.cold-coffee.salted-caramel-cream-cold-brew-venti`), Trenta (`starbucks.cold-coffee.salted-caramel-cream-cold-brew-trenta`)
- **Chocolate Cream Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.chocolate-cream-cold-brew-tall`), Grande (`starbucks.cold-coffee.chocolate-cream-cold-brew`), Venti (`starbucks.cold-coffee.chocolate-cream-cold-brew-venti`), Trenta (`starbucks.cold-coffee.chocolate-cream-cold-brew-trenta`)
- **Nondairy Vanilla Sweet Cream Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.nondairy-vanilla-sweet-cream-cold-brew-tall`), Grande (`starbucks.cold-coffee.nondairy-vanilla-sweet-cream-cold-brew`), Venti (`starbucks.cold-coffee.nondairy-vanilla-sweet-cream-cold-brew-venti`), Trenta (`starbucks.cold-coffee.nondairy-vanilla-sweet-cream-cold-brew-trenta`)
- **Iced Coffee** — default Grande: Tall (`starbucks.cold-coffee.iced-coffee-tall`), Grande (`starbucks.cold-coffee.iced-coffee`), Venti (`starbucks.cold-coffee.iced-coffee-venti`), Trenta (`starbucks.cold-coffee.iced-coffee-trenta`)
- **Iced Caffè Americano** — default Grande: Tall (`starbucks.cold-coffee.iced-caffe-americano-tall`), Grande (`starbucks.cold-coffee.iced-caffe-americano`), Venti (`starbucks.cold-coffee.iced-caffe-americano-venti`)
- **Iced Caffè Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-caffe-latte-tall`), Grande (`starbucks.cold-coffee.iced-caffe-latte`), Venti (`starbucks.cold-coffee.iced-caffe-latte-venti`)
- **Iced Flat White** — default Tall: Tall (`starbucks.cold-coffee.iced-flat-white-tall`), Grande (`starbucks.cold-coffee.iced-flat-white`), Venti (`starbucks.cold-coffee.iced-flat-white-venti`)
- **Iced Caffè Mocha** — default Grande: Tall (`starbucks.cold-coffee.iced-caffe-mocha-tall`), Grande (`starbucks.cold-coffee.iced-caffe-mocha`), Venti (`starbucks.cold-coffee.iced-caffe-mocha-venti`)
- **Iced White Chocolate Mocha** — default Grande: Tall (`starbucks.cold-coffee.iced-white-chocolate-mocha-tall`), Grande (`starbucks.cold-coffee.iced-white-chocolate-mocha`), Venti (`starbucks.cold-coffee.iced-white-chocolate-mocha-venti`)
- **Iced Caramel Macchiato** — default Grande: Tall (`starbucks.cold-coffee.iced-caramel-macchiato-tall`), Grande (`starbucks.cold-coffee.iced-caramel-macchiato`), Venti (`starbucks.cold-coffee.iced-caramel-macchiato-venti`)
- **Iced Shaken Espresso** — default Grande: Tall (`starbucks.cold-coffee.iced-shaken-espresso-tall`), Grande (`starbucks.cold-coffee.iced-shaken-espresso`), Venti (`starbucks.cold-coffee.iced-shaken-espresso-venti`)
- **Iced Brown Sugar Oatmilk Shaken Espresso** — default Grande: Tall (`starbucks.cold-coffee.iced-brown-sugar-oatmilk-shaken-espresso-tall`), Grande (`starbucks.cold-coffee.iced-brown-sugar-oatmilk-shaken-espresso`), Venti (`starbucks.cold-coffee.iced-brown-sugar-oatmilk-shaken-espresso-venti`)
- **Iced Blonde Vanilla Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-blonde-vanilla-latte-tall`), Grande (`starbucks.cold-coffee.iced-blonde-vanilla-latte`), Venti (`starbucks.cold-coffee.iced-blonde-vanilla-latte-venti`)
- **Iced Cinnamon Dolce Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-cinnamon-dolce-latte-tall`), Grande (`starbucks.cold-coffee.iced-cinnamon-dolce-latte`), Venti (`starbucks.cold-coffee.iced-cinnamon-dolce-latte-venti`)
- **Iced Caramel Protein Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-caramel-protein-latte-tall`), Grande (`starbucks.cold-coffee.iced-caramel-protein-latte`), Venti (`starbucks.cold-coffee.iced-caramel-protein-latte-venti`)
- **Iced Vanilla Protein Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-vanilla-protein-latte-tall`), Grande (`starbucks.cold-coffee.iced-vanilla-protein-latte`), Venti (`starbucks.cold-coffee.iced-vanilla-protein-latte-venti`)
- **Iced Sugar-Free Vanilla Protein Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-sugar-free-vanilla-protein-latte-tall`), Grande (`starbucks.cold-coffee.iced-sugar-free-vanilla-protein-latte`), Venti (`starbucks.cold-coffee.iced-sugar-free-vanilla-protein-latte-venti`)
- **Iced Sugar-Free Caramel Protein Latte** — default Grande: Tall (`starbucks.cold-coffee.iced-sugar-free-caramel-protein-latte-tall`), Grande (`starbucks.cold-coffee.iced-sugar-free-caramel-protein-latte`), Venti (`starbucks.cold-coffee.iced-sugar-free-caramel-protein-latte-venti`)
- **Vanilla Protein Cream Cold Brew** — default Grande: Tall (`starbucks.cold-coffee.vanilla-protein-cream-cold-brew-tall`), Grande (`starbucks.cold-coffee.vanilla-protein-cream-cold-brew`), Venti (`starbucks.cold-coffee.vanilla-protein-cream-cold-brew-venti`), Trenta (`starbucks.cold-coffee.vanilla-protein-cream-cold-brew-trenta`)
- **Cold Milk** — default Grande: Tall (`starbucks.cold-coffee.cold-milk-tall`), Grande (`starbucks.cold-coffee.cold-milk`), Venti (`starbucks.cold-coffee.cold-milk-venti`)
- **Iced Espresso** — default Doppio: Solo (`starbucks.cold-coffee.iced-espresso-solo`), Doppio (`starbucks.cold-coffee.iced-espresso-doppio`), Triple (`starbucks.cold-coffee.iced-espresso-triple`), Quad (`starbucks.cold-coffee.iced-espresso-quad`)
- **Royal English Breakfast Tea** — default Grande: Short (`starbucks.tea.royal-english-breakfast-tea-short`), Tall (`starbucks.tea.royal-english-breakfast-tea-tall`), Grande (`starbucks.tea.royal-english-breakfast-tea`), Venti (`starbucks.tea.royal-english-breakfast-tea-venti`)
- **Earl Grey Tea** — default Grande: Short (`starbucks.tea.earl-grey-tea-short`), Tall (`starbucks.tea.earl-grey-tea-tall`), Grande (`starbucks.tea.earl-grey-tea`), Venti (`starbucks.tea.earl-grey-tea-venti`)
- **Mint Majesty Tea** — default Grande: Short (`starbucks.tea.mint-majesty-tea-short`), Tall (`starbucks.tea.mint-majesty-tea-tall`), Grande (`starbucks.tea.mint-majesty-tea`), Venti (`starbucks.tea.mint-majesty-tea-venti`)
- **Emperor's Clouds & Mist Tea** — default Grande: Short (`starbucks.tea.emperor-s-clouds-and-mist-tea-short`), Tall (`starbucks.tea.emperor-s-clouds-and-mist-tea-tall`), Grande (`starbucks.tea.emperor-s-clouds-and-mist-tea`), Venti (`starbucks.tea.emperor-s-clouds-and-mist-tea-venti`)
- **Chamomile Mint Blossom Tea** — default Grande: Short (`starbucks.tea.chamomile-mint-blossom-tea-short`), Tall (`starbucks.tea.chamomile-mint-blossom-tea-tall`), Grande (`starbucks.tea.chamomile-mint-blossom-tea`), Venti (`starbucks.tea.chamomile-mint-blossom-tea-venti`)
- **Honey Citrus Mint Tea** — default Grande: Short (`starbucks.tea.honey-citrus-mint-tea-short`), Tall (`starbucks.tea.honey-citrus-mint-tea-tall`), Grande (`starbucks.tea.honey-citrus-mint-tea`), Venti (`starbucks.tea.honey-citrus-mint-tea-venti`)
- **London Fog Latte** — default Grande: Short (`starbucks.tea.london-fog-latte-short`), Tall (`starbucks.tea.london-fog-latte-tall`), Grande (`starbucks.tea.london-fog-latte`), Venti (`starbucks.tea.london-fog-latte-venti`)
- **Chai Latte** — default Grande: Short (`starbucks.tea.chai-latte-short`), Tall (`starbucks.tea.chai-latte-tall`), Grande (`starbucks.tea.chai-latte`), Venti (`starbucks.tea.chai-latte-venti`)
- **Iced Chai Latte** — default Grande: Tall (`starbucks.tea.iced-chai-latte-tall`), Grande (`starbucks.tea.iced-chai-latte`), Venti (`starbucks.tea.iced-chai-latte-venti`)
- **Matcha Latte** — default Grande: Short (`starbucks.tea.matcha-latte-short`), Tall (`starbucks.tea.matcha-latte-tall`), Grande (`starbucks.tea.matcha-latte`), Venti (`starbucks.tea.matcha-latte-venti`)
- **Iced Matcha Latte** — default Grande: Tall (`starbucks.tea.iced-matcha-latte-tall`), Grande (`starbucks.tea.iced-matcha-latte`), Venti (`starbucks.tea.iced-matcha-latte-venti`)
- **Protein Matcha** — default Grande: Short (`starbucks.tea.protein-matcha-short`), Tall (`starbucks.tea.protein-matcha-tall`), Grande (`starbucks.tea.protein-matcha`), Venti (`starbucks.tea.protein-matcha-venti`)
- **Iced Protein Matcha** — default Grande: Tall (`starbucks.tea.iced-protein-matcha-tall`), Grande (`starbucks.tea.iced-protein-matcha`), Venti (`starbucks.tea.iced-protein-matcha-venti`)
- **Caramel Protein Matcha** — default Grande: Short (`starbucks.tea.caramel-protein-matcha-short`), Tall (`starbucks.tea.caramel-protein-matcha-tall`), Grande (`starbucks.tea.caramel-protein-matcha`), Venti (`starbucks.tea.caramel-protein-matcha-venti`)
- **Iced Caramel Protein Matcha** — default Grande: Tall (`starbucks.tea.iced-caramel-protein-matcha-tall`), Grande (`starbucks.tea.iced-caramel-protein-matcha`), Venti (`starbucks.tea.iced-caramel-protein-matcha-venti`)
- **Sugar-Free Vanilla Protein Matcha** — default Grande: Short (`starbucks.tea.sugar-free-vanilla-protein-matcha-short`), Tall (`starbucks.tea.sugar-free-vanilla-protein-matcha-tall`), Grande (`starbucks.tea.sugar-free-vanilla-protein-matcha`), Venti (`starbucks.tea.sugar-free-vanilla-protein-matcha-venti`)
- **Iced Sugar-Free Vanilla Protein Matcha** — default Grande: Tall (`starbucks.tea.iced-sugar-free-vanilla-protein-matcha-tall`), Grande (`starbucks.tea.iced-sugar-free-vanilla-protein-matcha`), Venti (`starbucks.tea.iced-sugar-free-vanilla-protein-matcha-venti`)
- **Sugar-Free Caramel Protein Matcha** — default Grande: Short (`starbucks.tea.sugar-free-caramel-protein-matcha-short`), Tall (`starbucks.tea.sugar-free-caramel-protein-matcha-tall`), Grande (`starbucks.tea.sugar-free-caramel-protein-matcha`), Venti (`starbucks.tea.sugar-free-caramel-protein-matcha-venti`)
- **Iced Sugar-Free Caramel Protein Matcha** — default Grande: Tall (`starbucks.tea.iced-sugar-free-caramel-protein-matcha-tall`), Grande (`starbucks.tea.iced-sugar-free-caramel-protein-matcha`), Venti (`starbucks.tea.iced-sugar-free-caramel-protein-matcha-venti`)
- **Iced Black Tea** — default Grande: Tall (`starbucks.tea.iced-black-tea-tall`), Grande (`starbucks.tea.iced-black-tea`), Venti (`starbucks.tea.iced-black-tea-venti`), Trenta (`starbucks.tea.iced-black-tea-trenta`)
- **Iced Green Tea** — default Grande: Tall (`starbucks.tea.iced-green-tea-tall`), Grande (`starbucks.tea.iced-green-tea`), Venti (`starbucks.tea.iced-green-tea-venti`), Trenta (`starbucks.tea.iced-green-tea-trenta`)
- **Iced Passion Tango Tea** — default Grande: Tall (`starbucks.tea.iced-passion-tango-tea-tall`), Grande (`starbucks.tea.iced-passion-tango-tea`), Venti (`starbucks.tea.iced-passion-tango-tea-venti`), Trenta (`starbucks.tea.iced-passion-tango-tea-trenta`)
- **Iced Black Tea Lemonade** — default Grande: Tall (`starbucks.tea.iced-black-tea-lemonade-tall`), Grande (`starbucks.tea.iced-black-tea-lemonade`), Venti (`starbucks.tea.iced-black-tea-lemonade-venti`), Trenta (`starbucks.tea.iced-black-tea-lemonade-trenta`)
- **Iced Green Tea Lemonade** — default Grande: Tall (`starbucks.tea.iced-green-tea-lemonade-tall`), Grande (`starbucks.tea.iced-green-tea-lemonade`), Venti (`starbucks.tea.iced-green-tea-lemonade-venti`), Trenta (`starbucks.tea.iced-green-tea-lemonade-trenta`)
- **Iced Passion Tango Tea Lemonade** — default Grande: Tall (`starbucks.tea.iced-passion-tango-tea-lemonade-tall`), Grande (`starbucks.tea.iced-passion-tango-tea-lemonade`), Venti (`starbucks.tea.iced-passion-tango-tea-lemonade-venti`), Trenta (`starbucks.tea.iced-passion-tango-tea-lemonade-trenta`)
- **Iced Peach Green Tea** — default Grande: Tall (`starbucks.tea.iced-peach-green-tea-tall`), Grande (`starbucks.tea.iced-peach-green-tea`), Venti (`starbucks.tea.iced-peach-green-tea-venti`), Trenta (`starbucks.tea.iced-peach-green-tea-trenta`)
- **Iced London Fog Latte** — default Grande: Tall (`starbucks.tea.iced-london-fog-latte-tall`), Grande (`starbucks.tea.iced-london-fog-latte`), Venti (`starbucks.tea.iced-london-fog-latte-venti`)
- **Strawberry Açaí Refresher** — default Grande: Tall (`starbucks.refreshers.strawberry-acai-refresher-tall`), Grande (`starbucks.refreshers.strawberry-acai-refresher`), Venti (`starbucks.refreshers.strawberry-acai-refresher-venti`), Trenta (`starbucks.refreshers.strawberry-acai-refresher-trenta`)
- **Mango Dragonfruit Refresher** — default Grande: Tall (`starbucks.refreshers.mango-dragonfruit-refresher-tall`), Grande (`starbucks.refreshers.mango-dragonfruit-refresher`), Venti (`starbucks.refreshers.mango-dragonfruit-refresher-venti`), Trenta (`starbucks.refreshers.mango-dragonfruit-refresher-trenta`)
- **Passionfruit Guava Refresher** — default Grande: Tall (`starbucks.refreshers.passionfruit-guava-refresher-tall`), Grande (`starbucks.refreshers.passionfruit-guava-refresher`), Venti (`starbucks.refreshers.passionfruit-guava-refresher-venti`), Trenta (`starbucks.refreshers.passionfruit-guava-refresher-trenta`)
- **Blue Coconut Refresher** — default Grande: Tall (`starbucks.refreshers.blue-coconut-refresher-tall`), Grande (`starbucks.refreshers.blue-coconut-refresher`), Venti (`starbucks.refreshers.blue-coconut-refresher-venti`), Trenta (`starbucks.refreshers.blue-coconut-refresher-trenta`)
- **Mango Strawberry Refresher** — default Grande: Tall (`starbucks.refreshers.mango-strawberry-refresher-tall`), Grande (`starbucks.refreshers.mango-strawberry-refresher`), Venti (`starbucks.refreshers.mango-strawberry-refresher-venti`), Trenta (`starbucks.refreshers.mango-strawberry-refresher-trenta`)
- **Tropical Butterfly Refresher** — default Grande: Tall (`starbucks.refreshers.tropical-butterfly-refresher-tall`), Grande (`starbucks.refreshers.tropical-butterfly-refresher`), Venti (`starbucks.refreshers.tropical-butterfly-refresher-venti`), Trenta (`starbucks.refreshers.tropical-butterfly-refresher-trenta`)
- **Strawberry Açaí Lemonade Refresher** — default Grande: Tall (`starbucks.refreshers.strawberry-acai-lemonade-refresher-tall`), Grande (`starbucks.refreshers.strawberry-acai-lemonade-refresher`), Venti (`starbucks.refreshers.strawberry-acai-lemonade-refresher-venti`), Trenta (`starbucks.refreshers.strawberry-acai-lemonade-refresher-trenta`)
- **Mango Dragonfruit Lemonade Refresher** — default Grande: Tall (`starbucks.refreshers.mango-dragonfruit-lemonade-refresher-tall`), Grande (`starbucks.refreshers.mango-dragonfruit-lemonade-refresher`), Venti (`starbucks.refreshers.mango-dragonfruit-lemonade-refresher-venti`), Trenta (`starbucks.refreshers.mango-dragonfruit-lemonade-refresher-trenta`)
- **Blue Coconut Lemonade Refresher** — default Grande: Tall (`starbucks.refreshers.blue-coconut-lemonade-refresher-tall`), Grande (`starbucks.refreshers.blue-coconut-lemonade-refresher`), Venti (`starbucks.refreshers.blue-coconut-lemonade-refresher-venti`), Trenta (`starbucks.refreshers.blue-coconut-lemonade-refresher-trenta`)
- **Mango Strawberry Lemonade Refresher** — default Grande: Tall (`starbucks.refreshers.mango-strawberry-lemonade-refresher-tall`), Grande (`starbucks.refreshers.mango-strawberry-lemonade-refresher`), Venti (`starbucks.refreshers.mango-strawberry-lemonade-refresher-venti`), Trenta (`starbucks.refreshers.mango-strawberry-lemonade-refresher-trenta`)
- **Pink Drink** — default Grande: Tall (`starbucks.refreshers.pink-drink-tall`), Grande (`starbucks.refreshers.pink-drink`), Venti (`starbucks.refreshers.pink-drink-venti`), Trenta (`starbucks.refreshers.pink-drink-trenta`)
- **Dragon Drink** — default Grande: Tall (`starbucks.refreshers.dragon-drink-tall`), Grande (`starbucks.refreshers.dragon-drink`), Venti (`starbucks.refreshers.dragon-drink-venti`), Trenta (`starbucks.refreshers.dragon-drink-trenta`)
- **Butterfly Drink** — default Grande: Tall (`starbucks.refreshers.butterfly-drink-tall`), Grande (`starbucks.refreshers.butterfly-drink`), Venti (`starbucks.refreshers.butterfly-drink-venti`), Trenta (`starbucks.refreshers.butterfly-drink-trenta`)
- **Ocean Drink** — default Grande: Tall (`starbucks.refreshers.ocean-drink-tall`), Grande (`starbucks.refreshers.ocean-drink`), Venti (`starbucks.refreshers.ocean-drink-venti`), Trenta (`starbucks.refreshers.ocean-drink-trenta`)
- **Mango Dream** — default Grande: Tall (`starbucks.refreshers.mango-dream-tall`), Grande (`starbucks.refreshers.mango-dream`), Venti (`starbucks.refreshers.mango-dream-venti`), Trenta (`starbucks.refreshers.mango-dream-trenta`)
- **Cannon Ball Drink** — default Grande: Tall (`starbucks.refreshers.cannon-ball-drink-tall`), Grande (`starbucks.refreshers.cannon-ball-drink`), Venti (`starbucks.refreshers.cannon-ball-drink-venti`), Trenta (`starbucks.refreshers.cannon-ball-drink-trenta`)
- **Pink Cannon Ball Drink** — default Grande: Tall (`starbucks.refreshers.pink-cannon-ball-drink-tall`), Grande (`starbucks.refreshers.pink-cannon-ball-drink`), Venti (`starbucks.refreshers.pink-cannon-ball-drink-venti`), Trenta (`starbucks.refreshers.pink-cannon-ball-drink-trenta`)
- **Lemonade** — default Grande: Kids (`starbucks.refreshers.lemonade-kids`), Tall (`starbucks.refreshers.lemonade-tall`), Grande (`starbucks.refreshers.lemonade`), Venti (`starbucks.refreshers.lemonade-venti`), Trenta (`starbucks.refreshers.lemonade-trenta`)
- **Coffee Frappuccino** — default Grande: Tall (`starbucks.frappuccino.coffee-frappuccino-tall`), Grande (`starbucks.frappuccino.coffee-frappuccino`), Venti (`starbucks.frappuccino.coffee-frappuccino-venti`)
- **Caramel Frappuccino** — default Grande: Tall (`starbucks.frappuccino.caramel-frappuccino-tall`), Grande (`starbucks.frappuccino.caramel-frappuccino`), Venti (`starbucks.frappuccino.caramel-frappuccino-venti`)
- **Mocha Frappuccino** — default Grande: Tall (`starbucks.frappuccino.mocha-frappuccino-tall`), Grande (`starbucks.frappuccino.mocha-frappuccino`), Venti (`starbucks.frappuccino.mocha-frappuccino-venti`)
- **Caramel Ribbon Crunch Frappuccino** — default Grande: Tall (`starbucks.frappuccino.caramel-ribbon-crunch-frappuccino-tall`), Grande (`starbucks.frappuccino.caramel-ribbon-crunch-frappuccino`), Venti (`starbucks.frappuccino.caramel-ribbon-crunch-frappuccino-venti`)
- **Mocha Cookie Crumble Frappuccino** — default Grande: Tall (`starbucks.frappuccino.mocha-cookie-crumble-frappuccino-tall`), Grande (`starbucks.frappuccino.mocha-cookie-crumble-frappuccino`), Venti (`starbucks.frappuccino.mocha-cookie-crumble-frappuccino-venti`)
- **Vanilla Bean Crème Frappuccino** — default Grande: Tall (`starbucks.frappuccino.vanilla-bean-creme-frappuccino-tall`), Grande (`starbucks.frappuccino.vanilla-bean-creme-frappuccino`), Venti (`starbucks.frappuccino.vanilla-bean-creme-frappuccino-venti`)
- **Strawberry Crème Frappuccino** — default Grande: Tall (`starbucks.frappuccino.strawberry-creme-frappuccino-tall`), Grande (`starbucks.frappuccino.strawberry-creme-frappuccino`), Venti (`starbucks.frappuccino.strawberry-creme-frappuccino-venti`)
- **Matcha Crème Frappuccino** — default Grande: Tall (`starbucks.frappuccino.matcha-creme-frappuccino-tall`), Grande (`starbucks.frappuccino.matcha-creme-frappuccino`), Venti (`starbucks.frappuccino.matcha-creme-frappuccino-venti`)

### House configurations

- **No Whip** — ON by default. Whipped cream is ON by default on every mocha, hot chocolate and Frappuccino — the API's per-size default recipe carries `Whipped Cream Option` at sizeCode 'regular' with default:true. 'No whip' is the single most-uttered modification at any Starbucks counter and it removes roughly 70-110 cal and 7-11 g fat depending on size. Our published macros for these items are the WITH-whip numbers (Caffè Mocha Grande = 370 cal matches Starbucks' whipped default exactly), so a user who orders no-whip currently has no way to subtract it.
  - maps to: `starbucks.hot-coffee.caffe-mocha`, `starbucks.hot-coffee.white-chocolate-mocha`, `starbucks.hot-coffee.hot-chocolate`, `starbucks.cold-coffee.iced-caffe-mocha`, `starbucks.cold-coffee.iced-white-chocolate-mocha`, `starbucks.frappuccino.coffee-frappuccino`, `starbucks.frappuccino.caramel-frappuccino`, `starbucks.frappuccino.mocha-frappuccino`, `starbucks.frappuccino.caramel-ribbon-crunch-frappuccino`, `starbucks.frappuccino.mocha-cookie-crumble-frappuccino`, `starbucks.frappuccino.vanilla-bean-creme-frappuccino`, `starbucks.frappuccino.strawberry-creme-frappuccino`, `starbucks.frappuccino.matcha-creme-frappuccino`
  - **gap:** Whipped Cream as a removable/adjustable line item (options are Extra / Regular / Light / None) — we have no whipped cream item anywhere in the menu
- **The Milk Default (2% everywhere, Whole Milk in Frappuccinos)** — ON by default. Every hot and iced espresso drink, chai, matcha, London Fog, hot chocolate and steamer is built on 2% milk unless you say otherwise. Frappuccinos are built on WHOLE milk — a detail almost nobody knows and one that makes 'the same drink' a different macro depending on family. Cold Brew, Iced Coffee and Americano get NO milk at all by default (they offer 'splash of' instead). Coconutmilk is the default base for the Pink/Dragon/Ocean/Butterfly/Mango Dream drinks. There are 12 milk choices, and swapping is the second-most-common modification after 'no whip' — oat and almond are ordered constantly.
  - maps to: `starbucks.hot-coffee.caffe-latte`, `starbucks.hot-coffee.cappuccino`, `starbucks.hot-coffee.caffe-misto`, `starbucks.hot-coffee.flat-white`, `starbucks.hot-coffee.caramel-macchiato`, `starbucks.hot-coffee.caffe-mocha`, `starbucks.hot-coffee.hot-chocolate`, `starbucks.hot-coffee.steamed-milk`, `starbucks.cold-coffee.iced-caffe-latte`, `starbucks.cold-coffee.iced-caramel-macchiato`, `starbucks.tea.chai-latte`, `starbucks.tea.matcha-latte`, `starbucks.tea.london-fog-latte`, `starbucks.frappuccino.caramel-frappuccino`, `starbucks.frappuccino.coffee-frappuccino`, `starbucks.frappuccino.vanilla-bean-creme-frappuccino`
  - **gap:** 2% Milk
  - **gap:** Whole Milk
  - **gap:** Nonfat Milk
  - **gap:** Oatmilk
  - **gap:** Almondmilk
  - **gap:** Soymilk
  - **gap:** Coconutmilk
  - **gap:** Breve (Half & Half)
  - **gap:** Heavy Cream
  - **gap:** Protein-boosted Milk
  - **gap:** Vanilla Sweet Cream
  - **gap:** Nondairy Vanilla Sweet Cream
  - **gap:** 'Splash of' versions of all of the above for cold brew / iced coffee / americano
- **Half the Pumps / Standard Pump Count** — ON by default. Every syrup and sauce has a size-scaled default pump count that nobody states out loud but everyone is drinking. Hot espresso drinks: Short 2, Tall 3, Grande 4, Venti 5. Iced: Tall 3, Grande 4, Venti 6. Frappuccino: Tall 2, Grande 3, Venti 4. 'Half the pumps' / 'just one pump' / 'sugar-free vanilla instead' is THE canonical macro-conscious Starbucks order and each pump is roughly 20 cal / 5 g sugar. Without a pump control our numbers are locked to the full-sugar build.
  - maps to: `starbucks.hot-coffee.cinnamon-dolce-latte`, `starbucks.hot-coffee.blonde-vanilla-latte`, `starbucks.hot-coffee.caramel-macchiato`, `starbucks.hot-coffee.caffe-mocha`, `starbucks.hot-coffee.white-chocolate-mocha`, `starbucks.cold-coffee.iced-cinnamon-dolce-latte`, `starbucks.cold-coffee.iced-blonde-vanilla-latte`, `starbucks.cold-coffee.iced-caramel-macchiato`, `starbucks.cold-coffee.iced-caffe-mocha`, `starbucks.cold-coffee.iced-white-chocolate-mocha`, `starbucks.cold-coffee.iced-shaken-espresso`, `starbucks.cold-coffee.iced-brown-sugar-oatmilk-shaken-espresso`
  - **gap:** A per-pump quantity control (0 to 'extra') on each syrup/sauce
  - **gap:** 14 Syrups: Vanilla, Sugar-Free Vanilla, Caramel, Sugar-Free Caramel, Brown Sugar, Cinnamon Dolce, Hazelnut, Horchata, Banana, Mango, Marshmallow, Peppermint, Raspberry, Toasted Coconut
  - **gap:** 4 Sauces: Mocha, White Chocolate Mocha, Dark Caramel, Pistachio
  - **gap:** 4 Powders: Vanilla Bean, Lavender, Orange Vanilla, Blue
- **Chai With No Classic** — ON by default. A Chai Latte is not just chai concentrate and milk — the standard recipe adds an EQUAL number of pumps of Classic Syrup (liquid cane sugar) on top. A Grande is 4 pumps chai PLUS 4 pumps classic. This is invisible on any nutrition PDF and is the reason a chai latte reads sweeter than people expect. 'Chai, no classic' is a well-worn order among regulars and drops roughly 80 cal / 20 g sugar from a Grande. Iced Venti is 6 and 6.
  - maps to: `starbucks.tea.chai-latte`, `starbucks.tea.iced-chai-latte`
  - **gap:** Classic Syrup as a separately removable pumped component of the chai recipe
- **Add Cold Foam (including Protein Cold Foam, +15 g)**. 'Add sweet cream cold foam' has become one of the most-added modifiers on any cold drink, and in 2025 Starbucks added a Protein Cold Foam line that advertises +15 g protein per serving. Starbucks now offers three parallel foam families on nearly every drink: Cold Foam (16 flavors), Nondairy Cold Foam (15), Protein Cold Foam (16, labelled '15g*'). For a macro-tracking app this is arguably the single most valuable missing modifier — it is the one add-on a Loadout user would deliberately reach for to raise protein rather than lower calories.
  - maps to: `starbucks.cold-coffee.cold-brew`, `starbucks.cold-coffee.nitro-cold-brew`, `starbucks.cold-coffee.iced-coffee`, `starbucks.cold-coffee.iced-caffe-latte`, `starbucks.cold-coffee.iced-shaken-espresso`, `starbucks.tea.iced-chai-latte`, `starbucks.tea.iced-matcha-latte`, `starbucks.refreshers.strawberry-acai-refresher`
  - **gap:** Vanilla Sweet Cream Cold Foam
  - **gap:** Salted Caramel Cream Cold Foam
  - **gap:** Chocolate Cream Cold Foam
  - **gap:** Matcha Cream Cold Foam
  - **gap:** Brown Sugar Cream Cold Foam
  - **gap:** the other 11 Cold Foam flavors
  - **gap:** all 15 Nondairy Cold Foam flavors
  - **gap:** Vanilla Protein Cold Foam and the other 15 Protein Cold Foam flavors (+15 g protein each; Strawberry is 13 g)
  - **gap:** each foam's Regular / Light / Extra level
- **Bagel With Cream Cheese (or Butter), Warmed**. Ordering a bagel bare is the exception, not the rule. The Plain Bagel product page has exactly two option groups and one of them is Butter & Spreads with precisely two choices: Butter and Plain Cream Cheese. The other is Warming (Warmed / Not Warmed). A schmear is on the order of +100 cal and +9 g fat, which is a ~40% swing on a 250 cal bagel — and our bagel rows are the naked-bread numbers.
  - maps to: `starbucks.breads.plain-bagel`, `starbucks.breads.everything-bagel`
  - **gap:** Plain Cream Cheese
  - **gap:** Butter
- **Oatmeal With the Packets**. Rolled & Steel-Cut Oatmeal is served with topping packets you choose at the register and dump in yourself. Starbucks lists five: Nut Medley, Dried Fruit, Brown Sugar, Agave Syrup, Blueberries — plus a '1/4 inch milk on top' option in 11 milks and the full sweetener packet set. Our oatmeal row is '1 item (42 g)' = 160 cal, which is the DRY OAT portion with nothing on it. Almost nobody eats it that way; nut medley alone is ~100 cal and 9 g fat. This is the biggest single under-count in our food list.
  - maps to: `starbucks.food.rolled-and-steel-cut-oatmeal`
  - **gap:** Nut Medley
  - **gap:** Dried Fruit
  - **gap:** Brown Sugar
  - **gap:** Agave Syrup
  - **gap:** Blueberries
  - **gap:** 1/4 inch milk on top (11 milk choices)
  - **gap:** Honey / Sugar / Sugar in the Raw / Splenda / Stevia packets
- **Add a Shot / Blonde / Ristretto / Decaf** — ON by default. Espresso shot count is a default that scales with size and is constantly overridden: a latte carries 1 shot Short and Tall, 2 Grande, 2 Venti hot but 3 Venti iced. 'Add a shot', 'make it blonde', 'half-caf', 'ristretto' are said all day. Macro impact is small (~5 cal, ~1 g protein per shot) but it is a core part of how the order is spoken, and a Quad-shot Americano genuinely differs from a Solo.
  - maps to: `starbucks.hot-coffee.caffe-latte`, `starbucks.hot-coffee.caffe-americano`, `starbucks.hot-coffee.caffe-mocha`, `starbucks.hot-coffee.cappuccino`, `starbucks.cold-coffee.iced-caffe-latte`, `starbucks.cold-coffee.iced-caffe-americano`, `starbucks.cold-coffee.iced-shaken-espresso`
  - **gap:** Extra Espresso Shot as an add-on quantity
  - **gap:** Blonde Espresso / Signature Espresso / Decaf / 1-2 Decaf / 1-3 Decaf / 2-3 Decaf roast选择
  - **gap:** Ristretto and Long Shot styles
  - **gap:** Affogato-Style Shots (poured over a Frappuccino)
- **No Water / Milk Instead of Water**. Every espresso, tea, chai, matcha, Frappuccino and even the oatmeal carries a 'Preparation → Milk Instead of Water' group with 11 milk choices ('No water — Prepared with Oatmilk', etc.). 'Iced chai, no water' and 'Americano, no water, extra oat milk' are standard enthusiast orders. This is a big macro move, not a small one: it converts a near-zero-calorie Americano into a milk drink, and it makes a chai substantially richer.
  - maps to: `starbucks.tea.iced-chai-latte`, `starbucks.tea.chai-latte`, `starbucks.cold-coffee.iced-caffe-americano`, `starbucks.hot-coffee.caffe-americano`, `starbucks.tea.iced-matcha-latte`, `starbucks.food.rolled-and-steel-cut-oatmeal`
  - **gap:** 'No water — prepared with <milk>' as a preparation toggle across 11 milk types
- **Light Ice** — ON by default. Ice level (Regular / Light / Extra / None) is an explicit option on every cold drink and 'light ice' is the most common cold-drink request there is. On a Refresher, iced tea or lemonade less ice means more base liquid in the same cup, so it is a genuine calorie increase — the Trenta Refresher jumps meaningfully. On an iced latte it means more milk.
  - maps to: `starbucks.refreshers.strawberry-acai-refresher`, `starbucks.refreshers.pink-drink`, `starbucks.tea.iced-black-tea`, `starbucks.tea.iced-green-tea-lemonade`, `starbucks.cold-coffee.iced-coffee`, `starbucks.cold-coffee.iced-caffe-latte`
  - **gap:** Ice level control (Regular / Light / Extra / No Ice)
- **Caramel Drizzle Is Standard (Caramel Macchiato and Caramel Frappuccino)** — ON by default. The crosshatch of caramel on top of a Caramel Macchiato and the caramel lacing a Caramel Frappuccino are default recipe components, not decoration you asked for. 'No drizzle' / 'light drizzle' is a real request and worth roughly 15-30 cal. Same story for the mocha drizzle that is default on Hot Chocolate.
  - maps to: `starbucks.hot-coffee.caramel-macchiato`, `starbucks.cold-coffee.iced-caramel-macchiato`, `starbucks.frappuccino.caramel-frappuccino`, `starbucks.frappuccino.caramel-ribbon-crunch-frappuccino`, `starbucks.hot-coffee.hot-chocolate`
  - **gap:** Caramel Drizzle (Regular / Light / Extra / None)
  - **gap:** Mocha Drizzle (Regular / Light / Extra / None)
- **Frappuccino Chips — the DIY Java Chip**. There is no longer a 'Java Chip Frappuccino' on the menu, but people still order one every day. It is now built: Mocha Frappuccino plus Frappuccino Chips. Starbucks exposes a Blended Options group with Frappuccino Chips, Frappuccino Roast (the coffee powder — removable, which is how you get a decaf Frapp), Double Blended, and Affogato-Style Shots, plus 'Line the Cup with Caramel/Mocha Sauce'. Chips and cup-lining are meaningful calories.
  - maps to: `starbucks.frappuccino.mocha-frappuccino`, `starbucks.frappuccino.coffee-frappuccino`, `starbucks.frappuccino.caramel-frappuccino`, `starbucks.frappuccino.vanilla-bean-creme-frappuccino`
  - **gap:** Frappuccino Chips
  - **gap:** Line the Cup with Caramel Sauce
  - **gap:** Line the Cup with Mocha Sauce
  - **gap:** Cookie Crumble Topping
  - **gap:** Caramel Crunch Topping
  - **gap:** Mango-Pineapple Flavored Pearls
  - **gap:** Double Blended (no macro change)
  - **gap:** Affogato-Style Shots
- **Add Avocado Spread to the Sandwich**. Avocado Spread is not really a snack — Starbucks merchandises it as an attachment inside six different food subcategories (Breakfast Sandwiches, Breakfast Wraps, Egg Bites & Bakes, Bagels, Lunch Sandwiches, Pockets). It is the standard way people upgrade a bagel or a wrap and it is a real ~90 cal / 8 g fat addition. We have the item but stranded alone in the snack shelf, so nobody building a sandwich will find it.
  - maps to: `starbucks.extras.avocado-spread`, `starbucks.breads.plain-bagel`, `starbucks.breads.everything-bagel`, `starbucks.food.spinach-feta-and-egg-white-wrap`, `starbucks.food.bacon-and-gruyere-egg-bites`, `starbucks.food.turkey-bacon-cheddar-and-egg-white-sandwich`
- **Sweeten It (Classic Syrup or Packets)**. Brewed iced teas, iced coffee, cold brew and americanos now come UNSWEETENED by default — I verified Iced Coffee specifically because the old 'iced coffee arrives with classic syrup' convention is widely repeated and is now WRONG (Grande Iced Coffee recipe is ice only, 5 cal). The live convention is the reverse: people add Classic Syrup by pump, or grab packets. Note the asymmetry that trips people up — plain Iced Black Tea is unsweetened but Iced Black Tea LEMONADE is not.
  - maps to: `starbucks.cold-coffee.iced-coffee`, `starbucks.cold-coffee.cold-brew`, `starbucks.tea.iced-black-tea`, `starbucks.tea.iced-green-tea`, `starbucks.tea.iced-passion-tango-tea`, `starbucks.hot-coffee.caffe-americano`
  - **gap:** Classic Syrup (pumped, size-scaled)
  - **gap:** Honey Blend Syrup
  - **gap:** Honey packet
  - **gap:** Sugar packet
  - **gap:** Sugar in the Raw packet
  - **gap:** Splenda
  - **gap:** Stevia in the Raw

### Station order

Our browse order is close to right; the problem is depth, not sequence.

MATCHES: ours is hot-coffee → cold-coffee → tea → refreshers → frappuccino → food → breads(Bakery) → sides(Treats) → extras(Snacks). Real is Coffee & Espresso (Hot then Cold) → Tea → Refreshment → Frappuccino → Food (Breakfast → Bakery → Treats → Lunch → Snacks). The beverage spine is in the correct order, and Bakery→Treats→Snacks matches. That part is genuinely well done.

WHAT SHOULD MOVE OR APPEAR:

1. Insert the missing middle. The single biggest station error is that there is no per-drink customization step between "pick drink" and "pick food". Real ordering spends most of its time there. Everything in optionalCategoryIds today is food, so after choosing a latte the app offers you a croissant — it never offers you milk.

2. Promote Protein to a top-level station, second in the list. Starbucks made "Protein" a first-class menu category with three subgroups (High Protein Lattes, No Added Sugar Options, Protein Cold Foam Drinks). We already own 22 of these items but they are scattered across hot-coffee, cold-coffee and tea, so the exact user Loadout is built for cannot find them. This is the highest-value reordering fix.

3. Add "The Latest / Trending" as the first entry point. It is where the app opens.

4. Split out "Other Sips". Hot Chocolate and Steamed Milk are buried in our hot-coffee; Cold Milk in cold-coffee; Lemonade in refreshers. On the real menu these live together under Other Sips → Hot Chocolate, Lemonade & More → Milk & Steamers. Nobody hunting hot chocolate looks under "Hot Coffee & Espresso".

5. Reorder inside Tea. Real order is Chai → Matcha → Hot Tea → Iced Tea. Ours leads with brewed hot teas and buries chai and matcha in the middle — inverted from both the app and from what people actually order.

6. Move Lunch after Treats inside Food, and attach Avocado Spread as an add-on. On the real menu Avocado Spread is merchandised inside Breakfast Sandwiches, Breakfast Wraps, Egg Bites & Bakes, Bagels, Lunch Sandwiches and Pockets — six places, as an attachment. We list it once, standalone, in extras. It is macro-relevant, so it should attach to the sandwich rather than sit alone in a snack shelf.

7. Frappuccino should split into Coffee Frappuccino and Crème Frappuccino, which is how the board groups its 8 items — and it matters, because Crème Frapps take no espresso.

### Missing staples

- ENTIRE MISSING LINE — Energy Refreshers (20 permanent SKUs, a top-level menu category): Strawberry Açaí / Passionfruit Guava / Blue Coconut / Tropical Butterfly / Mango Strawberry / Mango Dragonfruit Lemonade Energy Refreshers, plus Pink, Dragon, Ocean, Butterfly, Mango Dream, Cannon Ball, Pink Cannon Ball and Island Colada Energy Drinks. We have zero of these.
- ENTIRE MISSING LINE — Blended Refreshers (12 permanent SKUs): Blended Pink Drink, Blended Dragon Drink, Blended Ocean Drink, Blended Mango Dream, Blended Cannon Ball Drink, Blended Pink Cannon Ball Drink, Blended Island Colada Drink, and the five Blended Lemonade Refreshers. Plus 12 more Blended Energy Refreshers.
- Espresso Con Panna (#411) — permanent item under Espresso Shot, Solo/Doppio/Triple/Quad
- Espresso Macchiato (#412) — permanent, the other half of the Macchiato category
- Iced Peach Green Tea Lemonade (#2123074) — we carry the non-lemonade version only, and lemonade is the more-ordered half
- Iced Horchata Shaken Espresso (#27497)
- Iced Hazelnut Oatmilk Shaken Espresso (#2123805)
- Vanilla Crème (#873068652) — hot steamer, Kids/Short/Tall/Grande/Venti
- Pistachio Crème (#2123366) — hot steamer
- Iced Vanilla Protein Cream Shaken Espresso (#40621) — one of only three Protein Cold Foam Drinks and we have only one of them
- Iced Banana Protein Cream Matcha (#28243)
- Nondairy Salted Caramel Cream Cold Brew (#2123883)
- Nondairy Chocolate Cream Cold Brew (#2123881)
- Cold Brew with Nondairy Vanilla Sweet Cream Cold Foam (#2123880)
- Pistachio Cream Cold Brew (#2123702)
- Toasted Coconut Cream Cold Brew (#34832)
- Pistachio Cortado (#34806) and Brown Sugar Oatmilk Cortado (#2124651) — the Cortado category has three members, we have one
- Featured Dark Roast – Starbucks 1971 Roast (#479) — the brewed dark roast that sits alongside Caffè Verona on the board
- Coffee Traveler – Pike Place Roast and Decaf (#873068655 / #873068657) — the 96 oz box, permanent
- Blended Matcha Lemonade (#40630) and Blended Strawberry Lemonade (#40923)
- Frappuccinos we lack that are on the current board: S'mores (#2121267), Horchata (#40517), Pistachio (#2123364), Orange Cream (#40667), S'mores Crème (#2121268), Horchata Crème (#40516), Lavender Crème (#2123827), Pistachio Crème (#2123365). NOTE: Java Chip and Double Chocolaty Chip Crème are genuinely gone from the menu — do not add them; Java Chip is now a build (Mocha Frapp + Frappuccino Chips).
- Lavender Latte / Iced Lavender Latte (#34919 / #34913), Pistachio Latte / Iced (#2123404), Toasted Coconut Latte / Iced (#40492 / #40491) — all listed Available today and all have run multi-year, but each has a seasonal history, so treat as probable-core rather than certain
- Ellenos Strawberry Shortcake Greek Yogurt (#2124784)
- Pumpkin & Pepita Loaf (#1255) — long-running bakery loaf
- That's It Apple + Mango Bar (#2121693) — we carry only the Blueberry flavor
- SkinnyDipped Coconut Almond Bite (#39313) and SkinnyDipped Lemon Bliss Almonds (#2123820) — we carry only the Dark Chocolate Cocoa Almonds
- Peter Rabbit Organics Strawberry Banana (#2121692)
- INCONSISTENT CUT — Bottled Beverages: we include Koia shakes and Horizon milk but omit everything else off the same shelf: Evolution Fresh Pure Orange / Defense Up / Super Fruit Greens, Tree Top Organic Apple Juice, Poppi Shirley Temple and Grape sodas, Spindrift Lemon and Raspberry Lime, Starbucks Iced Energy Blueberry Lemonade and Tropical Peach, Sol-ti Ginger and Turmeric SuperShots. Pick one rule and apply it.
- THE MODIFIER LAYER — the largest gap of all, and every item in it is permanently available: 12 milks, 14 syrups, 4 sauces, 4 powders, 47 cold foams across three families, whipped cream, caramel and mocha drizzle, 5 dry toppings, extra espresso shots, Classic and Honey Blend syrup, 5 sweetener packets, cream cheese, butter, and the 5 oatmeal topping packets.

### Naming

- Every drink name carries a redundant size in parentheses — 'Caffè Mocha (Venti)', 'Iced Chai Latte (Tall)'. The board says 'Caffè Mocha' and the customer says 'venti mocha'. 366 of our 427 rows have a size baked into the display name; it belongs in a chip picker, not the title.
- 'Pike Place Roast (Medium)' — the board reads 'Medium Roast — Pike Place® Roast', roast descriptor FIRST. Nobody ever says '(Medium)'. Same inversion on 'Caffè Verona Dark Roast' (board: 'Dark Roast — Caffè Verona®') and 'Sunsera Blonde Roast' (board: 'Blonde Roast — Starbucks® Sunsera'). All three of our brewed-coffee names are word-order-flipped from the menu board.
- 'Espresso (Doppio)' / '(Solo)' / '(Triple)' / '(Quad)' — those are size names, not part of the drink name. Board says 'Espresso'; the customer says 'doppio espresso' or 'quad shot'.
- 'Honey Citrus Mint Tea' — a very large share of customers order this by its folk name, 'Medicine Ball', and baristas ring it in on hearing that. Without an alias it is unfindable to the people most likely to want it.
- 'Chai Latte' — the spoken and long-standing board form is 'Chai TEA Latte'. Almost nobody drops the 'tea'. Needs an alias.
- 'Matcha Latte' — commonly ordered as 'green tea latte' or 'matcha green tea latte', which was the previous board name. Alias needed both directions.
- 'Caffè Misto' — customers arriving from any other coffee shop ask for a 'café au lait'. That is exactly what this is, and the word 'misto' is Starbucks-only vocabulary.
- 'Blonde Vanilla Latte' — board is 'Starbucks® Blonde Vanilla Latte'; searching 'blonde' should also surface it, since the roast, not the flavor, is what people are after.
- 'Iced Shaken Espresso' — long-time customers still call this the 'iced doubleshot' (its former name) or just 'shaken espresso'. Needs aliases.
- Frappuccino names drop the '® Blended Beverage' tail, which is correct for speech — but the spoken form is 'frap' ('caramel frap', 'java chip frap'). A 'frap' search alias would earn its keep.
- 'Ellenos Muesli Yogurt (No Added Sugar)' — board reads 'Ellenos® Muesli Yogurt – No Added Sugar'; our parenthetical reads like a size variant next to all the other parenthetical sizes.
- 'Organic Valley Mozzarella String Cheese' — the board now says 'Organic Valley Stringles® Mozzarella String Cheese'.
- 'Perfect Bar Peanut Butter' vs board 'Perfect Bar® Peanut Butter', 'KIND Salted Caramel & Dark Chocolate Nut Bar' vs 'KIND® Salted Caramel & Dark Chocolate Nut Bar', 'Khloud White Cheddar Protein Popcorn' vs 'Khloud™ …' — dropping the marks is right for a builder UI, just noting the board differs.
- Category display names are mostly good: breads→'Bakery' and sides→'Treats' match the board exactly. But 'extras'→'Snacks & Grab-and-Go' is our invention; the board just says 'Snacks'. And 'food' spans both Breakfast and Lunch, which are two separate board sections.
- 'Cortado' has no size in the name and is Short-only, which is correct — but it will look inconsistent sitting in a list where everything else is suffixed, another argument for stripping the suffixes globally.

---

## CAVA — NEEDS_WORK

### How you actually order

Verified against CAVA's own web builder with a real store attached, for all four Build Your Own formats.

GRAINS BOWL: GRAINS ("Select one full grain or two half grains") -> DIPS + SPREADS ("Select up to three dips. Select again to add multiple scoops.") -> MAINS ("Select one full portion or two half portions") -> TOPPINGS ("Select your toppings" — unlimited, no cap) -> DRESSINGS ("Select up to two dressings") -> SIDES ("Select a side (Optional)") -> DESSERTS (Optional) -> DRINKS (Optional).

SALAD BOWL: identical, but the first station is GREENS ("Select one full green or two half greens").

GREENS + GRAINS BOWL: GREENS ("Select one green") -> GRAINS ("Select one grain") -> then the same DIPS -> MAINS -> TOPPINGS -> DRESSINGS -> SIDES -> DESSERTS -> DRINKS. Both base steps are single-pick here because the bowl is already a split; the builder prices each at half calories (Brown Rice 150 vs 310, Super Greens 20 vs 35).

PITA: no base station whatsoever. Starts at 310 Cal (the pita itself) and goes straight to DIPS + SPREADS -> MAINS -> TOPPINGS -> DRESSINGS -> SIDES -> DESSERTS -> DRINKS.

In-store this is a single glass-fronted line and a person walks you down it in exactly that order: base first, then "any dips or spreads?", then your protein, then they sweep across the toppings well, then "any dressing?", and the register is where sides/dessert/drink get asked. Two things a PDF will never tell you: DIPS COME BEFORE PROTEIN (unlike Chipotle, where salsa follows meat), and every bowl format offers a FREE SIDE PITA as the first option in the SIDES station.

### Sizes

CAVA has no size system. There is no Small/Medium/Large, no ounce tiers, no piece counts. Every Build Your Own format is one size at one base price ($13.15 at the store I checked), and the only price variance comes from premium proteins and add-ons. The real 'size' axis at CAVA is FRACTIONAL PORTIONS INSIDE a single build — full vs half grain, full vs half green, full vs half protein — which is a quantity concept, not a size picker, and our formats file already handles the greens+grains case with quantityPerPick 0.5. The one place two of our rows genuinely are the same dish at two sizes is the pita served as a side: 'Free Side Pita' (80 Cal, $0, offered on every bowl) vs 'Side Pita' (320 Cal, +$2.75). Note the 320-cal item is also the bread in the Pita format via autoAdd, so if these collapse into one row the pita format must keep referencing cava.sides.whole-pita directly rather than going through the size picker. A second latent size axis exists but we have no items for it: every dip is sold both as an in-build scoop (30-70 Cal) and as a side cup (100-220 Cal) — see missingStaples.

- **Side Pita** — default Free: Free (`cava.sides.side-pita`), Whole (`cava.sides.whole-pita`)

### House configurations

- **Free Side Pita**. Every bowl format (Grains, Salad, Greens + Grains) includes a free pita as a side. It is the FIRST option in the SIDES station on all three bowl builders, priced $0 while every other side is +$2.75 to +$4.45. Most regulars take it because it costs nothing, and it is the closest thing CAVA has to a house convention. It adds a real 80 Cal / 3P / 14C / 1.5F that a nutrition PDF will never attribute to your bowl, because in the PDF it is just a separate line item called 'Side Pita'. Not offered on the Pita format, for obvious reasons.
  - maps to: `cava.sides.side-pita`
- **Half-and-half protein (the split)**. CAVA lets you take two proteins as half portions in one bowl at no extra charge beyond the pricier protein's upcharge — half chicken / half falafel, half steak / half meatballs. This is the single most common non-obvious CAVA order and it is stated explicitly at the counter and in the app. It is macro-critical: the result is the AVERAGE of two proteins, not the sum. Our menu models mains as selectMany with no fractional quantity, so a user who picks two proteins in Loadout gets 2 FULL portions and roughly double the true protein and calories.
  - maps to: `cava.mains.grilled-chicken`, `cava.mains.harissa-honey-chicken`, `cava.mains.grilled-steak`, `cava.mains.braised-lamb`, `cava.mains.spicy-lamb-meatballs`, `cava.mains.glazed-salmon`, `cava.mains.falafel`, `cava.mains.roasted-vegetables`
  - **gap:** A half-portion (0.5 quantity) concept for the mains category. The formats file only uses quantityPerPick 0.5 for bases in greens-and-grains; mains has no equivalent, so the split cannot be expressed.
- **Half-and-half base in a single-base bowl**. Separate from the Greens + Grains format. Inside a plain GRAINS BOWL you can take two half grains (half saffron rice / half black lentils is the standard lifter order — it buys fiber and 18g protein from the lentils without giving up the rice). Inside a plain SALAD BOWL you can take two half greens. Our formats file only models a split for the greens-and-grains format; grain-bowl and salad both force a single full base, so half-rice/half-lentils cannot be built in Loadout at all.
  - maps to: `cava.bases.brown-rice`, `cava.bases.saffron-basmati`, `cava.bases.black-lentils`, `cava.bases.super-greens`, `cava.bases.arugula`, `cava.bases.baby-spinach`, `cava.bases.romaine`, `cava.bases.power-greens`
  - **gap:** quantityPerPick 0.5 with choose:'two' on the bases prompt of the grain-bowl and salad formats
- **Three dips, and repeat scoops**. CAVA includes up to THREE dips/spreads at no charge, not two — and you may select the same dip more than once to get multiple scoops. 'Double crazy feta' and 'double hummus' are ordinary counter requests. Our dips category is selectUpTo max 2, so we undercount the most calorie-dense free thing on the line: a third scoop of Crazy Feta or Harissa is +70 Cal / +6g fat each, and a double scoop doubles it again.
  - maps to: `cava.dips.tzatziki`, `cava.dips.hummus`, `cava.dips.crazy-feta`, `cava.dips.harissa`, `cava.dips.red-pepper-hummus`, `cava.dips.roasted-eggplant`
  - **gap:** dips selectionRule should be selectUpTo max 3, and must permit quantity > 1 on the same item
- **Two dressings**. CAVA gives you up to TWO dressings, not one. Doubling up is routine — skhug plus lemon herb tahini, or garlic dressing plus hot harissa. Our dressings category is selectUpTo max 1, which structurally hides the biggest single fat swing on the menu: Garlic Dressing alone is 180 Cal / 20g fat, and Garlic + Greek Vinaigrette together is 310 Cal / 34g fat that a user simply cannot enter today.
  - maps to: `cava.dressings.balsamic-date`, `cava.dressings.yogurt-dill`, `cava.dressings.lemon-herb-tahini`, `cava.dressings.strawberry-sesame`, `cava.dressings.greek-vinaigrette`, `cava.dressings.skhug`, `cava.dressings.hot-harissa-vinaigrette`, `cava.dressings.garlic-dressing`
  - **gap:** dressings selectionRule should be selectUpTo max 2
- **Double protein**. Asking for a second full scoop of the same protein for an upcharge. This is the default order for the gym crowd Loadout is built for and it roughly doubles the protein line (Grilled Chicken 28g -> 56g, +250 Cal). Flagging confidence honestly: the WEB builder caps mains at one full portion and offers no double control, so I could only confirm this as an in-store/register request rather than an app-native option. Treat as medium confidence.
  - maps to: `cava.mains.grilled-chicken`, `cava.mains.harissa-honey-chicken`, `cava.mains.grilled-steak`, `cava.mains.braised-lamb`, `cava.mains.spicy-lamb-meatballs`, `cava.mains.glazed-salmon`, `cava.mains.falafel`, `cava.mains.roasted-vegetables`
  - **gap:** an explicit 2x / extra-scoop quantity control on mains

### Station order

Our station order is CORRECT and should not be reordered. Our categories run bases -> dips -> mains -> toppings -> dressings -> sides, and CAVA's real build sequence is base -> DIPS + SPREADS -> MAINS -> TOPPINGS -> DRESSINGS -> SIDES. The non-obvious part is already right: dips come BEFORE protein at CAVA (the opposite of Chipotle, where salsa follows meat), and we have that.

Three fixes inside the sequence, none of them a reorder:

1. DESSERTS is its own station at CAVA, presented after SIDES ("Add a dessert to your meal (Optional)"). We have the four desserts (cava.sides.greyston-blondie, cava.sides.greyston-brownie, cava.sides.whisked-apricot-honey, cava.sides.whisked-dark-chocolate) buried inside the Sides category alongside pita and chips. Split them into a `desserts` category placed last.

2. The Pita format has NO base station at all — CAVA's /builder/byo-pita jumps straight from the pita to DIPS + SPREADS. Our cava.formats.json lists "bases" in the pita format's optionalCategoryIds, which invites users to put rice or greens in a pita. That is not orderable. Remove "bases" from the pita format's optionalCategoryIds.

3. In the Pita format, dips are the FIRST prompt, before protein. Our pita format prompts protein first, then dips. Swap those two prompts so the format mirrors the line.

### Missing staples

- Side Hummus (140 Cal) — side cup of hummus, permanent, in the SIDES station of every builder
- Side Tzatziki (100 Cal) — side cup, permanent
- Side Red Pepper Hummus (110 Cal) — side cup, permanent
- Side Crazy Feta® (210 Cal) — side cup, permanent; the single biggest gap since Crazy Feta is CAVA's signature and the side cup is 3x the in-bowl scoop
- Side Roasted Eggplant (150 Cal) — side cup, permanent
- Side Harissa (220 Cal) — side cup, permanent
- Harissa BBQ Pita Chips (280 Cal) — permanent side with its own menu page (/menu/harissa-bbq-pita-chips), present in the SIDES station of all four builders. It appears to have replaced our Sumac Sour Cream + Onion Pita Chips.
- STALE, not missing: cava.sides.sumac-pita-chips (Sumac Sour Cream + Onion Pita Chips) no longer appears anywhere on cava.com — not on the menu board and not in any builder's SIDES station. It should be removed or archived.
- Not counted as gaps (documented exclusions in build_cava_csv.py, and I agree with them): the 11 Curated Bowls/Pitas (Chicken + Rice, Harissa Avocado, Greek Salad, Falafel Crunch, Spicy Lamb + Avocado, Steak + Harissa, Salmon + Yogurt Dill, Salmon + Strawberry Sesame, Steak + Feta, Greek Chicken, Spicy Chicken + Avocado), Kids Meals, and all drinks.

### Naming

- cava.sides.side-pita — WORST OFFENDER. We call the 80-Cal item 'Side Pita'. On CAVA's board 'Side Pita' is the 320-Cal whole pita (+$2.75); the 80-Cal one is called 'Free Side Pita'. Our name points at the wrong product, so a user who orders a 'Side Pita' at the counter gets 320 Cal while Loadout logged 80. Rename to 'Free Side Pita'.
- cava.sides.whole-pita — we call it 'Whole Pita'; the board calls it 'Side Pita' in the SIDES station (it is simply 'the pita' when it is the Pita format's bread). No such words as 'Whole Pita' appear anywhere on CAVA's menu or builder.
- cava.bases.baby-spinach — we say 'Baby Spinach'; the builder says just 'Spinach'.
- cava.dips.hummus — we say 'Hummus'; the builder says 'Traditional Hummus'. This matters because Red Pepper Hummus sits right next to it, so 'Hummus' alone is ambiguous on the line.
- cava.dips.roasted-eggplant — we say 'Roasted Eggplant'; the builder says 'Roasted Eggplant Dip'.
- cava.toppings.sumac-slaw — we say 'Sumac Slaw'; the builder and every curated-bowl description say 'Sumac Cabbage Slaw'.
- cava.dips.crazy-feta — we say 'Crazy Feta'; CAVA always renders it 'Crazy Feta®'. Trademarked signature item, shown with the ® everywhere including the builder chips.
- cava.sides.pita-chips — we say 'Pita Chips'; the board and builder say 'Classic Pita Chips' (needed to distinguish from Harissa BBQ Pita Chips).
- cava.sides.whisked-apricot-honey — we say 'Whisked! Apricot Honey'; the builder says 'Apricot Honey Cookie'. The 'Whisked!' brand name is not shown to customers.
- cava.sides.whisked-dark-chocolate — we say 'Whisked! Salted Dark Chocolate Oat Cookie'; the board and builder both say 'Salted Chocolate Oat Cookie' (no 'Dark', no 'Whisked!').
- Format names in cava.formats.json don't match the board: ours are 'Grain Bowl' / 'Greens + Grains' / 'Salad' / 'Pita'; CAVA's are 'GRAINS BOWL' / 'GREENS + GRAINS BOWL' / 'SALAD BOWL' / 'PITA'. Note 'Grains' is plural and both bowls carry the word 'BOWL'.
- Minor: the Grains Bowl blurb on cava.com/menu describes the grain as 'brown basmati rice' while the builder chip and the nutrition PDF both say 'Brown Rice'. Our 'Brown Rice' matches what a customer actually sees on the line, so no change needed — noting it only so a future reviewer doesn't 'fix' it.

---

## Chick-fil-A — NEEDS_WORK

### How you actually order

CONFIDENCE CAVEAT FIRST: I could not drive order.chick-fil-a.com. It is a JS SPA behind a browser-compat gate, its API (commerce.api.my.chick-fil-a.com) needs auth and a selected restaurant, and browser automation requires a user-selection step I cannot perform as a subagent. The sequence below is reconstructed from Chick-fil-A's own board/category ordering, its published meal SKUs, and its modifier tables — not from watching the app. Treat the ITEM-LEVEL step order as medium confidence; everything else in this audit is high.

Chick-fil-A has NO line. Nobody walks past stations. It is a single order-taker (counter, drive-thru iPad, or app) asking a short question tree, and the whole flow is entrée-first, sauce-last:

1. Daypart is decided FOR you, not by you. Breakfast runs until 10:30am and then the entire breakfast menu vanishes and is replaced by the lunch menu. You never see both. This is the first and hardest fork.
2. "What can I get for you?" -> ENTRÉE. One item. Sandwich, nuggets, strips, wrap, or salad — salads are a peer choice at this same step, not a later station.
3. Immediately: entrée MODIFIERS, asked as one follow-up ("anything on that?"). This is where bun swaps, no-butter, cheese choice, add bacon, and protein substitutions happen. On a Hash Brown Scramble Bowl/Burrito or a salad this step is mandatory and explicit — they must ask which meat.
4. "Would you like to make that a meal?" A Meal is a fixed bundle: entrée + side + drink, sold as its own SKU (itemTag CFA_SANDWICH_MEAL). If yes, you then pick the SIDE (waffle fries is the default assumption; swapping to fruit/mac/kale is free or small upcharge) and then the DRINK.
5. If no meal, sides are still offered à la carte.
6. "What sauce would you like?" — SAUCE IS ALWAYS THE LAST FOOD QUESTION, asked of essentially every order, and they hand you multiples on request. This is the single most macro-significant question at Chick-fil-A and it is asked after everything else.
7. Treats/dessert offered as the closer ("anything else? a cookie?").
8. Pay. "My pleasure."

Salads are a full parallel branch: choosing a salad silently pre-loads a specific dressing packet AND a specific chicken, and the questions become "which chicken?" and "keep the dressing or swap it?" rather than "which side?".

### Sizes

Chick-fil-A runs THREE unrelated size systems and our menu flattens all of them into loose rows.

(a) Named tiers Small / Medium / Large on the scoopable sides: Waffle Fries (S/M/L), Fruit Cup (S/M/L), Mac & Cheese (S/M only — there is no large), Hash Browns (S/L only — there is no medium). Medium is the default everywhere it exists; the marketing deep-link for fries is literally itemTag=MD_WAFFLE_POTATO_FRIES. On the board the size word comes FIRST: 'Large Chick-fil-A Waffle Potato Fries', not 'Waffle Fries (large)'.

(b) Cup / Bowl on soup only. Chicken Noodle Soup is 'Cup of…' or 'Bowl of…'. Cup is default.

(c) Piece counts on the chicken, which is the system that actually matters here. Nuggets 5/8/12/30, Grilled Nuggets 5/8/12/30, Chick-n-Strips 2/3/4/10, Chick-n-Minis 4/10. The count is spoken BEFORE the name — you say 'an 8-count' or 'a 12-count', and the board prints '8 ct Chick-fil-A Nuggets'. The 5-ct nugget counts exist only inside Kid's Meals, and the 2-ct strip likewise.

Everything else — sandwiches, wraps, salads, biscuits, parfaits, sauces, dressings — has exactly one size. Sauces are 1 oz cups; dressings are 2 oz packets. That split is real and our model already gets it right.

- **Chick-fil-A Waffle Potato Fries** — default Medium: S (`chick-fil-a.sides.waffle-potato-fries-small`), M (`chick-fil-a.sides.waffle-potato-fries-medium`), L (`chick-fil-a.sides.waffle-potato-fries-large`)
- **Fruit Cup** — default Medium: S (`chick-fil-a.sides.fruit-cup-small`), M (`chick-fil-a.sides.fruit-cup-medium`), L (`chick-fil-a.sides.fruit-cup-large`)
- **Mac & Cheese** — default Medium: S (`chick-fil-a.sides.mac-and-cheese-small`), M (`chick-fil-a.sides.mac-and-cheese`)
- **Hash Browns** — default Small: S (`chick-fil-a.sides.hash-browns`), L (`chick-fil-a.sides.hash-browns-large`)
- **Chicken Noodle Soup** — default Cup: Cup (`chick-fil-a.sides.chicken-noodle-soup`), Bowl (`chick-fil-a.sides.chicken-noodle-soup-bowl`)
- **Chick-fil-A Nuggets** — default 8 ct: 8 ct (`chick-fil-a.entrees.chick-fil-a-nuggets-8-ct`), 12 ct (`chick-fil-a.entrees.chick-fil-a-nuggets-12-ct`), 30 ct (`chick-fil-a.entrees.chick-fil-a-nuggets-30-ct`)
- **Grilled Nuggets** — default 8 ct: 8 ct (`chick-fil-a.entrees.grilled-nuggets-8-ct`), 12 ct (`chick-fil-a.entrees.grilled-nuggets-12-ct`), 30 ct (`chick-fil-a.entrees.grilled-nuggets-30-ct`)
- **Chick-fil-A Chick-n-Strips** — default 3 ct: 2 ct (`chick-fil-a.entrees.chick-n-strips-2-ct`), 3 ct (`chick-fil-a.entrees.chick-n-strips-3-ct`), 4 ct (`chick-fil-a.entrees.chick-n-strips-4-ct`), 10 ct (`chick-fil-a.entrees.chick-n-strips-10-ct`)
- **Chick-fil-A Chick-n-Minis** — default 4 ct: 4 ct (`chick-fil-a.breakfast.chick-n-minis-4-ct`), 10 ct (`chick-fil-a.breakfast.chick-n-minis-10-ct`)

### House configurations

- **The bun is buttered — you have to ask for it not to be** — ON by default. Chick-fil-A's classic white bun is brushed with butter spread and toasted on a flat-top before the filet goes on. It is not a topping, it is a prep step, so no item-level nutrition line ever mentions it. Asking for 'no butter' is the single most common macro-relevant Chick-fil-A modification and it is a real SKU: Chick-fil-A publishes 'Buttery White Bun' at 180 cal and 'White Bun (Unbuttered)' at 150 cal as two separate lines in its own Buns table. Those two lines only exist because the unbuttered build is orderable. Net -30 cal / -3g fat on any classic-bun sandwich. Note the Grilled Chicken Sandwich is NOT affected — it ships on a Multigrain Brioche Bun (210 cal, honey in the dough, no butter), which is why it lands at 11g fat.
  - maps to: `chick-fil-a.entrees.chick-fil-a-chicken-sandwich`, `chick-fil-a.entrees.spicy-chicken-sandwich`, `chick-fil-a.entrees.chick-fil-a-deluxe-sandwich`, `chick-fil-a.entrees.spicy-deluxe-sandwich`
  - **gap:** Buttery White Bun (180 cal, 5g protein, 60g) — the default
  - **gap:** White Bun (Unbuttered) (150 cal, 5g protein, 54g) — the 'no butter' swap
  - **gap:** Multigrain Brioche Bun (210 cal, 7g protein) — default on the Grilled Chicken Sandwich
  - **gap:** Gluten Free Bun (180 cal, 3g protein) — a real orderable swap
  - **gap:** No bun at all (filet only) — the standard low-carb order
- **Cool Wrap arrives with Avocado Lime Ranch already inside it** — ON by default. The Cool Wrap is not dressed at the table — the dressing is built into the wrap and is already counted in the 660 cal board number. Chick-fil-A's Cool Wrap page confirms the total includes Avocado Lime Ranch. This is a live correctness bug in our data: our chick-fil-a.json notes explicitly flag that they were unsure and shipped 660 'as served' without decomposing, warning that a user who adds a dressing will double-count. That uncertainty is now resolved — the dressing IS in the 660, and the dressing-free wrap is 350/42/29/13. Either decompose it into wrap-base + dressing, or hard-suppress the dressings station whenever the Cool Wrap is selected.
  - maps to: `chick-fil-a.entrees.chick-fil-a-cool-wrap`, `chick-fil-a.dressings.avocado-lime-ranch-dressing`
  - **gap:** Cool Wrap base with no dressing (350 cal / 42g protein / 29g carb / 13g fat) — needed so the dressing can be swapped or declined without double-counting
- **Every salad ships with one specific dressing packet, and it is a different one per salad** — ON by default. A nutrition PDF lists dressings as a separate category, which makes them look optional. They are not. Each salad comes with a designated packet already counted in the board calorie figure, and you get that one unless you name a different one: Cobb -> Avocado Lime Ranch (310), Market -> Zesty Apple Cider Vinaigrette (230), Spicy Southwest -> Creamy Salsa (290), Side Salad -> Avocado Lime Ranch (310). The Side Salad is the trap: the board says 'Side Salad, 470 Cal' — that is 160 cal of salad plus a 310 cal dressing packet, i.e. two-thirds of the item is dressing. Cobb additionally includes Crispy Bell Peppers (80 cal) in its 830.
  - maps to: `chick-fil-a.mains.cobb-salad-base`, `chick-fil-a.mains.market-salad-base`, `chick-fil-a.sides.side-salad`, `chick-fil-a.dressings.avocado-lime-ranch-dressing`, `chick-fil-a.dressings.zesty-apple-cider-vinaigrette`
  - **gap:** Spicy Southwest Salad base — the salad itself is missing from our menu entirely
  - **gap:** Creamy Salsa Dressing (290 cal) — the Spicy Southwest default
  - **gap:** Crispy Bell Peppers (80 cal) — bundled into Cobb's published 830
- **Salads and scramble bowls make you choose the protein, and the default is different for each** — ON by default. This is a mandatory spoken question at the counter that no nutrition summary surfaces, and the macro swing is enormous. Cobb defaults to fried Nuggets (830); switching to Grilled Nuggets drops it to 630 — a 200 cal / ~22g fat delta from one word. Market and Spicy Southwest default to a COLD grilled filet, and 'warm' is a separate free ask. On the Hash Brown Scramble Bowl/Burrito the order-taker MUST ask which meat: Nuggets (default), Sausage, Grilled Filet, Spicy Chicken, Bacon, or No Meat — and each of those again in a 'no hash browns' build. The macro-tracker's order at Chick-fil-A breakfast is 'scramble bowl, grilled filet, no hash browns' = 270 cal, versus the 470 default we ship. We currently hardcode only the default nugget build for both bowl and burrito, and only the default chicken for both salads.
  - maps to: `chick-fil-a.mains.cobb-salad-base`, `chick-fil-a.mains.market-salad-base`, `chick-fil-a.breakfast.hash-brown-scramble-bowl`, `chick-fil-a.breakfast.hash-brown-scramble-burrito`, `chick-fil-a.entrees.grilled-filet`
  - **gap:** Chick-fil-A Filet (250 cal, 24g protein) — the fried filet as a swappable component
  - **gap:** Spicy Filet (280 cal, 23g protein)
  - **gap:** Sausage (240 cal, 11g protein)
  - **gap:** Bacon (50 cal, 4g protein)
  - **gap:** Grilled Breakfast Filet (60 cal, 13g protein)
  - **gap:** Chick-fil-A Breakfast Filet (160 cal, 15g protein)
  - **gap:** Spicy Breakfast Filet (150 cal, 15g protein)
  - **gap:** All 22 non-default Hash Brown Scramble Bowl/Burrito builds, especially the six 'no hash browns' variants
  - **gap:** Cold vs Warm grilled filet on salads
- **Deluxe means lettuce + tomato + cheese, and the default cheese is different on each sandwich** — ON by default. 'Deluxe' is not a distinct recipe, it is a modifier bundle bolted onto the base sandwich — and which cheese you silently get depends on which Deluxe you ordered. Chick-fil-A Deluxe defaults to American (490). Spicy Deluxe defaults to Pepper Jack (540). Grilled Chicken Club defaults to Colby Jack (520). Every one of them can be ordered with any of the three cheeses or with No Cheese, which is a clean -50 to -80 cal. Colby Jack and Pepper Jack are 80 cal each versus American at 50, so the same word 'deluxe' means a 30-cal difference depending on the sandwich. Also worth noting: the Grilled Chicken Club is the only sandwich with bacon built in.
  - maps to: `chick-fil-a.entrees.chick-fil-a-deluxe-sandwich`, `chick-fil-a.entrees.spicy-deluxe-sandwich`, `chick-fil-a.entrees.grilled-chicken-club-sandwich`, `chick-fil-a.entrees.chick-fil-a-chicken-sandwich`, `chick-fil-a.entrees.spicy-chicken-sandwich`
  - **gap:** American Cheese (50 cal, 3g protein)
  - **gap:** Colby Jack Cheese (80 cal, 5g protein)
  - **gap:** Pepper Jack Cheese (80 cal, 4g protein)
  - **gap:** Bacon (50 cal, 4g protein) — addable to any sandwich
  - **gap:** Lettuce (5 cal), Tomato (5 cal)
  - **gap:** 'No Cheese' as a subtractive option on all three deluxe-tier sandwiches
- **Sauce quantity — the regular takes two, and two Chick-fil-A Sauces out-fat the nuggets**. Sauce is free, always offered, and handed out in multiples without argument; the counter script ends with 'what sauce would you like?' on essentially every order. The convention is one sauce per entrée minimum and two is normal, and the house move is either two Chick-fil-A Sauces or a Chick-fil-A Sauce plus a Polynesian for mixing. This is the biggest silently-untracked number at Chick-fil-A: one Chick-fil-A Sauce is 140 cal / 13g fat, so two of them (280 cal / 26g fat) carry MORE calories and more than double the fat of the 8-ct Nuggets (250 cal / 11g fat) they are dipping. Our dips category exists and is selectMany, which is right — but the gap is QUANTITY. A builder that can only add one of each sauce cannot express the actual normal order.
  - maps to: `chick-fil-a.dips.chick-fil-a-sauce`, `chick-fil-a.dips.polynesian-sauce`, `chick-fil-a.dips.barbeque-sauce`, `chick-fil-a.dips.honey-mustard-sauce`, `chick-fil-a.entrees.chick-fil-a-nuggets-8-ct`, `chick-fil-a.entrees.chick-fil-a-nuggets-12-ct`
  - **gap:** A per-sauce quantity stepper (x1 / x2 / x3) — the single highest-value UI fix on this menu
  - **gap:** Ketchup — stocked and given on request, not in Chick-fil-A's published sauce list
- **Fried Chicken Club — swapping the grilled filet for the fried one**. A long-standing off-menu order at most locations: the Grilled Chicken Club built with the original breaded Chick-fil-A Filet instead of the grilled filet. Real macro change — Chick-fil-A Filet is 250 cal / 24g protein against Grilled Filet at 110 cal / 21g protein, so roughly +140 cal on the same sandwich. Same trick runs in reverse: any fried sandwich can be built on the grilled filet.
  - maps to: `chick-fil-a.entrees.grilled-chicken-club-sandwich`, `chick-fil-a.entrees.grilled-filet`
  - **gap:** Chick-fil-A Filet (250 cal, 24g protein) as a swap-in component
  - **gap:** Spicy Filet (280 cal, 23g protein) as a swap-in component
- **Buffalo Chicken Sandwich and the Spicy Chicken, Egg & Cheese Biscuit — orderable but unlisted**. Two builds that are always available and never printed. (1) Buffalo Chicken Sandwich: a Spicy Chicken Sandwich with Zesty Buffalo Sauce spread inside rather than served on the side (+25 cal / +2.5g fat). (2) Spicy Chicken, Egg & Cheese Biscuit: the same as the Chicken, Egg & Cheese Biscuit but with the spicy breakfast filet — omitted from most menu boards purely for space, and made on request everywhere. Roughly 540 cal by substitution (Spicy Breakfast Filet 150 vs Chick-fil-A Breakfast Filet 160).
  - maps to: `chick-fil-a.entrees.spicy-chicken-sandwich`, `chick-fil-a.dips.zesty-buffalo-sauce`, `chick-fil-a.breakfast.chicken-egg-cheese-biscuit`, `chick-fil-a.breakfast.spicy-chicken-biscuit`
  - **gap:** Spicy Chicken, Egg & Cheese Biscuit as its own item
  - **gap:** Spicy Breakfast Filet (150 cal, 15g protein) as a swap-in component
- **Berry Parfait — granola or cookie crumbs is a question you get asked** — ON by default. The parfait topping is a choice made at order time, not a fixed recipe. Harvest Nut Granola (the 270 cal default) or chocolate cookie crumbs (240 cal). Small delta but it is a real spoken question and our single 270-cal item can't express it.
  - maps to: `chick-fil-a.breakfast.berry-parfait`
  - **gap:** Berry Parfait w/ Cookie Crumbs (240 cal)
  - **gap:** Harvest Nut Granola (70 cal) as a standalone topping

### Station order

Mostly right on the spine, wrong in three specific places.

Our category order is: entrees -> mains (Salads) -> breakfast -> sides -> dips -> dressings.
Chick-fil-A's own board order is: Breakfast -> Entrées -> Salads -> Sides -> Kid's Meals -> Family Style Meals -> Treats -> Beverages -> Dipping Sauces & Dressings -> Coffee.

WHAT WE GET RIGHT: entrée before sides before sauces. That genuinely matches the counter — sauce really is the last food question asked, and our dips/dressings sitting at the end is correct. Salads as a peer of entrées is also correct.

WHAT SHOULD MOVE:

1. BREAKFAST IS IN THE WRONG PLACE AND IS THE WRONG SHAPE. It currently sits third, between Salads and Sides, as if it were a mid-order station. It is not a station at all — it is a mutually exclusive daypart that ends at 10:30am and swaps the entire menu. Nobody is ever offered a biscuit after a sandwich. Either promote it to a daypart toggle above the whole builder, or drop it from the browse order entirely and let the existing 'breakfast' format own it. Leaving it inline invites nonsense builds like Spicy Deluxe + Sausage Biscuit.

2. THERE IS NO MODIFIER STEP, AND THAT IS THE BIGGEST STRUCTURAL GAP. At Chick-fil-A the question immediately after the entrée is 'anything on that?' — bun swap, no butter, which cheese, which meat in your scramble bowl, which chicken on your salad. Loadout jumps straight from entrée to sides. Chick-fil-A publishes four whole modifier tables (Buns, Proteins, Sandwich Toppings, Salad Toppings) precisely because this step exists, and we model none of it. A modifier step belongs between the entrée prompt and the sides prompt.

3. TREATS HAS NO STATION AT ALL. On the board it sits right after Sides and before Dipping Sauces, and at the counter it is the closer ('anything else?'). We have zero treat items — no Chocolate Chunk Cookie, no Brownie, no Icedream. Add a treats category positioned after sides and before dips.

4. MINOR: dips and dressings are ONE section on the board ('Dipping Sauces & Dressings'). Ours are two adjacent categories, which is fine functionally, but dressings must be conditionally suppressed — hidden entirely on a Cool Wrap (dressing already inside), and pre-filled rather than empty on a salad.

5. NOT A GAP, JUST NOTE: 'Make it a Meal' (entrée + side + drink, a real bundled SKU) is a step we deliberately skip because drinks are out of scope per the food-only rule. That is the right call; just don't let the sides prompt read as optional garnish when in the real flow it's the meal-upgrade branch.

### Missing staples

- Spicy Southwest Salad — a permanent, currently-listed salad and one of only three Chick-fil-A sells. We ship Cobb and Market and omit it entirely. 680 cal as served with its default Creamy Salsa Dressing.
- Chicken, Egg & Cheese Muffin (410 cal) — permanent breakfast item on the current board
- Bacon, Egg & Cheese Muffin (300 cal) — permanent; also the leanest hot breakfast sandwich Chick-fil-A sells after the Egg White Grill, so it matters for this app's audience
- Sausage, Egg & Cheese Muffin (490 cal) — permanent
- Chocolate Chunk Cookie (370 cal) — we have no treats/dessert category at all
- Chocolate Fudge Brownie (370 cal)
- Chick-fil-A Icedream Cone (180 cal)
- Chick-fil-A Icedream Cup (140 cal)
- Creamy Salsa Dressing (290 cal) — one of seven current dressings, and the default on the Spicy Southwest Salad
- Garden Herb Ranch Dressing (280 cal, 2 oz packet) — distinct from the 1 oz Garden Herb Ranch Sauce we already have
- Fat-Free Honey Mustard Dressing (90 cal) — one of only two low-cal dressings, directly relevant to macro trackers
- Light Balsamic Vinaigrette Dressing (80 cal) — likewise. We ship 3 of Chick-fil-A's 7 dressings.
- Chick-fil-A Sauce Flavored Waffle Potato Chips (210 cal) — permanent side, sits next to the Original Flavor bag we do have
- Buddy Fruits Apple Sauce (45 cal) — permanent side, the standard kid's/light swap
- 5 ct Chick-fil-A Nuggets (160 cal) and 5 ct Grilled Nuggets (80 cal) — the Kid's Meal counts. Adults order them constantly as the small portion.
- 2 ct Chick-n-Strips (200 cal) — we do have this one; noting only that its Kid's Meal framing should be visible
- Buttery Biscuit (290 cal) — sold on its own, the classic cheap breakfast add
- English Muffin (140 cal) and 4 ct Mini Yeast Rolls (240 cal) — the 'Breakfast Breads' section, all à la carte
- Chicken Tortilla Soup (280 cal) — appears in Chick-fil-A's nutrition data but NOT on the current /menu/sides board, so this one may be seasonal or being phased out. Lower confidence than the rest of this list; verify before adding.
- Saltines (50 cal) — the cracker packet that comes with soup, published as a 'Soup Topping'
- Standalone salad toppings sold as adds: Seasoned Tortilla Strips (70), Chili Lime Pepitas (80), Crispy Bell Peppers (80), Blue Cheese Crumbles (30), Roasted Nut Blend (70), Harvest Nut Granola (70)
- DELIBERATELY EXCLUDED, not a gap: all Frosted Lemonades, milkshakes, Frosted Coffees and floats. They live under 'Treats' on Chick-fil-A's board but are drinks, and the project rule is food-only outside Starbucks. Flagging so nobody 'fixes' this later.
- ALSO EXCLUDED, correctly: Honey Pepper Pimento Sandwich (600/620/450) and Jalapeño Ranch Club. Chick-fil-A's own page says 'available for a limited time at participating locations while supplies last' — LTOs, out of scope.

### Naming

- 'Side Salad (no dressing)' at 160 cal vs the board's 'Side Salad — 470 Cal'. A user standing at the counter reads 470 and concludes our app is broken. Same problem on 'Cobb Salad (no dressing)' (ours 520, board 830) and 'Market Salad (no dressing)' (ours 320, board 550). The '(no dressing)' suffix is a data-model artifact leaking into the UI — no board, receipt, or human ever says it. Name them 'Cobb Salad' / 'Market Salad' / 'Side Salad' and let the pre-attached dressing carry the difference visibly.
- Size labels are backwards from the board. We write 'Chick-fil-A Waffle Potato Fries (small)'; Chick-fil-A prints 'Small Chick-fil-A Waffle Potato Fries'. Same on 'Mac & Cheese (small)', 'Hash Browns (large)', 'Fruit Cup (small)'. Size goes first. This disappears if the size-picker collapse happens.
- Counts are backwards too. We write 'Chick-fil-A Nuggets (8 ct)'; the board prints '8 ct Chick-fil-A® Nuggets' and people say 'an 8-count' or 'a 12-count of nuggets'. Applies to all nuggets, grilled nuggets, strips and minis.
- 'Chick-fil-A Waffle Potato Fries' is nobody's spoken name. Every customer and every employee says 'waffle fries'. The trademarked mouthful is board-only.
- 'Chick-fil-A Waffle Potato Fries' (the medium, id waffle-potato-fries-medium) carries no size word at all while its siblings do. So the list shows 'Chick-fil-A Waffle Potato Fries', '…(small)', '…(large)' — the default is the one item you can't identify by size.
- 'Chick-fil-A Grilled Chicken Club' drops the trailing word. The board is 'Chick-fil-A® Grilled Chicken Club Sandwich'. Spoken, it's just 'the grilled club'.
- 'Chicken Noodle Soup' for the cup and 'Chicken Noodle Soup (bowl)' for the bowl. The board says 'Cup of Chicken Noodle Soup' and 'Bowl of Chicken Noodle Soup' — cup is an explicit word, not an implied default.
- 'Grilled Filet' is listed as an ENTRÉE but is not on the entrée board anywhere. Chick-fil-A publishes it in the 'Proteins' modifier table — it's a substitution component, not something you can point at and order. Keeping it is fine (it's the standard no-bun order) but it should read as 'Grilled Filet (no bun)' or live in a components/modifier group, not sit between the Cool Wrap and the nuggets as if it were a menu item.
- 'Chick-fil-A Cool Wrap' — the board prints the registered mark after 'Wrap' ('Chick-fil-A Cool Wrap®') and everyone just says 'Cool Wrap'. More importantly the name gives no hint that the dressing is already inside, which is the thing a user needs to know before they reach the dressings station.
- 'Original Flavor Waffle Potato Chips' matches the board exactly, but the qualifier 'Original Flavor' only makes sense next to the 'Chick-fil-A® Sauce Flavored' bag — which we don't carry. On its own it reads like a typo.
- 'Chick-fil-A Chick-n-Strips (3 ct)' — the board name carries a registered mark on 'Strips' ('Chick-fil-A Chick-n-Strips®') and, in the Trays section, Chick-fil-A itself uses a ™ on 'Chick-n-Strips™'. Minor, but our name is the only one in the file that drops trademark treatment inconsistently vs. the sandwich names, which keep 'Chick-fil-A'.
- Category label 'Salads' (id 'mains') contains only 2 of the 3 salads, and the Side Salad correctly lives under 'sides'. That split is right, but the label 'Salads' promising the full set while showing two of three will read as a bug once Spicy Southwest is added — make sure it lands in 'mains', not 'sides'.
- Our 'Dipping Sauces' and 'Salad Dressings' are two categories; the board has one section titled 'Dipping Sauces & Dressings'. Not worth merging, but worth knowing that a user looking for 'ranch' will find TWO different things (Garden Herb Ranch Sauce, 1 oz / 100 cal, and Garden Herb Ranch Dressing, 2 oz / 280 cal) — and we currently stock only the sauce, so a user who wants ranch on a salad will pick the wrong one.

---

## Chipotle — NEEDS_WORK

### How you actually order

TWO DIFFERENT SEQUENCES, and they disagree — Loadout should pick one deliberately.

IN STORE (the physical line, one server hands you off to a second):
1. "What can I get for you?" — you name the FORMAT first: burrito / bowl / tacos / salad. (Quesadilla is NOT orderable here — the menu grid badges it "DIGITAL ONLY".)
2. Tortilla comes off the warmer/press if it's a burrito or tacos. For a bowl you're asked nothing.
3. Rice — "white or brown?"
4. Beans — "black or pinto?"
5. Protein — "chicken, steak, barbacoa, carnitas, sofritas, or veggie?" Fajita veggies live in the same hot well and are offered here.
6. Handoff to the cold line.
7. Salsas — mild / corn / medium / hot, asked as a group.
8. Sour cream, cheese, then lettuce — in that order, lettuce last.
9. Guacamole / queso — the paid add-ons, asked last because they ring up.
10. Register: chips, chips-and-dip combos, sides, tortilla on the side, drinks.

DIGITAL (chipotle.com and the app — verified live today, identical on burrito, bowl and salad):
1. Pick the entrée format from a 9-tile grid.
2. **Protein or Veggie** (required) — Chipotle Honey Chicken [Limited Time], Chicken, Steak, Beef Barbacoa, Carnitas, Sofritas [Plant-Based Protein], Veggie [Includes Guacamole, 0 cal]. NO Carne Asada.
3. **Rice** (required) — White Rice / Brown Rice / **No Rice**.
4. **Beans** (required) — Black Beans / Pinto Beans / **No Beans**.
5. **Top Things Off** — ONE flat station holding Cilantro Lime Sauce [new], Guacamole, Fresh Tomato Salsa [Mild], Roasted Chili-Corn Salsa [Medium], Tomatillo-Green Chili Salsa [Medium], Tomatillo-Red Chili Salsa [Hot], Sour Cream, Fajita Veggies, Cheese, Romaine Lettuce, Queso Blanco. Salsas and toppings are NOT separate steps online.
6. **Options** (burrito only) — Double Wrap with Tortilla, 320 cal.
7. **Chips & Dips** — Chips, Chips & Guacamole, Large Chips, Large Chips & Large Guacamole, Chips & Fresh Tomato Salsa, Chips & Tomatillo-Red, Chips & Tomatillo-Green, Chips & Roasted Chili-Corn, Chips & Queso Blanco, Large Chips & Large Queso Blanco.
8. **Single Sides** — Side/Large Side of Cilantro Lime Sauce, Side/Large Side of Guacamole, Side/Large Side of Queso Blanco, **Tortilla on the Side (320 cal)**, Large Fresh Tomato / Large Tomatillo-Red / Large Tomatillo-Green / Large Roasted Chili-Corn Salsa.
9. **High Protein Cups** — Side of Chicken (180 cal, 32 g), Side of Steak (150 cal, 21 g), Side of Chipotle Honey Chicken.

TACOS deviate: **Tortilla FIRST** (Crispy Corn Tortilla 200 cal / Soft Flour Tortilla 250 cal — priced as the set of three), then Protein, then **Included Toppings** (free: both rices, both beans, all four salsas, sour cream, fajita veggies, cheese, romaine, or "No Included Toppings"), then **Add-Ons** (paid: Cilantro Lime Sauce, Guacamole, Queso Blanco).

QUESADILLA deviates hard: Protein or Veggie (last option is "Cheese Only — Includes Guacamole"), then **Optional Add-Ins = Fajita Veggies and nothing else** — that is the ONLY thing that can go inside. Then **Included Sides** (rice, beans, four salsas, sour cream, Chipotle-Honey Vinaigrette — in cups), then **Add-Ons (Always On The Side)** — guac, queso, cilantro lime sauce.

The single biggest structural fact the flow teaches: Chipotle splits toppings into FREE (everything except three things) and PAID ADD-ONS (Guacamole, Queso Blanco, Cilantro Lime Sauce). Our menu treats all toppings as one undifferentiated list.

### Sizes

Chipotle entrées have NO sizes. A burrito, bowl, salad, quesadilla or 3-taco order comes exactly one way and portion is a scoop, not a size tier — there is no Small/Medium/Large anywhere in the entrée builders. Size only exists on the sides-and-dips half of the menu, expressed as bare-name vs. "Side of…" vs. "Large…": Chips vs Large Chips; Guacamole (in-entrée / Side, 4 oz) vs Large Side of Guacamole (8 oz); Queso Blanco (in-entrée, 2 oz) vs Side of Queso Blanco (4 oz) vs Large Side of Queso Blanco (8 oz); and every salsa has a Large side variant. So the size picker belongs on dips and chips, never on the entrée.

- **Chips** — default Regular: Regular (`chipotle.chips.regular`), Large (`chipotle.chips.large`)
- **Guacamole** — default 4 oz: 4 oz (`chipotle.toppings.guacamole`), 8 oz (`chipotle.toppings.guacamole-large`)
- **Queso Blanco** — default 2 oz: 2 oz (`chipotle.toppings.queso-entree`), 4 oz (`chipotle.toppings.queso-side`), 8 oz (`chipotle.toppings.queso-large`)

### House configurations

- **Bowl + Tortilla on the Side**. Order a Burrito Bowl, then ask for a warm flour burrito tortilla on the side and wrap it yourself. The single most-repeated Chipotle ordering convention — the reason being that bowls get scooped more generously than burritos. Chipotle has since productized it: "Tortilla on the Side, 320 cal" is a real SKU under Single Sides in every builder (it is a paid side, not free, despite the folklore).
  - maps to: `chipotle.tortilla.flour-burrito`
  - **gap:** A "Tortilla on the Side" side item that can be added to a Bowl or Salad. Our tortilla category is only reachable from the burrito/tacos formats, so a bowl build physically cannot add it — the #1 real-world Chipotle order is unbuildable in Loadout.
- **Double Wrap with Tortilla**. A second flour tortilla wrapped around the outside of the burrito so it doesn't blow out. Historically a secret-menu ask; it is now an official step — the burrito builder has an entire "Options" station whose only entry is "Double Wrap with Tortilla, 320 cal". Macro effect is exactly one more burrito tortilla: +320 cal / +8 g P / +50 g C / +9 g F.
  - maps to: `chipotle.tortilla.flour-burrito`
  - **gap:** A quantity-2 (or a "double wrap" toggle) on the burrito tortilla. Our burrito format auto-adds exactly 1 tortilla and exposes no tortilla prompt at all, so this is unreachable.
- **Double protein / "double meat"**. Two scoops of protein in one entrée. It is the most-discussed modifier in the entire subreddit and Chipotle has now productized it as the "High Protein Cups" station (Side of Chicken 180 cal / 32 g, Side of Steak 150 cal / 21 g) and a "Double High Protein Bowl" on the High Protein Menu. Macro effect is a clean 2× on the protein row.
  - maps to: `chipotle.protein.chicken`, `chipotle.protein.steak`, `chipotle.protein.barbacoa`, `chipotle.protein.carnitas`, `chipotle.protein.sofritas`
  - **gap:** A ×2 quantity control on the protein pick — our protein category is selectMany with no quantity, so "double chicken" is expressible only by an awkward duplicate.
  - **gap:** "Side of Chicken" / "Side of Steak" as standalone High Protein Cup sides (same macros as the 4 oz scoop, but orderable as an add-on side rather than as the entrée's protein).
- **Half-and-half**. Standard counter vocabulary: "half white, half brown" on rice, "half black, half pinto" on beans, or "half chicken, half steak" on protein. Macro effect is 0.5× of each of two items, NOT 1× of both — getting this wrong overstates the entrée by a full scoop.
  - maps to: `chipotle.rice.cilantro-lime-white`, `chipotle.rice.cilantro-lime-brown`, `chipotle.beans.black`, `chipotle.beans.pinto`, `chipotle.protein.chicken`, `chipotle.protein.steak`, `chipotle.protein.barbacoa`, `chipotle.protein.carnitas`
  - **gap:** Fractional (0.5×) quantities. Our rice/beans/protein categories are selectMany with binary on/off, so a user who picks both rices to represent half-and-half gets 420 cal instead of 210.
- **Extra rice / extra beans**. A second scoop of rice and/or beans, given free (unlike extra protein, guac or queso). The standing value tip in the sub. Macro effect is roughly 2× that row: extra white rice is +210 cal / +40 g carb, extra black beans is +130 cal / +8 g P / +22 g C.
  - maps to: `chipotle.rice.cilantro-lime-white`, `chipotle.rice.cilantro-lime-brown`, `chipotle.beans.black`, `chipotle.beans.pinto`
  - **gap:** A light / normal / extra portion control on rice and beans. "Light rice" is equally common among people tracking carbs and is equally unexpressible.
- **Veggie entrée (guacamole included free)** — ON by default. "Veggie" is a choice in the protein slot, not a topping — and it is the ONLY place guacamole is free. The builder card literally reads "VEGGIE / Includes Guacamole / 0 cal". So a veggie bowl silently carries +230 cal / +22 g fat that a nutrition PDF would never attribute to the protein line. Quesadilla has the same deal under the name "Cheese Only — Includes Guacamole".
  - maps to: `chipotle.veggies.fajita-vegetables`, `chipotle.toppings.guacamole`
  - **gap:** A "Veggie" (0 cal) entry in the protein category that auto-adds guacamole. We have no protein-slot item for it, so a vegetarian build in Loadout is "no protein selected" and quietly drops the free guac.
- **Vinaigrette on a bowl or burrito**. Chipotle-Honey Vinaigrette poured over a burrito bowl instead of a salad. The online builder deliberately hides it on non-salad formats, but it is one of the most-asked-for things at the counter and staff will usually do it. Macro effect is large for a "dressing": +220 cal / +18 g carb / +16 g fat, more than the guacamole's calories per fluid ounce.
  - maps to: `chipotle.dressing.chipotle-honey-vinaigrette`
  - **gap:** Vinaigrette availability on the burrito/bowl/tacos formats. Our chipotle.formats.json exposes the dressing category on "salad" only, which matches the app but not the counter. It also appears in the quesadilla's Included Sides.
- **Quesadilla comes deconstructed** — ON by default. Nothing goes inside a Chipotle quesadilla except cheese, protein and fajita veggies. Rice, beans, all four salsas, sour cream and the vinaigrette arrive as free "Included Sides" in cups; guac, queso and cilantro lime sauce are labelled "Add-Ons (Always On The Side)". Macro-relevant because a tracked quesadilla is really a quesadilla PLUS several side cups the eater may or may not finish — and because our quesadilla format currently lets you put lettuce and salsa inside.
  - maps to: `chipotle.veggies.fajita-vegetables`, `chipotle.rice.cilantro-lime-white`, `chipotle.rice.cilantro-lime-brown`, `chipotle.beans.black`, `chipotle.beans.pinto`, `chipotle.salsa.fresh-tomato`, `chipotle.salsa.roasted-corn`, `chipotle.salsa.tomatillo-green`, `chipotle.salsa.tomatillo-red`, `chipotle.toppings.sour-cream`, `chipotle.dressing.chipotle-honey-vinaigrette`
  - **gap:** An "Included Sides" step (free, pick a few, includes rice/beans/salsas/sour cream/vinaigrette) distinct from the in-quesadilla ingredients.
  - **gap:** The constraint that the quesadilla's only in-item add-in is fajita veggies — our format's optionalCategoryIds currently allows veggies, salsa and toppings inside.
- **Quesarito**. Off-menu: a full burrito build wrapped in a cheese quesadilla instead of a plain tortilla. Macro delta over a normal burrito is roughly one extra flour burrito tortilla plus a cheese portion (+430 cal / +14 g P / +51 g C / +17 g F). Availability is real but store- and rush-dependent; many locations refuse it at peak.
  - maps to: `chipotle.tortilla.flour-burrito`, `chipotle.toppings.cheese`
  - **gap:** A "Quesarito" format (burrito build + a second tortilla pressed with cheese as the wrapper).
- **Nachos**. Off-menu: chips as the base with a full bowl build dumped on top. Macros are simply a bowl plus a bag of chips (+540 cal / +73 g C / +25 g F for the regular size), but people log it as one dish and forget the chips.
  - maps to: `chipotle.chips.regular`, `chipotle.toppings.cheese`, `chipotle.beans.black`
  - **gap:** A "nachos" format that swaps the tortilla/bowl base for chips.

### Station order

Our order is tortilla → rice → beans → protein → veggies → salsa → toppings → dressing → chips.

Against the PHYSICAL LINE this is close — the real line is tortilla → rice → beans → protein → fajita veggies → salsas → sour cream → cheese → lettuce → guac → register. Four things should move:

1. SPLIT "veggies". It currently holds three things that live at opposite ends of the line. `chipotle.veggies.fajita-vegetables` is correct where it is (hot line, right after protein, before salsa). `chipotle.veggies.romaine` should move to the END of toppings — romaine is literally the last thing the cold-line server adds, after cheese. `chipotle.veggies.supergreens-mix` is not a station item at all; it is the salad's auto-added base and should be hidden from the veggies station entirely (the formats file already auto-adds it, so it appears twice today).

2. DELETE the "dressing" station. Chipotle has no dressing step. `chipotle.dressing.chipotle-honey-vinaigrette` sits inside "Top Things Off" on the salad builder and inside "Included Sides" on the quesadilla builder. Fold it into toppings and let the format decide visibility.

3. ADD a "Sides" station after chips. Right now `chips` is the terminal station and holds only two items. The real terminal region is three stations — Chips & Dips (the chips-plus-dip combos), Single Sides (Tortilla on the Side, side/large guac, side/large queso, side/large cilantro lime sauce, large salsas) and High Protein Cups (Side of Chicken, Side of Steak). This is where the #1 Chipotle order — bowl plus tortilla on the side — actually lives.

4. ADD a burrito-only "Options" step between toppings and chips for Double Wrap with Tortilla.

Against the DIGITAL FLOW the mismatch is bigger and you have to choose: online, PROTEIN IS ASKED FIRST, before rice and beans, on burrito, bowl and salad alike. Only tacos ask tortilla first. If Loadout is modelling the counter, keep protein where it is and note the divergence; if it is modelling the app, protein moves to position 1. Also note the app collapses our `veggies` + `salsa` + `toppings` + `dressing` into ONE station called "Top Things Off" — four of our nine stations are one screen online. Separately, the app splits that station by price into free items vs. paid Add-Ons (Guacamole, Queso Blanco, Cilantro Lime Sauce), a distinction our flat toppings list does not carry.

One real ordering-experience fact our formats file misses entirely: Quesadilla and Build-Your-Own are badged "DIGITAL ONLY" on the menu grid — you cannot order a quesadilla at the counter.

### Missing staples

- Tortilla on the Side — 320 cal, Single Sides. The single highest-value gap: the most common Chipotle order in the wild is a bowl with a tortilla on the side, and our tortilla category is unreachable from the bowl format.
- Veggie — 0 cal protein-slot choice that includes guacamole free. There is no vegetarian entrée path in our menu.
- Cheese Only — the quesadilla's equivalent 0 cal choice, also includes guacamole.
- Cilantro Lime Sauce — 80 cal in-entrée. A current add-on on every single builder (badged 'new', not 'Limited Time'), sitting alongside Guacamole and Queso Blanco as one of the three paid add-ons.
- Side of Cilantro Lime Sauce — 160 cal.
- Large Side of Cilantro Lime Sauce — 320 cal.
- Double Wrap with Tortilla — 320 cal, the burrito's entire 'Options' station.
- Side of Chicken — 180 cal / 32 g protein, High Protein Cups.
- Side of Steak — 150 cal / 21 g protein, High Protein Cups.
- Chips & Guacamole — 770 cal.
- Chips & Queso Blanco — 780 cal.
- Chips & Fresh Tomato Salsa — 565 cal.
- Chips & Roasted Chili-Corn Salsa — 620 cal.
- Chips & Tomatillo-Green Chili Salsa — 555 cal.
- Chips & Tomatillo-Red Chili Salsa — 570 cal.
- Large Chips & Large Guacamole — 1270 cal.
- Large Chips & Large Queso Blanco — 1290 cal.
- Large Fresh Tomato Salsa — 40 cal (large salsa side).
- Large Roasted Chili-Corn Salsa — 120 cal.
- Large Tomatillo-Green Chili Salsa — 45 cal.
- Large Tomatillo-Red Chili Salsa — 90 cal.
- Explicit 'No Rice' and 'No Beans' choices — the builder makes declining an affirmative, required selection rather than a skip. Matters because a keto/high-protein Chipotle regular's whole order is defined by them.
- Kid's Meal — a permanent top-level category on the order grid (lower priority for a macro app, but it is not an LTO).

### Naming

- chipotle.rice.cilantro-lime-white / -brown → the board, the app and every employee say 'White Rice' and 'Brown Rice'. Nobody has ever said 'cilantro-lime white rice' out loud at a Chipotle.
- chipotle.veggies.fajita-vegetables 'Fajita Vegetables' → the app and the sneeze-guard label both read 'Fajita Veggies'.
- chipotle.tortilla.flour-taco 'Flour Tortilla (taco)' → the taco builder calls it 'Soft Flour Tortilla' and prices it as the set of three (250 cal for 3). Our per-tortilla row (80 cal) will not match anything a customer sees.
- chipotle.tortilla.crispy-corn 'Crispy Corn Tortilla' → name is right, but the builder shows 200 cal because it is quoting all three shells. Same unit mismatch.
- chipotle.tortilla.flour-burrito 'Flour Tortilla (burrito)' → the burrito builder never asks about a tortilla at all; the only place this string appears to a customer is as 'Tortilla on the Side' (320 cal) or 'Double Wrap with Tortilla' (320 cal).
- chipotle.protein.barbacoa 'Barbacoa' → the app card reads 'Beef Barbacoa'. Minor, but the board name is the longer one.
- chipotle.protein.carne-asada 'Carne Asada' → NOT on the current menu. It does not appear in any of the five builders I read. It is a returning LTO, not a staple, and shipping it as a permanent protein will make the menu look stale. (The current LTO in that slot is 'Chipotle Honey Chicken', 210 cal, explicitly badged 'Limited Time'.)
- chipotle.toppings.queso-entree / -side / -large 'Queso Blanco (entrée)' / '(side)' / '(large side)' → board names are 'Queso Blanco', 'Side of Queso Blanco', 'Large Side of Queso Blanco'. The parenthetical style reads like a nutrition PDF, not a menu.
- chipotle.toppings.guacamole-large 'Guacamole (large side)' → board name is 'Large Side of Guacamole'.
- chipotle.chips.large 'Chips (large)' → board name is 'Large Chips'.
- chipotle.veggies.supergreens-mix 'Supergreens Salad Mix' → the ingredient is called 'Supergreens'; and it is not a pickable station item at all, it is the salad's implicit base. It appearing in a 'Veggies' station is a phantom.
- chipotle.salsa.tomatillo-green notes say 'Medium-hot' → the app labels BOTH Tomatillo-Green Chili Salsa and Roasted Chili-Corn Salsa as 'Medium'. Tomatillo-Red is the only 'Hot'.
- Salsa names generally → the board names are right, but what people SAY is 'mild' (fresh tomato), 'corn' (roasted chili-corn), 'medium' or 'green' (tomatillo-green), and 'hot' or 'red' (tomatillo-red). The heat word should be the searchable/spoken alias, not just a note field.
- Category 'Veggies' → no such station exists at Chipotle. Fajita veggies are a topping; romaine is a topping; supergreens is a salad base.
- Category 'Dressing' → no such station exists. The vinaigrette lives in 'Top Things Off' (salad) and 'Included Sides' (quesadilla).
- Category 'Chips' → the app calls the terminal region 'Chips & Dips', 'Single Sides' and 'High Protein Cups'.

---

## Moe's — NEEDS_WORK

### How you actually order

Moe's is a Chipotle-style line, but the question order is NOT Chipotle's. The single biggest difference: PROTEIN IS ASKED FIRST, not the base. The grill is the first station; you are greeted with "Welcome to Moe's!", you say the item, and the very next question is what meat. Every one of the 14 buildable products on moes.com puts the Protein group at seq 0 — burrito, bowl, stack, quesadilla, nachos, taco, salad, kids, all of them.

The verified sequence (group names are Moe's own, taken from the live itemModifierGroups payload; seq numbers are theirs):

[0] Protein — Steak, White Meat Chicken, Adobo Chicken, Ground Beef, Tofu, and an explicit "No Protein". (Brisket is currently a paid LTO.)
[1] "Modify Proteins:" → "Extra Meat:" — the double-protein upsell, asked immediately after the protein, at the same station, for a surcharge.
[2] Vessel/shell — only asked when it is a real choice. Tacos get "Taco Shell: Crispy Shell / Soft Shell - Flour". The Stack gets a Tortilla group with exactly one option (Flour Tortilla). Burritos/bowls/quesadillas never ask; the tortilla is implied by the item.
[2 or 3] Rice — Seasoned Rice (default) / Cilantro Lime Rice / No Rice. Mandatory group. NOT asked on the Stack, Quesadilla, Nachos, Salad or Tacos — on those, rice drops down into the free-toppings bar instead of being its own station.
[3] Beans — Black / Pinto / No Beans. Mandatory. Default flips by item: PINTO on the Custom Burrito and Jr. Burrito, BLACK on the Bowl, Homewrecker, Homewrecker Bowl, Stack, Quesadilla, Nachos and Salad.
[4] "Fresh Free Ingredients" — ONE station, one sneeze guard, ~13 free items, and this is where Moe's differs most from our model: Grilled Peppers and Onions, Roasted Corn Salsa, Shredded Cheese, Pico, Shredded Lettuce, Sour Cream, Diced Onions, Black Olive, Fresh Jalapeños, Pickled Jalapeños, Cilantro, Southwest Vinaigrette Dressing, Hard Rock & Roll Sauce. Cheese, salsa, veggies, sour cream, a dressing and a sauce all live in the same free pass. Moe's markets this as "over 20 free ingredients".
[5] "Sauce Choice" — a separate SINGLE-SELECT drizzle after the free bar: Moe's Sauce, Poblano Crema, Chili Lime Sauce, Chipotle Ranch — each also offered as an "…On Side" variant. Note that Hard Rock & Roll Sauce and Southwest Vinaigrette are NOT here; they're on the free bar. Salads insert a mandatory "Dressings (Served on Side)" step before this.
[6] "Add-Ons" — the paid ones, at the end: "Guacamole Inside Your Item", "Queso Inside Your Item", "Bacon Inside Your Item". Quesadillas insert a "Sides" step here (Pico on the Side, Sour Cream on the Side, both pre-checked).
[9 or 10] "Free Chips and Salsa" — a MANDATORY, last step on every single entree, pre-answered "Yes, I Want Free Chips and Salsa", with a sub-question "Salsa Choice": House Made Salsa (Red) [default] / Tomatillo (Green) / Spicy House Made Salsa (Spicy Red). You have to actively decline it.

Then the register: shareable Queso / Guac / Chips (Side, Cup or Bowl), drink, cookie. Kids meals append their own Kids Drink and Kids Dessert steps.

### Sizes

Moe's has no S/M/L for entrées and never asks a size question for a burrito or bowl. Size shows up three separate ways, and only one of them is a question the customer answers.

1. THE VESSEL sets the portion silently. Jr. Burrito, Burrito, Bowl and taco each pull a different rice and bean portion off the same pan — Seasoned Rice is 94 cal in a Jr., 150 in a burrito, 300 in a bowl. The customer says 'seasoned rice' once and never hears a portion. Our menu exposes all eight rice rows and all eight bean rows inside the same selectOne category, so on the Burrito format a user sees 'Seasoned Rice' (300 cal, bowl portion) sitting next to 'Seasoned Rice (burrito portion)' (150 cal) with nothing to tell them apart. Picking wrong doubles the carbs. This is the single worst modelling bug in the file.

2. PROTEIN TIERS: Small (tacos/kids), Medium (every entrée), Double. Nobody is asked which tier — it follows the item — with one exception: 'Extra Meat:' is a real, paid, asked-out-loud upsell at the grill, and that is the Double row.

3. A GENUINE Side / Cup / Bowl PICKER exists, but only for the three shareables: Moe's Famous Queso, Guacamole and Tortilla Chips. Moe's own product pages render these as a mandatory 'Queso Size' / 'Guacamole Size' group with Side pre-selected. That is the one place a size chip is honest UI.

Also derived, never asked: the flour tortilla. 12" = burrito, 8" = quesadilla/kids, 6" = taco. The only shell question at the counter is Crispy vs Soft, and only for tacos.

- **Seasoned Rice** — default Burrito: Jr (`moes.rice.seasoned-rice-jr-burrito`), Burrito (`moes.rice.seasoned-rice-burrito`), Bowl (`moes.rice.seasoned-rice`), Share Bowl (`moes.rice.seasoned-rice-bowl`)
- **Cilantro Lime Rice** — default Burrito: Jr (`moes.rice.cilantro-lime-rice-jr-burrito`), Burrito (`moes.rice.cilantro-lime-rice-burrito`), Bowl (`moes.rice.cilantro-lime-rice`), Share Bowl (`moes.rice.cilantro-lime-rice-bowl`)
- **Black Beans** — default Entrée: Taco / Jr (`moes.beans.black-beans-jr`), Entrée (`moes.beans.black-beans`), Cup (`moes.beans.black-beans-cup`), Bowl (`moes.beans.black-beans-bowl`)
- **Pinto Beans** — default Entrée: Taco / Jr (`moes.beans.pinto-beans-jr`), Entrée (`moes.beans.pinto-beans`), Cup (`moes.beans.pinto-beans-cup`), Bowl (`moes.beans.pinto-beans-bowl`)
- **Moe's Famous Queso** — default Side: Side (`moes.dips.queso-side`), Cup (`moes.dips.queso-cup`), Bowl (`moes.dips.queso-bowl`)
- **Guacamole** — default Side: Side (`moes.dips.guac-side`), Cup (`moes.dips.guac-cup`), Bowl (`moes.dips.guac-bowl`)
- **Tortilla Chips** — default Side: 1 Serving (`moes.chips.tortilla-chips-serving`), Side (`moes.chips.tortilla-chips-side`), Cup (`moes.chips.tortilla-chips-cup`), Bowl (`moes.chips.tortilla-chips-bowl`)
- **Adobo Chicken** — default Regular: Taco (`moes.protein.adobo-chicken-small`), Regular (`moes.protein.adobo-chicken`), Double (`moes.protein.adobo-chicken-double`)
- **White Meat Chicken** — default Regular: Taco (`moes.protein.white-meat-chicken-small`), Regular (`moes.protein.white-meat-chicken`), Double (`moes.protein.white-meat-chicken-double`)
- **Steak** — default Regular: Taco (`moes.protein.hand-cut-steak-small`), Regular (`moes.protein.hand-cut-steak`), Double (`moes.protein.hand-cut-steak-double`)
- **Ground Beef** — default Regular: Taco (`moes.protein.ground-beef-small`), Regular (`moes.protein.ground-beef`), Double (`moes.protein.ground-beef-double`)
- **Tofu** — default Regular: Taco (`moes.protein.tofu-small`), Regular (`moes.protein.tofu`), Double (`moes.protein.tofu-large`)
- **Queso Inside Your Item** — default Entrée: Taco (`moes.toppings.queso-add-on-small`), Entrée (`moes.toppings.queso-add-on`)
- **Guacamole Inside Your Item** — default Entrée: Taco (`moes.toppings.guacamole-add-on-small`), Entrée (`moes.toppings.guacamole-add-on`)
- **Flour Tortilla** — default 12": 12" (`moes.tortilla.flour-tortilla-12`), 8" (`moes.tortilla.flour-tortilla-8`), 6" (`moes.tortilla.flour-tortilla-6`)

### House configurations

- **Free Chips and Salsa (with every single entrée)** — ON by default. This is Moe's equivalent of "Mike's Way" and it is the biggest macro miss in our menu. Every entrée at Moe's comes with free chips and salsa. It is not a suggestion and not an optional side — on moes.com it is a MANDATORY modifier group named literally "Free Chips and Salsa" with mandatory:true, appended as the last step of the build on the Burrito, Homewrecker, Jr. Burrito, Bowl, Homewrecker Bowl, Stack, Quesadilla, Chicken Club Quesadilla, Nachos, One Taco, Three Tacos, Salad, Southwest Salad and Kids items. The pre-selected answer is "Yes, I Want Free Chips and Salsa"; you must actively pick "No, I Don't Want Free Chips and Salsa" to decline. It carries a sub-group "Salsa Choice" (also mandatory) defaulting to House Made Salsa (Red), with Tomatillo (Green) and Spicy House Made Salsa (Spicy Red) as alternates.

Critically, this is NOT in Moe's published calorie numbers. The Homewrecker's published baseCal is 810 and its component sum without chips is 805 — the chips are on top of every number the nutrition chart gives you. Anyone tracking a Moe's meal from the PDF alone is under-reporting by roughly a side of chips.
  - maps to: `moes.chips.tortilla-chips-side`, `moes.salsa.house-made-salsa`
  - **gap:** The free-with-entrée chips portion has no row of its own. 'Tortilla Chips, Side' (350 cal / 45C / 18F / 5P) is the smallest purchasable size and my best mapping; the 140-cal 'Tortilla Chips' ingredient row is the smaller candidate. Reverse-engineering the Jr. Burrito Moe Value Meal range (1030 base, minus Jr. Burrito 620, minus a 200-cal side of queso, minus a 0-cal base drink) leaves ~210 cal for chips+salsa, which sits between the two rows. Moe's does not publish the free scoop, so this needs a dedicated 'Chips & Salsa (with entrée)' item or an explicit portion assumption.
  - **gap:** A self-serve salsa bar refill — the red/green/spicy salsas are unlimited in-store, so the salsa component is effectively uncapped.
- **The Homewrecker (the default order)**. Moe's OG and the thing a regular actually says at the counter — "Homewrecker, steak". It is a fixed build, not a custom burrito, and its whole selling point is that GUACAMOLE IS INCLUDED FREE. On the Custom Burrito, "Guacamole Inside Your Item" is a $0.00-listed but non-default add-on; on the Homewrecker and Homewrecker Bowl it is isDefault:true. Build: 12" flour tortilla, protein, seasoned rice, black beans, shredded Oaxaca cheese, shredded romaine, pico, sour cream, guacamole — plus the free chips and salsa above.
  - maps to: `moes.tortilla.flour-tortilla-12`, `moes.rice.seasoned-rice-burrito`, `moes.beans.black-beans`, `moes.cheeses.oaxaca-cheese`, `moes.veggies.romaine-lettuce`, `moes.salsa.pico-de-gallo`, `moes.toppings.sour-cream`, `moes.toppings.guacamole`
- **Pre-checked toppings on a plain custom Burrito or Bowl** — ON by default. If a customer says "just a burrito" and stops talking, they do not get an empty tortilla. Moe's online build pre-selects rice, beans, cheese and pico, and on bowls also sour cream. The bean default flips by vessel, which is genuinely surprising: PINTO on the Custom Burrito and Jr. Burrito, BLACK on the Bowl, Homewrecker, Stack, Quesadilla, Nachos and Salad. Our formats mark rice as required:false and pre-select nothing, so a Loadout burrito starts at 310 cal where a real one starts at 725.
  - maps to: `moes.rice.seasoned-rice-burrito`, `moes.beans.pinto-beans`, `moes.cheeses.oaxaca-cheese`, `moes.salsa.pico-de-gallo`, `moes.toppings.sour-cream`
- **The Stack (queso is structural, and it takes TWO corn shells)**. Moe's signature crunchy-in-soft item and a format we don't have at all. Two crunchy corn shells are glued inside a grilled 12" flour tortilla with Moe's Famous Queso as the mortar. Queso is not an upsell here — "Queso Inside Your Item" is isDefault:true on the Stack alone, and the product copy leads with it. There is no rice station on a Stack; rice drops to the free bar.
  - maps to: `moes.tortilla.flour-tortilla-12`, `moes.tortilla.crispy-corn-shell-6`, `moes.toppings.queso-add-on`, `moes.beans.black-beans`, `moes.cheeses.oaxaca-cheese`, `moes.salsa.pico-de-gallo`
  - **gap:** A 'Stack' format — our formats file has only burrito/bowl/tacos/salad, and the corn shell needs quantity 2, which no current format can express (only the tacos format sets quantityPerPick, and it sets 3).
- **A Moe's salad always ships with dressing, and Chipotle Ranch is the default** — ON by default. "Dressings (Served on Side)" is a MANDATORY group on both the Salad and the Southwest Salad, defaulting to Chipotle Ranch Dressing — 140 cal / 15 g fat, i.e. 40% of the whole salad. Our salad format has dressings as required:false with no default, so a Loadout salad silently omits the single largest macro line in the real dish. The salad also comes pre-loaded with romaine, black beans, shredded cheese and pico.
  - maps to: `moes.veggies.romaine-lettuce`, `moes.beans.black-beans`, `moes.cheeses.oaxaca-cheese`, `moes.salsa.pico-de-gallo`, `moes.dressings.chipotle-ranch`
- **Quesadillas come with pico and sour cream cups on the side** — ON by default. Both the plain Quesadilla and the Chicken Club Quesadilla have a "Sides" modifier group where "Pico on the Side" and "Sour Cream on the Side" are BOTH pre-checked. That is +70 cal and 5 g fat nobody thinks to log, arriving in two little cups they didn't ask for.
  - maps to: `moes.salsa.pico-de-gallo`, `moes.toppings.sour-cream`
  - **gap:** A 'Quesadilla' format (8" or 12" grilled tortilla + cheese) — we have neither the format nor a Chicken Club Quesadilla preset.
- **Nachos are built on queso, not sprinkled with cheese** — ON by default. On the Nachos build, the Add-Ons group's "Queso" option is isDefault:true — queso is the base of the dish, not an upcharge, and Pico is pre-checked too. The chip bed is roughly a Cup of chips, not a Side.
  - maps to: `moes.chips.tortilla-chips-cup`, `moes.dips.queso-side`, `moes.beans.black-beans`, `moes.salsa.pico-de-gallo`
  - **gap:** A 'Nachos' format. And note that Nachos ALSO trigger the mandatory Free Chips and Salsa step — a bowl of nachos comes with a separate bag of free chips.
- **Moe Value Meal**. The standing $9.95 combo a regular orders by name: a Jr. Burrito (or two tacos, or two Dippers) plus 2 oz of Moe's Famous Queso, chips, salsa and a regular fountain drink. The 2 oz queso is a Side portion and is separate from — and on top of — the free chips and salsa that already come with the entrée.
  - maps to: `moes.dips.queso-side`, `moes.chips.tortilla-chips-side`, `moes.salsa.house-made-salsa`
  - **gap:** The Jr. Burrito itself (no format for it).
  - **gap:** The fountain drink — deliberately out of scope per the food-only menu rule.
- **"Extra Meat" (double protein), asked at the grill**. Not a default, but it is asked out loud on every item, immediately after the protein — a dedicated group named "Modify Proteins:" at seq 1, before rice is even mentioned. It is the Double tier in the nutrition chart. Worth surfacing as a stepper on the protein row rather than as five extra menu rows, because at the counter it is one follow-up question, not a separate ingredient.
  - maps to: `moes.protein.white-meat-chicken-double`, `moes.protein.adobo-chicken-double`, `moes.protein.hand-cut-steak-double`, `moes.protein.ground-beef-double`, `moes.protein.tofu-large`

### Station order

No — our order is wrong in three structural ways, not just cosmetically.

OUR ORDER: tortilla → rice → beans → protein → cheese → salsa → veggies → toppings → sauces → dressings → dips → chips → dessert.
MOE'S ACTUAL ORDER: protein → extra meat? → (shell, only for tacos) → rice → beans → Fresh Free Ingredients → Sauce Choice → paid Add-Ons → Free Chips & Salsa → register (dips/drink/dessert).

WHAT SHOULD MOVE:

1. PROTEIN MOVES TO FIRST. This is the headline. Moe's is not Chipotle — the grill is the first station and "what meat?" is the first question on every item. Protein sits at seq 0 on all 14 buildable products in Moe's own ordering payload, ahead of rice and beans. Our menu buries it at position 4. Immediately after it, before rice, comes the "Extra Meat:" double-protein question — attach that to the protein row as a Regular/Double toggle rather than leaving five separate "(Double)" items adrift in the list.

2. TORTILLA SHOULD STOP BEING A STATION. It is only ever a question for tacos ("Crispy Shell / Soft Shell - Flour") and it is a single forced option on the Stack. For burritos, bowls, quesadillas and kids items Moe's never asks — the size follows the vessel. Our format files already auto-add the 12" tortilla for burritos, so leading the walk with a "Tortilla & Shell" station shows the user a choice that doesn't exist and lets them pick an 8" or a corn shell for a burrito.

3. COLLAPSE CHEESE + SALSA + VEGGIES + TOPPINGS + DRESSINGS INTO ONE "FRESH FREE INGREDIENTS" STATION. At Moe's this is literally one group, one sneeze guard, and the brand markets it as "over 20 free ingredients". Splitting it into five of our thirteen stations makes the walk feel twice as long as the real line and hides the fact that it's all free. Two items in our Toppings and Dressings categories do NOT belong on that bar and should move out: Chipotle Ranch is part of the single-select Sauce Choice, and Guacamole/Queso/Bacon are the paid Add-Ons step. Conversely, Hard Rock & Roll Sauce and Southwest Vinaigrette DO belong on the free bar despite living in our Sauces and Dressings categories.

4. SAUCES BECOME A SINGLE-SELECT STEP AFTER THE FREE BAR, not a selectMany alongside it. Moe's "Sauce Choice" has maxSlt 1 across Moe's Sauce, Poblano Crema, Chili Lime Sauce and Chipotle Ranch, each with an "…On Side" variant. Our sauces category is selectMany and omits Chipotle Ranch entirely (it's filed under Dressings).

5. ADD A PAID "ADD-ONS" STEP between sauces and chips: Guacamole Inside Your Item, Queso Inside Your Item, Bacon Inside Your Item. We have all three items (guacamole-add-on, queso-add-on, bacon) but scattered inside a generic "Toppings & Add-Ons" bucket that also holds free things like sour cream.

6. FREE CHIPS & SALSA BECOMES A MANDATORY FINAL STEP, defaulted to yes, not an optional "Tortilla Chips" category the user has to go find. Right now our chips category is buried between dips and dessert and is easy to skip — which is exactly backwards from how the real order works.

7. DRESSINGS SHOULD ONLY APPEAR ON SALADS, and there it is mandatory with Chipotle Ranch pre-selected. Our formats expose the dressings category as an optional extra on burritos and bowls, where Moe's never offers it as a standalone step.

Everything after the free chips — Queso/Guac/Chips to share, drink, cookie — is register-side and its current tail position is correct.

### Missing staples

- THE STACK — Moe's signature crunchy item, a permanent menu category headline ('Stacks & Quesadillas'). Two crispy corn shells and queso inside a grilled flour tortilla. We have every ingredient (the corn shell item is even named '/ Stack Shell') but no format and no preset. Verified build sums to 720 vs Moe's published 722.
- QUESADILLA — permanent category, published 690-840 cal. No format. Comes with pico and sour cream on the side by default.
- CHICKEN CLUB QUESADILLA — the fixed-recipe quesadilla, 1240-1390 cal, permanently on the board. Bacon and chipotle ranch inside, pico and sour cream on the side.
- NACHOS — its own top-level menu category (moes.com/menu/nachos), 1020-1170 cal. No format.
- JR. BURRITO — permanent smaller burrito, 620-770 cal, and the anchor of the $9.95 Moe Value Meal. Our menu already carries the junior rice and bean portions (seasoned-rice-jr-burrito, black-beans-jr) — they're orphaned with no format that uses them.
- GRILLED BURRITO DIPPERS — sold as 1 ct., 2 ct. and a 10-pack. Mini burritos with Oaxaca cheese and queso inside, grilled. Now a headline item with its own Moe Value Meal variant.
- ONE TACO — Moe's sells a single taco as well as Three Tacos. Our tacos format hard-codes quantityPerPick 3, so a single taco can't be built.
- KIDS MEALS — Kids Burrito (260-335), Kids Quesadilla (65-140), Kids Taco (160-235). These are what the 8" and 6" tortillas and the Small protein tier exist for; without them, moes.tortilla.flour-tortilla-8 is unreachable in any format.
- SOUTHWEST SALAD — the fixed-recipe salad (670-820 cal): romaine, black beans, roasted corn salsa, pico, Oaxaca cheese, dressing on the side. We have a generic Salad format but no preset for the one people order by name.
- MOE PROTEIN BURRITO — we have a Moe Protein Bowl preset but not the burrito (1040-1190 cal, 'up to 69g protein'). The bowl is in presets, the burrito isn't.
- 'NO PROTEIN' — Moe's offers an explicit No Protein option on every build (itf-6300), and No Rice and No Beans alongside it. Our formats mark protein required:true, so a vegetarian burrito is impossible to build in Loadout. This is a real, permanently-available choice.
- CILANTRO — on the Fresh Free Ingredients bar on every item. Macro-trivial (~1 cal) but its absence makes the free bar look incomplete next to the real sneeze guard.
- CHIPS & DIPS TRIO — permanent shareable: queso + guac + house-made salsa + chips.
- MOE VALUE MEAL — the standing $9.95 combo (entrée + 2 oz queso + chips + salsa + drink), a permanent menu fixture with its own product page, not an LTO.
- KILLER BROWNIE — offered in the Kids Dessert group alongside the chocolate chunk cookie; our Dessert category has only the cookie.

### Naming

- 'Hand Cut Steak' — the board and the order flow both just say 'Steak'. Nobody says 'hand cut' at the counter. (The PDF's marketing name is where ours came from.)
- 'Organic Tofu' — the order flow says 'Tofu'. 'Organic' is a nutrition-chart adjective.
- 'Shredded Oaxaca Cheese' — the line and the app both say 'Shredded Cheese'. 'Oaxaca' appears only in the nutrition PDF and in Moe Protein product copy. A customer asking for 'Oaxaca cheese' would get a blank look.
- 'Pico de Gallo' — Moe's calls it 'Pico' everywhere in the ordering flow, and 'New Pico' in the nutrition chart.
- 'Shredded Romaine Lettuce' — order flow says 'Shredded Lettuce'.
- 'Grilled Onions and Peppers' — Moe's word order is the reverse: 'Grilled Peppers and Onions'.
- 'Hard Rock Sauce' — the real name is 'Hard Rock & Roll Sauce'. Our name is a truncation that appears nowhere on Moe's menu.
- 'Southwest Vinaigrette' — listed as 'Southwest Vinaigrette Dressing', and it sits on the FREE ingredients bar, not in a dressings station.
- 'House-Made Salsa' / 'Tomatillo Salsa' / 'Spicy Red Salsa' — the ordering flow labels these by colour because they're the chip salsas: 'House Made Salsa (Red)', 'Tomatillo (Green)', 'Spicy House Made Salsa (Spicy Red)'. Worse, our menu files all five salsas as entrée toppings; in reality only Pico and Roasted Corn Salsa are on the build line — the other three are the salsa-bar salsas you get with your free chips.
- "Moe's Famous Queso (Add-On)" and 'Guacamole (Add-On)' — on the menu these read 'Queso Inside Your Item' and 'Guacamole Inside Your Item'. The '(Add-On)' suffix is nutrition-chart vocabulary. Out loud you'd say 'queso in it'.
- 'Crispy Bacon' — the order flow calls it 'Bacon Inside Your Item'.
- Every rice and bean row carrying a portion suffix — '(burrito portion)', '(junior burrito portion)', '(bowl)', '(cup)'. None of these are ever said, shown, or asked. A customer says 'seasoned rice' once.
- '12" Flour Tortilla' — never spoken and never chosen; it's just what a burrito is wrapped in. Same for the 8".
- '6" Crispy Corn Tortilla / Stack Shell' — at the counter the question is 'crispy or soft?' and the options are labelled 'Crispy Shell' and 'Soft Shell - Flour'.
- 'Sweet Street Chocolate Chunk Cookie' — the board says 'Chocolate Chunk Cookie'. 'Sweet Street' is the bakery supplier's name.
- Our category name 'Queso & Guac (to share)' — Moe's menu section is 'Dips & Sides'.
- Our format 'Bowl' — Moe's calls the custom one a 'Burrito Bowl' on the product page and its bowls category also carries 'Homewrecker Bowl' and 'Moe Protein Bowl'. A bare 'Bowl' is ambiguous.
- Our format 'Tacos' — the board lists 'Three Tacos' and 'One Taco' as separate items.
- Our format 'Salad' — the board lists 'Fresh Salad' (build-your-own) and 'Southwest Salad' (fixed).
- 'Potatoes' — this item is in the nutrition PDF but appears nowhere in Moe's current menu or ordering flow. It is likely a discontinued or breakfast-only ingredient and would confuse anyone looking for it on the line.
- We have both 'Guacamole' (80 cal, fresh-ingredient scoop) and 'Guacamole (Add-On)' (60 cal) as separate rows with near-identical names. A user cannot tell which to pick; Moe's surfaces only one thing called 'Guacamole Inside Your Item'.

---

## Panda Express — NEEDS_WORK

### How you actually order

Verified by walking the live builder at two stores (McKinney TX and Rosemead CA). The sequence is short — Panda is two questions, not a Chipotle-style line.

STEP 0 — Pick the container before any food. The board/app opens on formats, not ingredients: Panda Bundles (format + drink), BOWL (1 side + 1 entree), PLATE (1 side + 2 entrees), BIGGER PLATE (1 side + 3 entrees), BALANCED PROTEIN PLATES (2 fixed presets + Build Your Own), Panda Cub Meal, 5 Person Family Meal (2 LARGE sides + 3 LARGE entrees), Appetizers and More, A La Carte, Drinks, Catering. The side portion never changes across Bowl/Plate/Bigger Plate — you are only buying more entree scoops.

STEP 1 — Side. The literal on-screen label is "Choose a Side, or Get Half and Half". Four options at most stores (White Steamed Rice 520, Fried Rice 620, Chow Mein 600, Super Greens 130), five in CA (+ Quinoa Fried Rice 440). Half-and-half is first-class, not a hack: tap a second side and both cards flip to a "1/2" badge, the other sides gray out, price does not move, and the calorie readout becomes an exact 50/50 (Chow Mein + Super Greens = 365 Cal). In-store the server starts here — Panda staff explicitly say "tell them your sides first" because the side goes in the container before anything else and they cannot start your order without it.

STEP 2 — Entree(s). "Choose an Entree" / "Choose Two Entrees" / "Choose Three Entrees". 13-14 options. Premium entrees carry a visible upcharge inline (+$1.50 Honey Walnut Shrimp, +$1.50 Black Pepper Sirloin Steak, +$2.50 Grilled Mandarin Salmon) and are badged "Premium". Picking the SAME entree twice is supported and free — the card turns into a quantity stepper (I selected Orange Chicken x2 on a Plate: 1640 Cal = 620 fried rice + 510x2). Step 2 is gated on Step 1: entree cards do not respond until a side is chosen.

THERE IS NO STEP 3. Bowls and Plates have no sauce step, no topping step, no "anything else on it". After Step 2 you hit ADD TO ORDER.

SAUCES live outside the build. They appear as an "ADD SAUCE" checklist only on (a) appetizer items and (b) Balanced Protein Plates. In-store they are packets handed over at the register — you ask, and many stores cap it at one packet per order.

APPETIZERS are a separate add-on line with their own size picker. Important: since roughly Feb 2026 a POS change removed the long-standing convention of ringing an appetizer into an entree slot on a Plate/Bigger Plate ("rice, orange chicken, and spring rolls" as a Plate). Do not model it — it is dead chain-wide.

Then drinks, then pay. A fortune cookie goes in the bag.

### Sizes

Panda has no per-dish size picker inside a meal — the size ladder IS the format. Bowl -> Plate -> Bigger Plate holds the side constant (~11 oz) and adds ~5-6 oz entree scoops. Our JSON portions are exactly the in-meal portions and match the live builder's calorie chips item-for-item (Chow Mein 600, Fried Rice 620, White Steamed Rice 520, Super Greens 130, Orange Chicken 510, Grilled Teriyaki 275). So there is nothing in our file to collapse — zero duplicate size rows exist, and groups is empty.

But three real, permanent size axes are entirely absent from our model:

1. A LA CARTE ENTREES: Small / Medium / Large, Small pre-selected. Small IS the in-meal portion (Orange Chicken Small = 5.92 oz / 510 Cal, identical to our row). Medium and Large are roughly 2x and 3x.

2. A LA CARTE SIDES: Medium / Large only — no Small — with Medium pre-selected, and Medium is BIGGER than the meal side. A la carte Chow Mein Medium is 16.5 oz / 880 Cal against the 11 oz / 600 Cal we carry. Anyone logging "a medium chow mein" would be under-counting by 280 Cal using our row.

3. APPETIZERS: Small / Large, Small pre-selected — and this one bites items we already ship. Cream Cheese Rangoon is Small (3 pcs) vs Large (12 pcs); Chicken Egg Roll is Small (1 pc) vs Large (6 pcs). Our rows are the Small.

4. The side slot is internally two half-units (see half-and-half), so a side needs a 0.5 multiplier our schema has no way to express.

Family Meal uses Large sides and Large entrees. The failure here is omission, not mis-splitting — do not restructure existing rows, add a size dimension.


### House configurations

- **Half and Half (side)**. Split the single side slot between two different sides — half chow mein / half fried rice, half super greens / half fried rice, half super greens / half white rice. Free, officially labeled in Step 1 of the builder ('Choose a Side, or Get Half and Half'), and extremely common: r/PandaExpress regulars call it 'pretty common', 'it's an option for a reason', and one commenter notes the POS rings every side as two halves even when you order a single side. Macro impact is exactly 50/50 of each side — verified Chow Mein + Super Greens = 365 Cal = (600+130)/2. This is the one Panda mechanic that most changes a tracked total, because it is the difference between 620 Cal of fried rice and 375 Cal of half-fried-rice/half-greens on the SAME order.
  - maps to: `panda-express.sides.chow-mein`, `panda-express.sides.fried-rice`, `panda-express.sides.white-steamed-rice`, `panda-express.sides.super-greens`, `panda-express.sides.chow-fun`
  - **gap:** Quinoa Fried Rice — a fifth side (440 Cal) live at CA stores, selectable in Step 1, not in our menu and not yet in Panda's own nutrition table
  - **gap:** A 0.5 portion multiplier — every side we carry is a full 11 oz portion with no way to express a half
- **Grilled Teriyaki Chicken comes sauced** — ON by default. Panda's closest thing to Mike's Way. Order Grilled Teriyaki Chicken and Teriyaki Sauce is applied by default — you have to actively decline it. The nutrition table lists the chicken NAKED at 275 Cal / 14 g carb / 33 g protein, so a PDF-only model silently under-counts every teriyaki order by the sauce: +70 Cal, +16 g carb, +14 g sugar, +380 mg sodium. The product photo on the menu itself shows the sauce drizzled across the chicken.
  - maps to: `panda-express.entrees.grilled-teriyaki-chicken`, `panda-express.sauces.teriyaki-sauce`
- **Double Protein Plate**. A permanent, named, orderable preset under 'Balanced Protein Plates' — priced the same as a regular Plate. Composition string on the item: '2X Grilled Teriyaki Chicken with Half White Steamed Rice + Half Super Greens'. 875 Cal, 76 g protein. Teriyaki Sauce arrives pre-checked. This is the highest-protein thing on the Panda menu and precisely the order a macro-tracking user comes to Panda for — it also demonstrates that Panda's own product design uses BOTH the half-and-half side and duplicate entrees, the two mechanics our model cannot express.
  - maps to: `panda-express.entrees.grilled-teriyaki-chicken`, `panda-express.sides.white-steamed-rice`, `panda-express.sides.super-greens`, `panda-express.sauces.teriyaki-sauce`
  - **gap:** quantity 2 on the Grilled Teriyaki Chicken component
  - **gap:** 0.5 multiplier on both White Steamed Rice and Super Greens
- **Harmonious Macros Plate**. The second permanent Balanced Protein Plates preset: 'Grilled Teriyaki Chicken and Broccoli Beef with Super Greens'. 555 Cal, 57 g protein, full (not half) Super Greens as the side. Teriyaki Sauce pre-checked. Same price as a normal Plate.
  - maps to: `panda-express.entrees.grilled-teriyaki-chicken`, `panda-express.entrees.broccoli-beef`, `panda-express.sides.super-greens`, `panda-express.sauces.teriyaki-sauce`
- **Same entree twice (or three times)**. The 'double orange chicken plate'. On a Plate or Bigger Plate you can put the same entree in every slot at no upcharge — the card becomes a quantity stepper rather than forcing two distinct picks. Very common for people who only want one thing but want more of it. Macro impact is a clean multiple of the entree row, but our formats file expresses the entree prompt as choose:'upTo:2' / 'upTo:3', which reads as N distinct selections and will likely block or mis-model the duplicate.
  - maps to: `panda-express.entrees.orange-chicken`, `panda-express.entrees.hot-orange-chicken`, `panda-express.entrees.beijing-beef`, `panda-express.entrees.grilled-teriyaki-chicken`
  - **gap:** a per-entree quantity control (1-3) inside the entree station

### Station order

Our station order is correct — do not move anything. Our categories run sides -> entrees -> appetizers -> sauces, which is exactly the real sequence: Step 1 side, Step 2 entree(s), then appetizers as a separate add-on line, then sauce packets at the register. Panda staff on r/PandaExpress confirm the counter order explicitly: "we like you to start with your sides since that's the first option we have to do to not make your plate messy and have accurate portion sizes," and for drive-thru "they can't start to make your food until you tell them your sides."

Two refinements rather than reorderings:

1. Sauces are not a walked station. There is no sauce step in the Bowl/Plate flow at all. Sauces surface only as an "ADD SAUCE" checklist bolted onto appetizer items and Balanced Protein Plates, and in-store they are packets you request at the till (often capped at one per order). Keeping Sauces as a fourth optional category is fine, but it should render as a post-build add-on tray, not as a station you are walked past — and Potsticker Sauce should only appear when a potsticker is in the order.

2. The format choice is a real zeroth step that precedes the stations. The board opens on Bowl / Plate / Bigger Plate / Balanced Protein Plates, and the side and entree stations are literally labeled STEP 1 and STEP 2 beneath it. Our formats file already models this correctly. One gap: Balanced Protein Plates is a fourth permanent format sibling to Bowl/Plate/Bigger Plate and is missing from panda-express.formats.json — it deserves a format entry with the two presets, since it is the macro-conscious entry point and the app's whole audience.

### Missing staples

- Quinoa Fried Rice — a fifth permanent SIDE (440 Cal), selectable in Step 1 and in A La Carte at the Rosemead CA store. Newer than Panda's own nutrition table, which does not list it yet. Highest-priority gap: it sits in the first station a customer touches.
- Grilled Mandarin Salmon — Premium entree (+$2.50, 180 Cal), badged New, present in Step 2 and A La Carte at the CA store. Not in the nutrition table yet.
- Hot & Sour Soup — listed under 'Appetizers and More' in the live CA builder, i.e. it is a food line item, not a drink. Cup 12.2 oz / 120 Cal / 7 g protein, Bowl 17.4 oz / 170 Cal / 10 g protein. Our dataSource notes deliberately excluded soups; per the food-only rule this one should come back in.
- Fortune Cookie — 0.18 oz / 20 Cal / 5 g carb. Permanently available and dropped in the bag with orders. Trivial macros but it is the one thing everyone actually eats that we have no row for.
- Chef's Special / Chef's Special Premium — a permanent rotating premium ENTREE SLOT on the board at CA stores (+$1.50). The contents rotate, so it is not a fixed item, but the slot itself is permanent and a customer will see it in Step 2 and wonder where it went in our app.

### Naming

- panda-express.entrees.orange-chicken is named 'Orange Chicken' but every menu board and the online builder now say 'The Original Orange Chicken'. Panda renamed it when Hot Orange Chicken launched, and the two sit adjacent in Step 2 — 'Orange Chicken' vs 'Hot Orange Chicken' reads as a temperature difference rather than the Original/Hot pairing the board actually presents.
- panda-express.entrees.teriyaki-chicken ('Teriyaki Chicken', 340 Cal, 41 g protein) does not exist on any menu board. Neither store's Step 2 or A La Carte listed it; the board only ever says 'Grilled Teriyaki Chicken'. It exists solely as a row in the nutrition PDF. Shipping it next to panda-express.entrees.grilled-teriyaki-chicken (275 Cal, 33 g protein) gives the user two near-identical teriyaki chickens with no way to tell which one they were handed — and the wrong pick is a 65 Cal / 8 g protein error. Either drop it or label it clearly as a non-board variant.
- panda-express.entrees.super-greens-entree is named 'Super Greens (Entree)'. The board just says 'Super Greens', and it genuinely appears twice — once in Step 1 as a side (10 oz / 130 Cal) and once in Step 2 as an entree (7 oz / 90 Cal), with no parenthetical either time. Keep the two rows, but render both as 'Super Greens' and let the station header do the disambiguating; nobody says 'super greens entree' out loud.
- The four '... Chicken Breast' items (honey-sesame, string-bean, sweet-and-sour, sweetfire) match the board exactly, but out loud people say 'honey sesame', 'string bean chicken', 'sweet and sour', 'sweetfire'. Search/matching should hit these without the 'Breast' suffix.
- panda-express.appetizers.veggie-spring-roll is 'Veggie Spring Roll' on the board but 'Vegetable Spring Roll' in the nutrition table — our name matches the board, which is right; just note the two spellings so a nutrition re-scrape does not 'correct' it the wrong way.
- Availability, not spelling, but it will read as a naming mismatch to users: Chow Fun, Potato Chicken, Sweet & Sour Chicken Breast, SweetFire Chicken Breast, Wok-Fired Shrimp, Steamed Ginger Fish, Eggplant Tofu, Chicken Potsticker and Apple Pie Roll are all in Panda's nutrition table but appeared on NEITHER store's live board (TX or CA). They are regional/legacy. Worth a 'not at every location' marker so users do not go hunting for a row that has no counterpart on the board in front of them.

---

## Panera Bread — NEEDS_WORK

### How you actually order

Panera is not a line — it is a kiosk/app/counter flow, and the app IS the canonical sequence (most orders are placed on the kiosk or in-app; Rapid Pick-Up is the default).

1. Pick a CATEGORY from the board. Real nav order: What's New, You Pick Two, Must-Have Meals, Mix & Match, Sandwiches, Market Bowls, Soups & Mac, Salads, Salad Stuffers, Bakery, Beverages, Family Feast Value Meals, Breakfast (before 11am), Kids, Sides & Spreads, Vegetarian.

2. Pick the named DISH. Right on the card you already see a size chip ("Whole ▾" for sandwiches/salads/market bowls, "Bowl ▾" for soups & mac) plus "Add" and "Customize".

3. On the product page, in this literal on-screen order: SIDES → SIZES → QUANTITY. The headline reads "850 Cal + Side (150 Cal)" — the side is already chosen for you and already counted.
   - Sides prompt: "Would you like to add a free side?" Options: French Baguette 190 Cal FREE, Apple 80 Cal FREE, Chips 150 Cal FREE, Asiago Croissant Twists +$1.00 / 210 Cal, Fruit Cup +$2.39 / 60 Cal, No Side.
   - Sizes prompt: "Which size would you like?" Half / Whole.

4. Salads only: a "Make it a Stuffer" checkbox sits between the size row and Customize — it converts a half salad into an Italian Stuffer Roll sandwich.

5. Hit CUSTOMIZE. Tabs run left to right and the sequence differs by dish type:
   - Sandwich: What's Included → Breads → Proteins → Cheeses → Toppings → Condiments
   - Salad: What's Included → Proteins → Cheeses → Veggies → Toppings → Dressings
   "What's Included" lists the stock build; every line has a minus (remove) and an amount control that opens "How much would you like?" → Light / Regular (default) / Extra. Everything else in the other tabs is a plus (add), most with an upcharge.

6. Start an order / Add to bag.

You Pick Two is a separate entry point, not a step: you choose "Create Your Own", then "Select any two of the following: Cup of Soup or Mac, Half Salad, Half Sandwich" — ANY two, including two of the same type — and then one free side from a restricted set of three (chips, French Baguette, apple). You can also enter YP2 from an item card via a "Make It Part of a YP2™" button.

### Sizes

Panera has TWO independent size axes and we model neither as a picker.

AXIS 1 — Whole / Half. Every sandwich, salad and market bowl carries a "Whole ▾" dropdown on the menu card and on the product page ("Which size would you like?" → Half / Whole). WHOLE is the default. Our mains category is whole-only (31 items, all servingDescription "(whole)") and the half is derived by a split rule, so there is nothing to collapse — but the app must surface a Half chip on every mains row, because Half is what a customer picks whenever they build a You Pick Two, and Panera publishes its own independently-rounded half numbers (Fuji Apple whole 710 vs published half 350, not 355).

AXIS 2 — Cup / Bowl / Bread Bowl / Group, for soups and mac. This one IS wrong in our data: 24 rows in `entrees` are really 8 dishes at 3 sizes. On the board there is ONE card per soup with a size dropdown, and the default shown is BOWL, not Cup. Bread Bowl and Group Serving are rendered as separate sections beneath, which supports treating Bread Bowl as a fourth size chip rather than its own dish. We have no Group (32 oz) portions at all.

AXIS 3 — dressing portions. 18 dressing rows are 9 dressings at 2 portions (1 dressing cup vs 2 dressing cups), and three of them have a THIRD portion sitting over in `sauces` as "- Sandwich Portion". Same liquid, three sizes, three rows. The portion is not a free choice — it follows the salad size — so it should be a chip on one dressing row, defaulting to Whole.

NOT a size axis, despite looking like one: Salad Stuffers. A Stuffer is a half salad packed into an Italian Stuffer Roll, reached by a "Make it a Stuffer" CHECKBOX on the salad's own page, and it is listed inside the Salads category under the header "Upgrade any half salad!". Our 12 Stuffer rows in `entrees` are orphaned from their parent salads and should be a format toggle on the salad, not standalone dishes.

- **Broccoli Cheddar Soup** — default Bowl: Cup (`panera.entrees.broccoli-cheddar-soup-cup`), Bowl (`panera.entrees.broccoli-cheddar-soup-bowl`), Bread Bowl (`panera.entrees.broccoli-cheddar-soup-bread-bowl`)
- **Creamy Tomato Soup** — default Bowl: Cup (`panera.entrees.creamy-tomato-soup-cup`), Bowl (`panera.entrees.creamy-tomato-soup-bowl`), Bread Bowl (`panera.entrees.creamy-tomato-soup-bread-bowl`)
- **Bistro French Onion Soup** — default Bowl: Cup (`panera.entrees.bistro-french-onion-soup-cup`), Bowl (`panera.entrees.bistro-french-onion-soup-bowl`), Bread Bowl (`panera.entrees.bistro-french-onion-soup-bread-bowl`)
- **Homestyle Chicken Noodle Soup** — default Bowl: Cup (`panera.entrees.chicken-noodle-soup-cup`), Bowl (`panera.entrees.chicken-noodle-soup-bowl`), Bread Bowl (`panera.entrees.chicken-noodle-soup-bread-bowl`)
- **Cream of Chicken & Wild Rice Soup** — default Bowl: Cup (`panera.entrees.cream-of-chicken-wild-rice-cup`), Bowl (`panera.entrees.cream-of-chicken-wild-rice-bowl`), Bread Bowl (`panera.entrees.cream-of-chicken-wild-rice-bread-bowl`)
- **Black Bean Soup** — default Bowl: Cup (`panera.entrees.black-bean-soup-cup`), Bowl (`panera.entrees.black-bean-soup-bowl`), Bread Bowl (`panera.entrees.black-bean-soup-bread-bowl`)
- **Mac & Cheese** — default Bowl: Cup (`panera.entrees.mac-and-cheese-cup`), Bowl (`panera.entrees.mac-and-cheese-bowl`), Bread Bowl (`panera.entrees.mac-and-cheese-bread-bowl`)
- **Bacon Mac & Cheese** — default Bowl: Cup (`panera.entrees.bacon-mac-and-cheese-cup`), Bowl (`panera.entrees.bacon-mac-and-cheese-bowl`), Bread Bowl (`panera.entrees.bacon-mac-and-cheese-bread-bowl`)
- **Caesar Dressing** — default Whole: Half (`panera.dressings.caesar-dressing-half`), Whole (`panera.dressings.caesar-dressing-whole`)
- **Farmhouse Ranch Dressing** — default Whole: Sandwich (`panera.sauces.farmhouse-ranch-sandwich-portion`), Half (`panera.dressings.farmhouse-ranch-half`), Whole (`panera.dressings.farmhouse-ranch-whole`)
- **Greek Dressing** — default Whole: Sandwich (`panera.sauces.greek-dressing-sandwich-portion`), Half (`panera.dressings.greek-dressing-half`), Whole (`panera.dressings.greek-dressing-whole`)
- **Green Goddess Dressing** — default Whole: Sandwich (`panera.sauces.green-goddess-sandwich-portion`), Half (`panera.dressings.green-goddess-dressing-half`), Whole (`panera.dressings.green-goddess-dressing-whole`)
- **Asian Sesame Vinaigrette** — default Whole: Half (`panera.dressings.asian-sesame-vinaigrette-half`), Whole (`panera.dressings.asian-sesame-vinaigrette-whole`)
- **Creamy Garden Herb Dressing** — default Whole: Half (`panera.dressings.creamy-garden-herb-half`), Whole (`panera.dressings.creamy-garden-herb-whole`)
- **Sesame Ginger Dressing** — default Whole: Half (`panera.dressings.sesame-ginger-dressing-half`), Whole (`panera.dressings.sesame-ginger-dressing-whole`)
- **White Balsamic with Apple Vinaigrette** — default Whole: Half (`panera.dressings.white-balsamic-apple-vinaigrette-half`), Whole (`panera.dressings.white-balsamic-apple-vinaigrette-whole`)
- **Lemon Vinaigrette** — default Whole: Half (`panera.dressings.zesty-smoky-lemon-vinaigrette-half`), Whole (`panera.dressings.zesty-smoky-lemon-vinaigrette-whole`)
- **French Baguette** — default Side: 2 oz slice (`panera.breads.french-baguette-slice`), Side (`panera.sides.french-baguette-side`), 1/4 Loaf (`panera.sides.french-baguette-breakfast-portion`)

### House configurations

- **The Free Side (Chips on a sandwich, Baguette on everything else)** — ON by default. Every entree at Panera — sandwich, salad, market bowl, soup, mac — comes with a free side, and one is ALREADY SELECTED for you before you touch anything. You have to actively decline it. The default is not uniform: sandwiches default to Chips (150 Cal); salads, market bowls and soups default to French Baguette (190 Cal). Panera's own product pages print the headline as "850 Cal + Side (150 Cal)" and "670 Cal + Side (190 Cal)", i.e. the side is quoted as part of the meal. The nutrition PDF prints only the bare 850 and 670. This is the single biggest gap in our model: it silently adds 150–190 kcal and ~17–37 g carbs to essentially every Panera order a user builds.
  - maps to: `panera.sides.kettle-cooked-potato-chips`, `panera.sides.french-baguette-side`, `panera.sides.side-apple`, `panera.sides.fruit-cup`
  - **gap:** Asiago Croissant Twists — 210 Cal per 2-pack, the +$1.00 premium upgrade slot in the free-side picker; we have no item for it
  - **gap:** 'No Side' as an explicit decline option (needed so the default can be turned off without the row looking empty)
- **Dressing is already in the salad — and it comes on the side** — ON by default. A Panera salad's published calories ALREADY INCLUDE its full dressing portion. The dressing is listed inside Customize under 'What's Included' with a Regular amount control and a Remove button, exactly like the chicken or the cheese. It is served in a cup on the side by default, which makes people assume it is an extra. It is not. Our `dressings` category is wired as an optional add-on for salads, so a user who picks Caesar Salad with Chicken (670) and then adds Caesar Dressing - Whole Portion (320) lands at 990 for a salad that is actually 670. The real orderable actions are: keep it (default), swap it for another dressing, drop to Light, bump to Extra, or Remove it entirely.
  - maps to: `panera.mains.caesar-salad-with-chicken`, `panera.dressings.caesar-dressing-whole`, `panera.dressings.caesar-dressing-half`, `panera.dressings.greek-dressing-whole`, `panera.dressings.farmhouse-ranch-whole`, `panera.dressings.green-goddess-dressing-whole`, `panera.dressings.asian-sesame-vinaigrette-whole`, `panera.dressings.sesame-ginger-dressing-whole`, `panera.dressings.white-balsamic-apple-vinaigrette-whole`, `panera.dressings.creamy-garden-herb-whole`, `panera.dressings.zesty-smoky-lemon-vinaigrette-whole`
  - **gap:** Poppyseed Dressing — offered on every salad's Dressings tab, we have no item for it
  - **gap:** A 'dressing already included / swap vs add' distinction in the data model — right now every dressing is purely additive
- **Light / Regular / Extra on every single component** — ON by default. Every ingredient already in a dish has a portion control, not just an on/off. Tapping the amount opens 'How much would you like?' with Light, Regular (pre-selected) and Extra. Extra on a protein or cheese carries the same upcharge as adding it fresh (+$3.39 for bacon), i.e. Extra literally doubles it. Regulars order 'light dressing' and 'extra chicken' constantly and it is a real macro lever, not a request the staff improvise.
  - **gap:** A Light/Regular/Extra multiplier on component items — our model is binary include/exclude with no portion axis at all
- **Any sandwich on a bagel (+$0.60)**. The Breads tab on every sandwich lists the six sandwich breads AND all nine bagels as a straight swap for sixty cents. This is a permanently supported option in Panera's own ordering UI, not a favour. It is a big macro move — a Cinnamon Crunch Bagel is 430 Cal against a 140 Cal slice of Country Rustic Sourdough — and it is the most commonly cited Panera 'hack' in the enthusiast writeups.
  - maps to: `panera.breads.tomato-basil-miche`, `panera.breads.artisan-ciabatta`, `panera.breads.black-pepper-focaccia`, `panera.breads.french-baguette-slice`, `panera.breads.country-rustic-sourdough`, `panera.breads.classic-white-loaf`
  - **gap:** Multigrain Bagel Flat (190 Cal)
  - **gap:** Blueberry Bagel (290 Cal)
  - **gap:** Cinnamon Swirl & Raisin Bagel (300 Cal)
  - **gap:** Cinnamon Crunch Bagel (430 Cal)
  - **gap:** Asiago Bagel (350 Cal)
  - **gap:** Asiago Everything Bagel (370 Cal)
  - **gap:** Plain Bagel (280 Cal)
  - **gap:** Sesame Bagel (310 Cal)
  - **gap:** Everything Bagel (300 Cal)
- **You Pick Two — any two, plus one free side**. Not 'a half sandwich and a soup'. The rule is literally 'Select any two of the following: Cup of Soup or Mac, Half Salad, Half Sandwich' — so two half sandwiches, or two cups of soup, are both legal orders, and plenty of people order them. On top of the two picks you get ONE free side, and the YP2 side list is narrower than the a la carte one: chips, French Baguette, or apple only. Our you-pick-two format forces exactly one item from `mains` and one from `entrees`, which both blocks two-of-a-kind and wrongly allows a Salad Stuffer or a whole Bread Bowl to occupy the second slot.
  - maps to: `panera.sides.kettle-cooked-potato-chips`, `panera.sides.french-baguette-side`, `panera.sides.side-apple`
  - **gap:** Half-portion entries for mains — halves are derived by a rule rather than existing as pickable rows, so a YP2 builder has nothing concrete to put in each slot
  - **gap:** A constraint that only Cup-size soups/mac qualify (Bowl, Bread Bowl and Group must be excluded from the YP2 pool)
- **Make it a Stuffer**. A half salad packed into a warm Italian Stuffer Roll, turning a salad into a handheld. It is a checkbox on the salad's own product page, sitting between the size row and the Customize button — you never navigate to a separate dish. Panera markets it as 'Upgrade any half salad'. It adds the roll's calories on top of the half salad and is a permanent line as of April 2026.
  - maps to: `panera.entrees.caesar-salad-stuffer`, `panera.entrees.caesar-salad-stuffer-with-chicken`, `panera.entrees.greek-salad-stuffer`, `panera.entrees.greek-salad-stuffer-with-chicken`, `panera.entrees.fuji-apple-chicken-salad-stuffer`, `panera.entrees.asian-sesame-chicken-salad-stuffer`, `panera.entrees.green-goddess-chicken-cobb-salad-stuffer`, `panera.entrees.southwest-chicken-ranch-salad-stuffer`, `panera.entrees.ranch-parm-blt-salad-stuffer`, `panera.entrees.farmhouse-crunch-salad-stuffer`, `panera.entrees.shrimply-baja-salad-stuffer`, `panera.entrees.ultimate-garden-steak-salad-stuffer`, `panera.breads.italian-style-roll`, `panera.breads.bread-portion-italian-style-roll`
  - **gap:** The link between each salad in `mains` and its Stuffer in `entrees` — they are currently unrelated rows in different categories, so a user browsing Salads never sees the Stuffer option exists
- **Add a protein to anything**. Every sandwich and every salad has a Proteins tab whose whole purpose is bolting more meat on. On salads the list is Steak +$4.19, Seasoned Diced Chicken +$3.39, Slow-Roasted Pork +$3.89, Tuna Salad +$3.39, Cranberry Walnut Chicken Salad +$3.39, Soppressata +$3.39, Shrimp +$4.09. On sandwiches it is Grilled Sliced Chicken, Soppressata, Black Forest Ham, Smoked Pulled Chicken, Chopped Bacon (all +$3.39) and Steak +$4.19. 'Caesar salad, add chicken' is one of the most-ordered modifications at the chain and we cannot express it at all. Related and well documented: Panera will swap AVOCADO in for the meat on a sandwich at no charge, which is the standard vegetarian move on the Mediterranean Veggie and the BLTs.
  - maps to: `panera.mains.caesar-salad`, `panera.mains.caesar-salad-with-chicken`, `panera.mains.greek-salad`, `panera.mains.greek-salad-with-chicken`
  - **gap:** Grilled Sliced Chicken
  - **gap:** Seasoned Diced Chicken
  - **gap:** Smoked Pulled Chicken
  - **gap:** Steak
  - **gap:** Slow-Roasted Pork
  - **gap:** Shrimp
  - **gap:** Soppressata
  - **gap:** Black Forest Ham
  - **gap:** Chopped Bacon
  - **gap:** Tuna Salad (as an add-on)
  - **gap:** Cranberry Walnut Chicken Salad (as an add-on)
  - **gap:** Avocado (+$1.89, and free when swapped for meat)
  - **gap:** Add-on cheeses: American, Provolone, Asiago, Parmesan, Feta, Fresh Mozzarella (all +$1.49)
  - **gap:** Add-on veggies: Grilled Broccoli, Sweet Potatoes, Edamame, Kalamata Olives, Grape Tomatoes, Shredded Red Cabbage, Arugula, Cucumber, Red Onions, Caramelized Onions, Zesty Sweet Peppers, Roasted Corn, Sliced Pepperoncini, Everything Bagel Seasoning
- **Turn the soup into a bread bowl**. The signature Panera move. Note that a bread bowl is NOT soup plus a bread bowl added together — Panera hollows the loaf and ladles less soup in, so Broccoli Cheddar Bowl 420 + Sourdough Soup Bowl 650 = 1070 but the actual published bread bowl is 930. Our data already handles this correctly by modelling bread bowls as whole items; the problem is purely that they sit as unrelated rows instead of a fourth size chip on the soup, so a user scanning Soups sees three Broccoli Cheddars and no indication that they are the same soup.
  - maps to: `panera.entrees.broccoli-cheddar-soup-bread-bowl`, `panera.entrees.creamy-tomato-soup-bread-bowl`, `panera.entrees.bistro-french-onion-soup-bread-bowl`, `panera.entrees.chicken-noodle-soup-bread-bowl`, `panera.entrees.cream-of-chicken-wild-rice-bread-bowl`, `panera.entrees.black-bean-soup-bread-bowl`, `panera.entrees.mac-and-cheese-bread-bowl`, `panera.entrees.bacon-mac-and-cheese-bread-bowl`, `panera.breads.sourdough-soup-bowl`

### Station order

Our sequence is mains → entrees → sides → breads → dressings → sauces, and the formats file treats sides, breads, dressings and sauces all as flat optional categories hanging off the main. The real flow is a two-stage funnel and the second stage is ordered differently depending on what you picked.

What Panera actually asks, in order: pick the dish → SIDE (pre-selected, free) → SIZE → quantity → then inside Customize, a fixed tab order that is bread-first for sandwiches and dressing-last for salads.

What should move:

1. SIDES must move UP to sit immediately after the main, and must change from an optional selectMany to a REQUIRED single-select that is already pre-filled (Chips for a sandwich, French Baguette for a salad/bowl/soup). It is the first question Panera asks after the dish, and it is the only station that is answered for you.

2. SIZE needs to become a real station between the side and the customization. Right now Whole/Half exists only as a derivation rule and Cup/Bowl/Bread Bowl exists only as duplicated rows.

3. BREADS must move ahead of dressings and sauces — it is the first tab inside Customize for a sandwich. It also needs re-scoping: our `breads` category is a mix of You-Pick-Two side-bread portions ("Bread Portion - Croissant", "Bread Portion - Italian Style Roll") and sandwich bread slices. Panera has two different bread concepts and we have merged them. The sandwich swap list is exactly: Tomato Basil, Artisan Ciabatta, Black Pepper Focaccia, French Baguette, Country Rustic Sourdough, Classic White Loaf, plus nine bagels. Whole Grain Lahvash and Croissant are not sandwich bread options.

4. DRESSINGS and SAUCES belong LAST, and they should be split by dish type, not offered together. A sandwich gets a Condiments tab (Apple Cider BBQ, Balsamic Glaze, Hummus, Salsa Verde Spread, Basil Pesto Spread, Mayonnaise, Sea Salt, Chipotle Aioli, Green Goddess, Garlic Aioli, Farmhouse Ranch, Greek). A salad gets a Dressings tab and no bread tab at all. Our sandwich-salad format currently offers `breads` AND `dressings` AND `sauces` to the same build, which produces nonsense combinations like a Caesar Salad with a bread choice.

5. THREE STATIONS ARE ENTIRELY MISSING and they sit right in the middle of the real sequence: Proteins, Cheeses, and Toppings/Veggies. On a sandwich the order is Breads → Proteins → Cheeses → Toppings → Condiments; on a salad it is Proteins → Cheeses → Veggies → Toppings → Dressings. We jump straight from the dish to sides/sauces, so the entire "build on top of the stock recipe" middle of the flow is absent.

6. ENTREES should not be a peer of MAINS. On the board the Bagel Stacks are filed under Hot Sandwiches, the Salad Stuffers under Salads, and the Soups & Mac are their own top-level category. Our `entrees` bucket lumps soups, mac, stuffers and bagel stacks into one 38-item list that matches nothing a customer sees.

Suggested station sequence: Dish (by real category) → Side → Size → Bread (sandwiches only) → Proteins → Cheeses → Veggies/Toppings → Dressings or Condiments.

### Missing staples

- All nine bagels — Plain (280), Everything (300), Sesame (310), Asiago (350), Asiago Everything (370), Cinnamon Crunch (430), Cinnamon Swirl & Raisin (300), Blueberry (290), Multigrain Bagel Flat (190). Needed both as standalone bakery items and as the +$0.60 sandwich bread swap.
- Cream cheese spreads — Plain 1.5 oz (140), Honey Walnut 1.5 oz (130), and the 8 oz tubs. The bagel is unorderable without them.
- Asiago Croissant Twists (210 Cal per 2-pack) — the premium upgrade inside the free-side picker, so it is missing from a station we also do not have.
- The entire breakfast egg-sandwich line (15 permanent items): Wake-Up BLT Asiago Everything Bagel Stack 570, Farmhouse Duo Asiago Bagel Stack 730, Sausage & Egg Asiago Bagel Stack 810, Ham Croissant Benny 430, Bacon Double Take 550, Steak & Wake 520, Ciabatta Bacon Egg & Cheese 470, Croissant Bacon Egg & Cheese 480, Garden Avo & Egg White 350, Chipotle Chicken Egg & Avo 600, Ciabatta Ham Egg & Cheese 460, Ciabatta Sausage Egg & Cheese 610, Croissant Sausage Egg & Cheese 620, Ciabatta Egg & Cheese 430, Croissant Egg & Cheese 440.
- Frittatas and Souffles — Five Cheese & Bacon Frittata 300, Broccoli Cheddar Frittata 280, Spinach & Bacon Souffle 550, Four Cheese Souffle 470. The souffle is one of Panera's signature items.
- Avocado Toasts — Classic Avo 260, Green Goddess Avo 310.
- Steel Cut Oatmeal with Strawberries & Pecans (330) — the standard high-fibre breakfast order.
- Add-on proteins, which have no home in our menu at all: Grilled Sliced Chicken, Seasoned Diced Chicken, Smoked Pulled Chicken, Steak, Slow-Roasted Pork, Shrimp, Soppressata, Black Forest Ham, Chopped Bacon, Tuna Salad, Cranberry Walnut Chicken Salad.
- Add-on cheeses (+$1.49): American, Provolone, Asiago, Parmesan, Feta, Fresh Mozzarella.
- Add-on veggies and toppings: Avocado, Grilled Broccoli, Sweet Potatoes, Edamame, Kalamata Olives, Grape Tomatoes, Shredded Red Cabbage, Arugula, Romaine, Mixed Greens, Cucumber, Red Onions, Caramelized Onions, Zesty Sweet Peppers, Roasted Corn, Sliced Pepperoncini, Cilantro, Basil, Everything Bagel Seasoning.
- Poppyseed Dressing — on every salad's Dressings tab, absent from ours.
- Chipotle Aioli as a salad dressing — we have it only as a sandwich sauce, but it appears in the salad Dressings list too.
- Half portions of the three Market Bowls — the board shows a Whole/Half picker on all of them and we carry whole only.
- Group Serving (32 oz) portions of all eight soups and macs — a permanent third size, e.g. Broccoli Cheddar Group 990 Cal, Bacon Mac & Cheese Group 2110 Cal.
- Pastries: Cinnamon Roll 580, Almond Pastry 470, Cherry Pastry 330, Cranberry Orange Slice 370, Pecan Braid 450, Chocolate Croissant 410, Lil' Lemon Bundt Cake 330.
- Cookies: Chocolate Chipper 390, Candy Cookie 410, Oatmeal Raisin with Berries 340, Petite Chocolate Chipper 100 ea.
- Orange Scone 540, Blueberry Muffin 530, Chocolate Chip Muffie 340.
- The Kids menu — a whole top-level category with its own smaller portions.

### Naming

- Every sandwich in `mains` appends its bread — 'Chicken Bacon Rancher on Black Pepper Focaccia', 'Bacon Turkey Bravo on Tomato Basil', 'Toasted Italiano on Baguette'. The board and the app say just 'Chicken Bacon Rancher', 'Bacon Turkey Bravo®', 'Toasted Italiano'. Nobody says the bread out loud, it makes rows unscannable, and it becomes actively wrong the moment the customer uses the bread swap — which is a supported, one-tap option.
- 'Cranberry Walnut Chicken Salad on Country Rustic' → the board says 'Cranberry Walnut Chicken Salad Sandwich'. The word Sandwich is load-bearing here: without it, it reads as the salad.
- 'Turkey & Cheddar on Country Rustic Sourdough' → board: 'Turkey & Cheddar Sandwich'. 'Tuna Salad on Country Rustic Sourdough' → board: 'Tuna Salad Sandwich'.
- 'Vegetarian Creamy Tomato Soup with Croissant Croutons' → board: 'Creamy Tomato Soup'. Nobody orders the long version, and 'Vegetarian' is a filter tag at Panera, not part of the name.
- 'Vegetarian Black Bean Soup' → board: 'Black Bean Soup'.
- Size baked into soup and mac names — 'Broccoli Cheddar Soup - Cup', 'Mac & Cheese - Bowl'. The board shows one card named 'Broccoli Cheddar Soup' with a size chip. The ' - Cup' / ' - Bowl' / ' - Bread Bowl' suffixes are our artifact, not menu language.
- 'Kettle Cooked Potato Chips' → the app and the counter both just say 'Chips'. That is also how it reads inside the free-side picker.
- 'French Baguette - Side Portion' → board: 'French Baguette'. And 'French Baguette - Breakfast Portion (quarter baguette)' is not a name that appears anywhere on Panera's menu.
- 'Bread Portion - Croissant' and 'Bread Portion - Italian Style Roll' are nutrition-PDF table headings, not orderable names. A customer says 'croissant' or asks for the Stuffer roll.
- Sauce names drift from the app's Condiments tab: ours 'Apple Cider Vinegar BBQ Sauce' vs 'Apple Cider BBQ'; 'Green Chile Salsa Verde' vs 'Salsa Verde Spread'; 'Creamy Basil Pesto' vs 'Basil Pesto Spread'; 'Farmhouse Ranch Dressing - Sandwich Portion' vs plain 'Farmhouse Ranch Dressing'.
- 'Zesty Smoky Lemon Vinaigrette' → the salad Dressings tab calls it 'Lemon Vinaigrette'. 'White Balsamic with Apple Vinaigrette' → 'White Balsamic Apple Vinaigrette'.
- 'Signature Sauce' — on the Bacon Turkey Bravo the app names this ingredient 'Bravo Sauce'. Whether it is one sauce under two names or two sauces, our single generic 'Signature Sauce' will not match what a customer sees in the ingredient list.
- Trademark marks are stripped: the board renders 'Bacon Turkey Bravo®', 'Toasted Frontega Chicken®' and 'You Pick Two®'. Minor, but the ® is how people recognise the flagship items.
- The two Asiago Bagel Stacks live in our `entrees` bucket alongside soups and stuffers; the board files them under Sandwiches → Hot Sandwiches. A user hunting for a sandwich will not find them.
- Our category label 'Soups, Mac, Stuffers & Bagel Stacks' corresponds to no heading Panera uses. The real headings are 'Soups & Mac', 'Salad Stuffers' (inside Salads), and 'Hot Sandwiches'.
- Panera calls the format 'You Pick Two®' — our formats file has the id right but the customer-facing shorthand at the counter and on item cards is 'YP2'.

---

## Subway — NEEDS_WORK

### How you actually order

You do NOT build a Subway sub from parts the way Loadout models it. You name a sandwich and a length, then subtract and add. The board is a grid of ~24 named subs grouped Steak / Chicken / Italians / Deli Classics / Clubs / Local Favorites, plus a $4.99 Sub of the Day, a $6.99 Meal of the Day, and a $3.99 "6-inch Deli Faves" value row. Note the Subway Series numbers (#1–#15) are GONE — nobody says "give me a number 7" anymore; the live 2026 board is all names again.

The real sequence, in order:

1. FORMAT + SUB + SIZE, all in one breath. "Lemme get a footlong Spicy Italian." Online this is even more explicit: Sandwiches, Protein Bowls, Wraps, Salads and Breakfast are five separate top-level categories, and each one carries the SAME roster of named subs. So format is picked before anything else, then the sub, then size (6-inch or footlong — the counter always asks, there is no silent default).
2. BREAD. "What bread?" They pull the roll and hinge-cut it.
3. CHEESE. Asked at the front of the line, not the back — because cheese has to be on before the toaster. As of a ~2026 policy change, cheese now goes onto the bread BEFORE the meat.
4. MEAT goes on. This is the moment "50% extra protein" is offered — it is Subway's headline upsell and is pushed on every sub in the app.
5. "TOASTED?" The single most iconic question at Subway, and it is asked of literally every sandwich. Bread + cheese + meat go through together. Zero macro impact, but leaving it out of the walk makes the whole thing feel un-Subway.
6. Sandwich slides down the line, frequently to a SECOND employee. VEGGIES. Most customers say "all the veggies" or "everything" rather than listing.
7. SAUCES / condiments — "anything else on it? Salt, pepper, oregano?" (Under the 2026 build order the sauce physically goes down before the veg, but it is still the last thing you're asked.)
8. Wrapped and cut. "Cut it in half? Into four?"
9. REGISTER: "Chips and a drink? Make it a meal?" Chips and cookies are the impulse layer, and the $6.99 Meal of the Day is a headline board item.

Caveat on confidence: I scraped the live store menu successfully, but subway.com blocked both the browser and WebFetch before I could open the in-app Customize screen, so I could not read the customizer's own section headings verbatim. Steps 2–7 are reconstructed from the counter build order (employee-sourced) rather than from the app UI. Treat the exact app section ordering as unverified.

### Sizes

Two axes, and we've modeled the wrong one at the item level.

(1) THE REAL SIZE SYSTEM IS SANDWICH LENGTH: 6-inch vs Footlong. It is chosen when you name the sub, not when you pick bread, and it is a clean 2× — every single component doubles, and Subway's own nutrition doc instructs you to double the 6-inch values for a footlong. On the live board, Footlong is the headline price and 6-inch is the value option (it even has its own $3.99 "6-inch Deli Faves" row). Verified arithmetically on the store menu: Cold Cut Combo is 520 cal in the 6" Deli Faves row and 1040 cal in the Sandwiches row; Ham & Salami 510 / 1020; Spicy Pepperoni 520 / 1030. Exactly 2×.

(2) A vestigial MINI tier survives on the kids' menu only. It is not a bread flavor and no adult customer is ever offered it.

Wraps, Salads and Protein Bowls have NO size at all — one size each. There is no default length: the counter always asks "6-inch or footlong?", though Footlong is what every board and promo leads with.

What's wrong in our model: (a) 6-inch and Footlong are two separate FORMATS in subway.formats.json that duplicate the entire prompt list verbatim — same breads subset, same protein prompt, same cheese prompt — differing only by portionMultiplier. A user picking a restaurant sees two near-identical cards. This should be ONE "Sandwich" format with a 6"/Footlong size chip, exactly the way the counter asks it. (b) The two Mini rolls sit inside the bread picker as if Mini Artisan Italian were a peer of Artisan Italian. It isn't — it's the same bread at kids' size, and it should be a size tier, not a row.

- **Artisan Italian Bread** — default 6-inch: 6-inch (`subway.breads.artisan-italian`), Mini (`subway.breads.mini-artisan-italian`)
- **Hearty Multigrain Bread** — default 6-inch: 6-inch (`subway.breads.hearty-multigrain`), Mini (`subway.breads.mini-hearty-multigrain`)
- **Chocolate Chip Cookie** — default Single: Single (`subway.extras.chocolate-chip-cookie`), Footlong (`subway.extras.footlong-chocolate-chip-cookie`)

### House configurations

- **50% Extra Protein ("double meat", "Deluxe")**. Subway's single biggest macro lever and its headline upsell — offered at the counter on every sub and pushed hard in the app. Despite being marketed as "+50%", an employee spelled out the actual mechanic: it adds exactly one more 6-inch portion of the same meat. A footlong is normally 2 scoops (or 12 slices of turkey); "extra protein" makes it 3 scoops / 18 slices. So on a 6-inch it is literally double meat, and on a footlong it is +50%. Costs roughly $3–5. Note two real-world exclusions an employee flagged: you cannot get extra meat on flatbread or on the Fresh Fit Turkey & Ranch. This is THE thing a macro-tracking user at Subway wants and it is completely unexpressible in our model right now — every protein row is a boolean, so there is no way to say "turkey, but two portions".
  - maps to: `subway.proteins.oven-roasted-turkey`, `subway.proteins.black-forest-ham`, `subway.proteins.roast-beef`, `subway.proteins.tuna`, `subway.proteins.rotisserie-style-chicken`, `subway.proteins.grilled-chicken`, `subway.proteins.grilled-chicken-teriyaki-glazed`, `subway.proteins.steak`, `subway.proteins.meatballs`, `subway.proteins.pastrami`, `subway.proteins.cold-cut-combo-meats`, `subway.proteins.all-american-club-meats`, `subway.proteins.subway-club-meats`
  - **gap:** A quantity / portion-multiplier control on protein rows. The entire convention is 'the same item, one more time' — there is no new ingredient to add, only a count. Our selectionRule for proteins is selectMany (boolean per item), so 'extra turkey' is currently unrepresentable.
- **Protein Bowl**. A permanent top-level category on the board (not a salad, not an off-menu hack) — the sandwich with no bread, served in a bowl, carrying the FOOTLONG meat portion. Employees describe it as 2 scoops; 3 scoops gets rung up as 'protein bowl plus a six-inch portion'. It is the highest-protein, lowest-carb thing at Subway and it is exactly what a macro-tracking user comes looking for. It prices ~$2–3 above the same sub as a Salad, which is consistent with the extra meat portion. We model a 'salad' format with no portion multiplier, which is Subway's Salad — a different, cheaper SKU. The Protein Bowl is missing entirely.
  - maps to: `subway.proteins.grilled-chicken`, `subway.proteins.oven-roasted-turkey`, `subway.proteins.steak`, `subway.proteins.roast-beef`, `subway.veggies.lettuce`, `subway.veggies.spinach-baby`, `subway.cheeses.monterey-cheddar-shredded`, `subway.sauces.peppercorn-ranch`
  - **gap:** The Protein Bowl format itself (no bread + 2× protein). Our formats file has six-inch-sandwich, footlong, wrap and salad — no bowl.
  - **gap:** The 2× protein rule that defines it.
- **"All the veggies" / "Everything on it"**. The dominant way people order the back half of the line — one phrase instead of nine taps. Standard set is lettuce, tomatoes, cucumbers, green peppers, onions, pickles, black olives, jalapeños and banana peppers. It does NOT include avocado (upcharge, and a running joke that customers tack it on last) and does not include spinach (spinach is an alternative to lettuce, not an addition). Macro delta is genuinely small — every veggie in the set is 0–5 cal — but it changes carbs a few grams and, more importantly, it is one gesture in the real world and nine in our app. Worth shipping as a one-tap preset on the veggies station.
  - maps to: `subway.veggies.lettuce`, `subway.veggies.tomatoes`, `subway.veggies.cucumbers`, `subway.veggies.green-peppers`, `subway.veggies.onions`, `subway.veggies.pickles-crinkle`, `subway.veggies.olives-black`, `subway.veggies.jalapeno-peppers`, `subway.veggies.banana-peppers`
- **Extra / double cheese**. Subway's default cheese portion is 2 triangles on a 6-inch and 4 on a footlong — that is what our cheese macros already represent. 'Extra cheese' or 'double cheese' doubles it and is one of the most common single modifiers, worth +80 to +110 cal and +7 to +9 g fat on a 6-inch. Historical note that supports how normal this is: the retired Subway Series subs all shipped with double cheese by default, which is part of why they cost more — and an employee notes most staff didn't know, so people were quietly getting single. Like extra protein, this is a count, not a new ingredient.
  - maps to: `subway.cheeses.american`, `subway.cheeses.provolone`, `subway.cheeses.pepper-jack`, `subway.cheeses.monterey-cheddar-shredded`
  - **gap:** A quantity control on cheese rows — same structural gap as extra protein.
- **Make it a Meal (chips + drink)**. The $6.99 Meal of the Day is a headline category on the board, and 'chips and a drink?' is asked at the register on a large share of orders. The chips are not incidental — they run 130–260 cal each and are listed with calorie counts right on the menu. For a macro app this is a routine, board-level addition that changes the total by a couple hundred calories, and we have no chip items at all. (Drinks are correctly excluded per project convention; chips are food and should not be.)
  - maps to: `subway.extras.chocolate-chip-cookie`
  - **gap:** Lay's Classic (240 cal)
  - **gap:** Doritos Nacho Cheese (260 cal)
  - **gap:** SunChips Harvest Cheddar (210 cal)
  - **gap:** Miss Vickie's Jalapeño (210 cal)
  - **gap:** Lay's BBQ (230 cal)
  - **gap:** Lay's Salt & Vinegar (230 cal)
  - **gap:** Lay's Baked Original (130 cal)
  - **gap:** Lay's Baked BBQ (140 cal)
  - **gap:** Simply Cheetos Puffs White Cheddar (200 cal)
  - **gap:** The meal-combo concept itself
- **Chicken & Bacon Ranch — the standard build** — ON by default. An example of the biggest structural gap: at Subway a named sub IS a recipe, and the recipe is knowledge the nutrition PDF never gives you. Chicken & Bacon Ranch is chicken + bacon + shredded Monterey cheddar + peppercorn ranch, toasted — the shredded cheese and the ranch are part of the sub, not choices. A customer who taps 'Chicken & Bacon Ranch' expects those four things to land at once. Our menu can compose it from parts but a user has to already know the recipe to do so. Same story for Steak Philly (steak + green peppers + onions + cheese, always toasted), B.M.T. (salami + pepperoni + ham), Spicy Italian (pepperoni + salami), Meatball (meatballs + marinara + cheese) and about twenty more.
  - maps to: `subway.proteins.rotisserie-style-chicken`, `subway.proteins.bacon`, `subway.cheeses.monterey-cheddar-shredded`, `subway.sauces.peppercorn-ranch`
  - **gap:** The named sub as a preset/recipe. We have three bundled meat blends (cold-cut-combo-meats, all-american-club-meats, subway-club-meats) but no equivalent for B.M.T., Spicy Italian, 5 Meat Italian, Meatball, Steak Philly, Chipotle Philly, Chicken & Bacon Ranch, Sweet Onion Chicken Teriyaki, Honey Mustard, Turkey & Ham, or the four Fresh Fit subs.

### Station order

Our order is `breads → proteins → cheeses → veggies → sauces → extras`. The real line is close but off in three places, and one of them changed recently.

1. CHEESE SHOULD MOVE AHEAD OF PROTEIN. Cheese is asked at the front station because it has to be on the sandwich before the toaster — the standard is "bread and cheese toasted." Subway also pushed a build-order change roughly two months ago that makes cheese go onto the bread BEFORE the meat. Multiple employees in that thread confirm it is real policy ("makes for a cleaner build", "helps the meat receive most of the heat"), while noting older staff and managers still do it the old way when asked. Recommend: `breads → cheeses → proteins`.

2. A "TOASTED?" STEP IS MISSING ENTIRELY, and it belongs between proteins and veggies. It carries zero macros, which is presumably why it was dropped, but it is the most recognizable question in the entire chain — you are asked it every single visit, on every single sandwich, including the ones where it makes no sense (there is a whole r/subway thread about people toasting tuna and cold cuts). A Subway walk without a toaster prompt does not read as Subway. Suggest a zero-macro toggle rather than a station.

3. SAUCES vs VEGGIES — hedge. The same 2026 policy change also moved sauce ahead of veggies in the physical build. But the customer is still ASKED for veggies first and sauces last ("anything else on it?"), and adherence to the new order is admittedly patchy. I would leave `veggies → sauces` as-is; the change is about where the squeeze bottle lands, not about the question sequence.

4. EXTRAS IS CORRECTLY LAST but is mislabeled conceptually — it is the register upsell, not a station on the line. Cookies, chips and applesauce are handed over after the sandwich is wrapped. Framing it as "Make it a meal?" would match reality better than a sixth build station.

One more thing that sits above all of this: at Subway, FORMAT and SIZE are chosen before you reach any station at all. Online, Sandwiches / Protein Bowls / Wraps / Salads / Breakfast are five sibling top-level categories each carrying the identical sub roster. Our formats layer handles this, but 6-inch and Footlong being two separate format cards means the very first choice a user makes is one the counter treats as a single "6-inch or footlong?" question.

### Missing staples

- Italian Herbs & Cheese bread — almost certainly the most-ordered bread at Subway and completely absent. Our dataSource note says it was dropped because it isn't in the January 2026 nutrition PDF, but that is a gap in the document, not the board: Lay's launched a co-branded 'Subway Italian Herbs & Cheese' potato chip two months ago, which nobody licenses for a discontinued bread. This is the highest-priority single omission in the whole file.
- Mozzarella (shredded) cheese — same story, excluded for not appearing in the PDF. It is the default cheese on Meatball and a standard option on the board.
- Bagged chips, all nine SKUs, confirmed live with calorie counts: Lay's Classic (240), Doritos Nacho Cheese (260), SunChips Harvest Cheddar (210), Miss Vickie's Jalapeño (210), Lay's BBQ (230), Lay's Salt & Vinegar (230), Lay's Baked Original (130), Lay's Baked BBQ (140), Simply Cheetos Puffs White Cheddar (200). These are food, not drinks, and they are half of the $6.99 Meal of the Day.
- Protein Bowl as a format — permanent top-level category, no bread, footlong meat portion. The single most macro-relevant thing on the Subway menu and we don't have it.
- Breakfast as a format — Bacon Egg & Cheese, Steak Egg & Cheese, Egg & Cheese, Black Forest Ham Egg & Cheese, plus all four as wraps. We have the egg patty and hash browns as components but no daypart to assemble them in.
- Personal Cheese Pizza (700 cal) — its own permanent category on the board.
- 6 Pack Cookie Box ($5.00) — a standing item in Snacks, Sides & Desserts.
- Named subs as presets — Steak Philly, Chipotle Philly, Chicken & Bacon Ranch, Honey Mustard, Sweet Onion Chicken Teriyaki, Grilled Chicken, B.M.T., Spicy Italian, 5 Meat Italian, Meatball Pepperoni, Meatball, Ham & Salami, B.L.T., Spicy Pepperoni, Veggie Delite, Turkey & Ham, plus the four Fresh Fit subs (Grilled Chicken & Avocado, Ham & Turkey Stacker, Turkey & Ranch Delite, Seasoned Steak & Avocado). Deliberately excluded per the dataSource note, and components-first is more defensible at Subway than at most chains — but this is the surface people actually order from.
- Honey Oat bread — long-standing regional bread, also excluded for PDF absence. Lower confidence than Italian Herbs & Cheese; I could not confirm it on the 2026 board.
- Light Mayonnaise — excluded for PDF absence; commonly still available and a meaningful macro swap against full mayo (100 cal / 11 g fat).
- Possible removals to check, not additions: Rotisserie-Style Chicken and Pastrami did not appear anywhere on the live 2026 store board, and neither did the Footlong Cookie (the cookie case is Chocolate Chip, White Chip Macadamia Nut, Oatmeal Raisin, Raspberry Cheesecake, Double Chocolate). Buffalo Sauce is in our file and Buffalo Chicken was confirmed discontinued by a customer who tracked it. Worth verifying before shipping.

### Naming

- subway.proteins.steak — we call it "Steak (no cheese)". The board says "Steak". Nobody has ever said "steak, no cheese" out loud; the parenthetical is a nutrition-document disambiguator that leaked into a customer-facing label.
- subway.cheeses.monterey-cheddar-shredded — we call it "Monterey Cheddar, Shredded". Customers say "shredded cheese", full stop. The verbatim customer order in the 210-upvote thread is literally "double meat, shredded cheese". Lead with "Shredded Cheese".
- subway.breads.hearty-multigrain — we call it "Hearty Multigrain Bread". A large share of customers say "wheat". If someone types or scans for wheat they will find nothing.
- subway.breads.artisan-italian — we call it "Artisan Italian Bread". At the counter people say "Italian" or "white".
- subway.breads.artisan-flatbread — we call it "Artisan Flatbread". Everyone, customers and staff, says "flatbread".
- subway.proteins.grilled-chicken-teriyaki-glazed — we call it "Grilled Chicken, Sweet Onion Teriyaki Glazed". The board says "Sweet Onion Chicken Teriyaki®". This is one of Subway's most recognizable sub names and our version is unrecognizable as it.
- subway.proteins.cold-cut-combo-meats / all-american-club-meats / subway-club-meats — these read as internal SKUs. On the board they are the sandwiches themselves: "Cold Cut Combo®", "All American Club®" (no hyphen — we have "All-American"), "Subway Club®". The trailing word "Meats" and the parenthetical ingredient lists are backstage vocabulary.
- subway.proteins.bacon / pepperoni / genoa-salami — we bake serving counts into the names: "Bacon (2 strips)", "Pepperoni (3 slices)", "Genoa Salami (3 slices)". The board says Bacon, Pepperoni, Salami. Same problem across the veggies: "Tomatoes (3 wheels)", "Cucumbers (3 slices)", "Green Peppers (3 strips)", "Pickles, Crinkle (3 chips)", "Jalapeño Peppers (3 rings)", "Banana Peppers (3 rings)", "Olives, Black (3 rings)". Counts belong in servingDescription, which already has them — they're duplicated into the name.
- Inverted-comma naming throughout the veggies and cheeses: "Spinach, Baby", "Olives, Black", "Pickles, Crinkle", "Parmesan, Grated", "Avocado, Sliced", "Avocado, Smashed". Nobody says "olives, black". These read like a spreadsheet sort key.
- subway.veggies.avocado-sliced vs avocado-smashed — the board just says "Avocado". Presenting two avocados as separate rows forces a choice the counter never offers.
- subway.sauces.olive-oil-blend, olive-oil-blend-and-vinegar, red-wine-vinegar — three overlapping rows for what is said as one thing: "oil and vinegar". A customer asking for oil and vinegar cannot tell which of the three to tap, and tapping the wrong pair double-counts or under-counts the oil.
- subway.breads.wrap-pocket-9-inch — we call it '9" Wrap (Pocket)'. On the board the product is "Protein Pockets", which is currently running as a LIMITED TIME ONLY line. Also worth noting: our formats file lets you pick it inside the generic "Wrap" format, which is not how it is sold.
- subway.breads.wrap-12-inch — we call it '12" Wrap'. The board just says "Wrap"; the size is not something customers choose or say.
- subway.breads.mini-artisan-italian / mini-hearty-multigrain — "Mini ... Bread" reads as a bread flavor sitting next to the real breads. It is the kids' menu size, and no adult is ever offered it.
- subway.extras.raspberry-cheesecake-cookie — we call it "Naturally Flavored Raspberry Cheesecake Cookie". The cookie case says "Raspberry Cheesecake". The regulatory qualifier doesn't belong in the tappable name.
- subway.extras.applesauce — the board item is "GoGo squeeZ® Apple Apple", a branded pouch. "Applesauce" is close enough to find but won't match what's printed.
- subway.sauces.subkrunch — correct and current (good sign the file was built from a fresh source), but it is a crunchy topping, not a sauce. It sitting in "Sauces & Condiments" alongside mayo will read oddly. Same for subway.sauces.giardiniera and subway.sauces.cheddar-cheese-sauce.

---

## Sweetgreen — NEEDS_WORK

### How you actually order

There is exactly ONE custom product: "Create Your Own" (category "Custom", customType: BOWL). There is no Create Your Own Salad, no Create Your Own Wrap, no Create Your Own Plate — everything else on the board is a named recipe you then modify. Our formats file inventing three parallel builders (custom-salad-bowl / warm-grain-bowl / wrap) does not match reality.

Two flow variants are live right now. LEGACY (NYC, Chicago, Boston, Austin, Seattle, Miami):
1. Bases — min 1, max 2 units, same base can be taken twice. Greens and grains are in ONE list together (Chopped Romaine, Organic Shredded Kale, Organic Spring Mix, Organic Baby Spinach, Organic Arugula, Wild Rice, Golden Quinoa, White Rice).
2. Toppings — max 10, helper "First four are included". Proteins are NOT here.
3. Premiums — max 7. THIS IS WHERE PROTEIN LIVES, mixed in with avocado, egg, cheeses, hummus, warm veg.
4. Dressings — max 3, allowMultipleQuantity false (no dupes), helper "Portions + details on next page".
5. Bread — max 1, single item "Bread".
Then a dedicated second screen: "How would you like your dressing?" → On the side / Mixed in, plus a Light / Medium / Heavy weight radio per dressing.

NEW, already rolled out in LA and DC (feature flag CELS-5026-customization-upsell-pricing-enabled, paired INCLUDED/EXTRAS groups merged in the UI):
1. Bases (min 1, max 2)
2. Mains — helper "1 main is included." max 1, then Extra Mains max 3. Contents: Blackened Chicken, Roasted Chicken, Avocado, Roasted Tofu, Warm Roasted Sweet Potatoes, Warm Portobello Mix, Hard Boiled Egg, Miso Glazed Salmon, Caramelized Garlic Steak.
3. Toppings — "First four are included.", then Extra Toppings max 6. The cheeses (Shaved Parmesan, Feta Crumble, White Cheddar) and Napa Cabbage Slaw moved OUT of Premiums into Toppings here.
4. Premiums — now a short paid list only: Peaches, Hummus, Goat Cheese, Parmesan Crisps, Crumbled Bacon, Summer Vegetable Medley, Apple Kimchi Sauce.
5. Dressings → 6. Bread → dressing detail screen.

Named recipes use format-specific group sets. Wraps: Bases max 1 (not 2) → Toppings max 4 → Mains max 3 → Premiums max 3 → "Dressings (Mixed-in)" max 2, helper "Select one full portion or two half portions" → "Dressings (On the side)" max 1, helper "Our chefs think wraps taste best with a dip." → Tortilla (min 1, max 1, free 1 — auto-included). Protein Plates: Bases are GRAINS ONLY (Wild Rice / Golden Quinoa / White Rice), max 2, no Bread step, and dressing is forced on the side ("For optimal freshness, dressing for plates are served on the side."). Kids Meals have no Bases group at all.

### Sizes

Sweetgreen has NO size system. No S/M/L, no Tall/Grande, no ounce tiers, no piece counts, no half-vs-full salad. One bowl, one price band, everywhere. Nothing in our menu is one dish at several sizes, so there is nothing to collapse.

What exists instead is a PORTION system, which is a different axis and is the thing our model actually can't express:
(a) The base allowance is 2 units. The bowl's greens portion is defined as 2 base units, not 1. Every green in our JSON is one unit — I verified servingMeasure in the live API matches our grams exactly (Romaine 140 g, Kale 70 g, Spring Mix 70 g, Spinach 60 g, Arugula 60 g), while the API's headline ingredient calorie for a green is exactly 2x ours because it quotes a full 2-unit portion. Grains are quoted per unit (Wild Rice 95 g / 155 cal = ours exactly). If a customer selects only one base the app throws a modal: "Heads up - only 1 base portion selected. You can get a full portion by adding another base. Are you sure you'd like to continue?"
(b) Every ingredient has a Single / Double / Triple quantity stepper (portionLabel: 1=Single, 2=Double, 3=Triple). Double protein, double chickpeas, double avocado are all first-class.
(c) Dressings have a pour weight: Light / Medium / Heavy, mapped in code to 1 / 2 / 3 portions.
Kids Meals (Little Harvest, Mini Mezze, Ranchy Chicken + Rice) are separate products with their own smaller modifier groups, not a size of the adult bowl.


### House configurations

- **The Full Base (two base units)**. A sweetgreen bowl's base is TWO units, not one. You pick up to 2 from a single combined greens+grains list, and you may take the same one twice. The three normal shapes: double the same green (a "full portion of kale"), one green + one grain (the Harvest Bowl build), or double grain (the Protein Plate build). Our JSON's per-item macros are ONE unit, so a Loadout build that adds a single green is silently modeling half a bowl of greens. Verified against live product calorie totals: Kale Caesar 510 cal = half-Romaine + half-Kale (2 units total); Harvest Bowl 760 cal = 1 unit kale + 1 unit wild rice; Caramelized Garlic Steak plate 770 cal = wild rice counted TWICE.
  - maps to: `sweetgreen.bases.chopped-romaine`, `sweetgreen.bases.shredded-kale`, `sweetgreen.bases.spring-mix`, `sweetgreen.bases.baby-spinach`, `sweetgreen.bases.arugula`, `sweetgreen.bases.wild-rice`, `sweetgreen.bases.golden-quinoa`, `sweetgreen.bases.white-rice`
  - **gap:** Quantity/repeat support on the bases station — selectMany can add each base once, so 'double kale' (2 units of one green) is unrepresentable
  - **gap:** A 'you have only 1 of 2 base units' nudge, which is the real app's behavior
  - **gap:** Our formats file splits bases into two prompts (greens required, warm grain optional) — the real flow is one list with a shared 2-unit budget, so Loadout lets a user take 5 greens plus 3 grains
- **Mixed-in dressing is a DOUBLE pour** — ON by default. When dressing is mixed into the bowl (the tossed-salad experience), the default weight is Medium, and Medium is hard-coded as TWO portions. So a mixed-in Balsamic Vinaigrette is 420 cal / 44 g fat, not the 210 cal / 22 g our JSON lists. Light = 1x, Medium = 2x, Heavy = 3x. If you pick two mixable dressings, each one drops to Light (1x each) rather than doubling up — so 'two dressings' is not double dressing, it's the same total as one. Dressing served on the side is 1 portion each, and you can dial up to 3 total portions on the side.
  - maps to: `sweetgreen.dressings.balsamic-vinaigrette`, `sweetgreen.dressings.caesar`, `sweetgreen.dressings.green-goddess-ranch`, `sweetgreen.dressings.charred-jalapeno-ranch`, `sweetgreen.dressings.pesto-vinaigrette`, `sweetgreen.dressings.spicy-cashew`, `sweetgreen.dressings.lime-cilantro-jalapeno-sauce`, `sweetgreen.dressings.sweetgreen-hot-sauce`, `sweetgreen.dressings.hot-honey-mustard-sauce`, `sweetgreen.dressings.miso-sesame-ginger`, `sweetgreen.dressings.citrus-sesame-vinaigrette`, `sweetgreen.dressings.honey-bbq-sauce`, `sweetgreen.dressings.kbbq-dressing`, `sweetgreen.dressings.garlic-aioli`, `sweetgreen.dressings.extra-virgin-olive-oil`, `sweetgreen.dressings.balsamic-vinegar`
  - **gap:** A Light / Medium / Heavy pour selector on each dressing (1x / 2x / 3x multiplier on that item's macros)
  - **gap:** A bowl-level 'Mixed in vs On the side' toggle that flips the default pour from 1x to 2x
  - **gap:** The 'two dressings each go Light' rule, so adding a second dressing should halve the first rather than stack
- **Wraps get dressing TWICE — mixed in plus a dip** — ON by default. Every wrap ships with dressing inside AND a second dressing on the side as a dip, by default. The Classic Chicken Caesar's default ingredient list literally contains Caesar twice — that is +160 cal of dressing a per-ingredient build would never account for. Wraps also differ structurally: base is max 1 unit (not 2), toppings capped at 4, and the tortilla is a separate auto-included group.
  - maps to: `sweetgreen.bases.tortilla`, `sweetgreen.dressings.caesar`, `sweetgreen.dressings.charred-jalapeno-ranch`, `sweetgreen.dressings.green-goddess-ranch`
  - **gap:** A second dressing slot on the wrap format labeled 'dip on the side', distinct from the mixed-in dressing
  - **gap:** The wrap-specific rule that the base is 1 unit, not 2
- **The included build: 1 main + 4 toppings** — ON by default. A Create Your Own at base price includes 2 base units, ONE main (protein/avocado/egg/tofu/warm veg), FOUR toppings, dressing, and optional bread. Toppings 5+ are $0.65 each, extra mains $2.25-$6.55. That is the shape of the regular order — a Loadout default build that dumps in eight toppings is not what anyone actually walks out with, and one that has zero protein isn't either.
  - maps to: `sweetgreen.proteins.roasted-chicken`, `sweetgreen.proteins.blackened-chicken`, `sweetgreen.proteins.caramelized-garlic-steak`, `sweetgreen.proteins.miso-glazed-salmon`, `sweetgreen.proteins.roasted-tofu`, `sweetgreen.premiums.avocado`, `sweetgreen.premiums.hard-boiled-egg`, `sweetgreen.premiums.warm-roasted-sweet-potatoes`, `sweetgreen.premiums.warm-portobello-mix`
  - **gap:** A free-quantity budget on the toppings station (first 4 included) so the UI can show 4-of-4 used
  - **gap:** A 'Mains' station that treats avocado, hard boiled egg, warm portobello and warm sweet potatoes as protein-tier picks — right now they sit in premiums and read as garnish
- **Protein Plate = double grain, no greens, dressing on the side** — ON by default. The Protein Plates are not salads. Their base list is grains only, and the house build is TWO units of the same grain — the Caramelized Garlic Steak plate's default is Wild Rice listed twice (310 cal of grain, not 155). Because there is no green base, dressing can never be mixed in; it always comes on the side at 1x. There is no bread step on a plate.
  - maps to: `sweetgreen.bases.wild-rice`, `sweetgreen.bases.golden-quinoa`, `sweetgreen.bases.white-rice`, `sweetgreen.proteins.caramelized-garlic-steak`, `sweetgreen.proteins.miso-glazed-salmon`
  - **gap:** A 'Protein Plate' format: grain-only base at 2 units, no greens prompt, no bread, dressing pinned to 1x on the side
  - **gap:** Our formats file's 'warm-grain-bowl' offers greens as an optional add — on a real plate greens are not on the menu at all
- **Double protein**. Ordering the protein twice is a normal, first-class order — the quantity stepper offers Single / Double / Triple and the protein group allows repeats. Doubling roasted chicken is +110 cal / +23 g protein; doubling steak is +220 cal / +25 g protein. This is probably the single most common macro-relevant modification a Loadout user would want to express and it's the same gesture that would fix the base-unit problem.
  - maps to: `sweetgreen.proteins.roasted-chicken`, `sweetgreen.proteins.blackened-chicken`, `sweetgreen.proteins.caramelized-garlic-steak`, `sweetgreen.proteins.miso-glazed-salmon`, `sweetgreen.proteins.roasted-tofu`
  - **gap:** Per-item quantity (1x/2x/3x) anywhere in the builder — every station in our JSON is selectMany with an implicit quantity of 1

### Station order

Close, but two real problems.

Ours: bases → ingredients → premiums → proteins → dressings → sides.
Real (universal): Bases → Toppings → Premiums → Dressings → Bread.
Real (LA + DC, rolling out): Bases → Mains → Toppings → Premiums → Dressings → Bread.

1. PROTEINS IS IN THE WRONG PLACE, and it's in the wrong place in both directions. In legacy markets there is no protein station at all — chicken, steak, salmon and tofu are line items inside Premiums, alongside goat cheese and hummus. In the markets sweetgreen is migrating to, protein got promoted to its own step called "Mains" positioned SECOND, immediately after Bases and before Toppings. Nowhere is protein a separate station sitting after premiums, which is what we do. Move proteins to slot 2 (right after bases), rename the station "Mains", and it matches where sweetgreen is going while still being defensible against the legacy line.

2. FOUR ITEMS ARE FILED UNDER THE WRONG STATION. In the new structure sweetgreen moved these out of Premiums:
   → into Mains: sweetgreen.premiums.avocado, sweetgreen.premiums.hard-boiled-egg, sweetgreen.premiums.warm-portobello-mix, sweetgreen.premiums.warm-roasted-sweet-potatoes. These are what a vegetarian picks as their "1 included main", not garnishes.
   → into Toppings: sweetgreen.premiums.shaved-parmesan, sweetgreen.premiums.feta-crumble, sweetgreen.premiums.white-cheddar, sweetgreen.premiums.napa-cabbage-slaw.
   What actually remains a Premium: hummus, goat cheese, parmesan crisps, crumbled bacon, apple kimchi sauce, summer vegetable medley, peaches.

3. Minor: our "sides" station is doing two jobs. In the build flow the last step is literally named "Bread" and contains exactly one item (sweetgreen.sides.bread). Rosemary Focaccia and Hummus + Focaccia are not part of that step — they're à-la-carte items from the separate Sides menu you add as a second line item. Splitting "Bread" (in-build, max 1) from "Sides" (separate order) would mirror the real thing.

4. One thing I could NOT verify: the physical in-store makeline script. Reddit and all forum sources were unreachable and my search budget was gone, so I have no independent read on whether counter staff walk you base→protein→toppings→dressing in that spoken order, or whether they toss the bowl with dressing by default. Everything above is from the digital flow, which sweetgreen builds from the same modifier-group data the makeline screens use, but I'd treat the spoken in-store sequence as unconfirmed.

### Missing staples

- Mint — a standard topping, present in all 8 stores across all 6 markets I checked (2 g portion)
- Garlic Parm Crunch — standard topping in all 8 stores (13 g, 60 cal, 4 g protein). Distinct from Garlic Breadcrumbs, which we do have; sweetgreen carries both simultaneously
- Peaches — Premiums list at all 8 stores (31 g, 10 cal). Summer item but currently live everywhere, and it appears to be what replaced our Summer Tomatoes
- Lemon Tarragon Vinaigrette — in the Dressings list at all 8 stores (40 g, 160 cal). It's the FIRST dressing shown in the picker at every location, so it's a headline option, not a fringe one
- Roasted Sweet Potatoes + Hot Honey Mustard — permanent item on the Sides menu (350 cal). We have neither of the two sweet potato sides
- Roasted Sweet Potatoes + Green Goddess Ranch — permanent item on the Sides menu (360 cal)
- Olive Oil Tortilla as a standalone side (320 cal) — we only carry the tortilla as a base, which is not how sweetgreen sells it
- Also worth noting the reverse: sweetgreen.premiums.summer-tomatoes and sweetgreen.dressings.tomato-vinaigrette appear at ZERO of the 8 stores I checked. They look like last season's items that have since been swapped for Peaches and Lemon Tarragon Vinaigrette

### Naming

- Category 'Ingredients' → the app and the makeline both call this station 'Toppings'. Nobody at sweetgreen says 'ingredients'. This is our most visible naming mismatch since it's a station header.
- 'Arugula' → 'Organic Arugula'. Same for 'Baby Spinach' → 'Organic Baby Spinach', 'Spring Mix' → 'Organic Spring Mix', 'Shredded Kale' → 'Organic Shredded Kale'. All four greens carry the Organic prefix on the board and in the app; Chopped Romaine is the only green that does not.
- 'Shredded Carrots' → the menu says 'Raw Carrots'. Different word, and a user scanning for 'raw' or hunting under S won't find it.
- 'Tortilla' filed under Bases → the board says 'Olive Oil Tortilla', and it is not a base you choose. It only exists as (a) an auto-included component of the four named wraps and (b) an à-la-carte item on the Sides menu. A user looking at our Bases station will think they can build a wrap from scratch; they can't.
- Proteins are all listed on sweetgreen's board with qualifiers: 'Antibiotic-Free Blackened Chicken', 'Antibiotic-Free Roasted Chicken', 'Antibiotic-Free Miso Glazed Salmon', 'Antibiotic-Free Grass-Fed Caramelized Garlic Steak'. Our short names are what a person actually says out loud, so I would keep them as the display name — but they won't string-match the board or the app, which matters if we ever reconcile against sweetgreen data or let users search.
- 'Bread' under Sides → correct for the in-build step (the group is literally named 'Bread'), but misleading as a Sides entry: there is no plain 'Bread' on sweetgreen's Sides menu. The Sides menu breads are Rosemary Focaccia and Hummus + Focaccia.
- 'Roasted Sweet Potatoes' (ingredients, 39 g) vs 'Warm Roasted Sweet Potatoes' (premiums, 72 g) — this pair is genuinely correct and matches the real menu exactly, but it reads like a duplicate. Worth a note in the UI so users don't think it's a bug.
- Our formats are named 'Custom Salad Bowl' / 'Warm Grain Bowl' / 'Wrap'. On sweetgreen there is exactly one custom entry point and it is called 'Create Your Own', sitting in a category called 'Custom'. Saying 'I'll do a custom salad bowl' at the counter isn't a thing; 'create your own' is.

---
