# Component data — the flagship four

Per-component macros so a configured item can be added to and removed from by
arithmetic rather than guesswork. The published item total is AS SERVED and
already includes its defaults, so each component below is what that part
contributes and removing it is a subtraction.

`DERIVED` means the figure came from subtracting two published totals — the
arithmetic is shown. Nothing here is estimated; what could not be established
is in the gaps list and is therefore **not removable**.

## chick-fil-a — `top_down_configuration` (confidence high)

11 configured items · 36 components priced · 9 gaps

### Components

| Component | kcal | P | C | F | Source |
|---|---|---|---|---|---|
| Cobb Salad base (no bell peppers, no dressing) | 440 | 39 | 22 | 22 | DERIVED |
| Grilled sandwich base (multigrain brioche bun + grilled filet, as built) | 380 | 28 | 43 | 11 | DERIVED |
| Cool Wrap without dressing | 350 | 42 | 29 | 13 | DERIVED |
| Avocado Lime Ranch Dressing | 310 | 1 | 3 | 32 | published |
| Creamy Salsa Dressing | 290 | 1 | 2 | 31 | published |
| Spicy Filet | 280 | 23 | 16 | 13 | published |
| Garden Herb Ranch Dressing | 280 | 1 | 2 | 29 | published |
| Chick-fil-A Filet (fried) | 250 | 24 | 12 | 12 | published |
| Sausage Patty | 240 | 11 | 1 | 22 | published |
| Spicy Southwest Salad base (no toppings, no dressing) | 240 | 27 | 15 | 7 | DERIVED |
| Zesty Apple Cider Vinaigrette Dressing | 230 | 0 | 16 | 19 | published |
| Multigrain Brioche Bun | 210 | 7 | 38 | 4 | published |
| Buttery White Bun | 180 | 5 | 29 | 6 | published |
| Gluten Free Bun | 180 | 3 | 37 | 4 | published |
| Chick-fil-A Breakfast Filet | 160 | 15 | 8 | 8 | published |
| Side Salad base (no dressing) | 160 | 5 | 11 | 10 | DERIVED |
| White Bun (Unbuttered) | 150 | 5 | 28 | 1 | published |
| Spicy Breakfast Filet | 150 | 15 | 7 | 7 | published |
| Grilled Filet | 110 | 21 | 1 | 2 | published |
| Fat-Free Honey Mustard Dressing | 90 | 0 | 22 | 0 | published |
| Colby Jack Cheese | 80 | 5 | 0 | 7 | published |
| Pepper Jack Cheese | 80 | 4 | 0 | 6 | published |
| Light Balsamic Vinaigrette Dressing | 80 | 0 | 10 | 4 | published |
| Crispy Red Bell Peppers | 80 | 1 | 6 | 6 | published |
| Chili Lime Pepitas | 80 | 4 | 2 | 7 | published |
| Harvest Nut Granola | 70 | 1 | 10 | 2 | published |
| Seasoned Tortilla Strips | 70 | 1 | 8 | 4 | published |
| Roasted Nut Blend | 70 | 1 | 2 | 6 | published |
| Grilled Breakfast Filet | 60 | 13 | 0 | 1 | published |
| American Cheese | 50 | 3 | 1 | 4 | published |
| Applewood Smoked Bacon | 50 | 4 | 0 | 4 | published |
| Blue Cheese Crumbles | 30 | 2 | 0 | 2 | published |
| Light Italian Dressing | 25 | 0 | 3 | 1 | published |
| Green Leaf Lettuce | 5 | 0 | 1 | 0 | published |
| Tomato | 5 | 0 | 1 | 0 | published |
| Dill Pickle Chips | 0 | 0 | 0 | 0 | published |

### Configured items

- **`chick-fil-a.entrees.chick-fil-a-chicken-sandwich`** — 420 cal as served
  - includes: Buttery White Bun, Chick-fil-A Filet (fixed), Pickles (2 dill chips)
  - addable: white-bun-unbuttered, multigrain-brioche-bun, gluten-free-bun, american-cheese, colby-jack-cheese, pepper-jack-cheese, bacon, lettuce, tomato
- **`chick-fil-a.entrees.spicy-chicken-sandwich`** — 450 cal as served
  - includes: Buttery White Bun, Spicy Filet (fixed), Pickles (2 dill chips)
  - addable: white-bun-unbuttered, multigrain-brioche-bun, gluten-free-bun, american-cheese, colby-jack-cheese, pepper-jack-cheese, bacon, lettuce, tomato
- **`chick-fil-a.entrees.chick-fil-a-deluxe-sandwich`** — 490 cal as served
  - includes: Buttery White Bun, Chick-fil-A Filet (fixed), Pickles (2 dill chips), Lettuce, Tomato, American Cheese (default cheese for this sandwich)
  - addable: colby-jack-cheese, pepper-jack-cheese, bacon, white-bun-unbuttered, multigrain-brioche-bun, gluten-free-bun
- **`chick-fil-a.entrees.spicy-deluxe-sandwich`** — 540 cal as served
  - includes: Buttery White Bun, Spicy Filet (fixed), Pickles (2 dill chips), Lettuce, Tomato, Pepper Jack Cheese (default cheese for this sandwich)
  - addable: american-cheese, colby-jack-cheese, bacon, white-bun-unbuttered, multigrain-brioche-bun, gluten-free-bun
- **`chick-fil-a.entrees.grilled-chicken-sandwich`** — 390 cal as served
  - includes: Multigrain brioche bun + grilled filet (unsplittable block - see dataGaps) (fixed), Lettuce, Tomato
  - addable: american-cheese, colby-jack-cheese, pepper-jack-cheese, bacon
- **`chick-fil-a.entrees.grilled-chicken-club-sandwich`** — 520 cal as served
  - includes: Multigrain brioche bun + grilled filet (unsplittable block - see dataGaps) (fixed), Lettuce, Tomato, Colby Jack Cheese (default cheese for this sandwich), Applewood Smoked Bacon
  - addable: american-cheese, pepper-jack-cheese
- **`chick-fil-a.entrees.chick-fil-a-cool-wrap`** — 660 cal as served
  - includes: Cool Wrap without dressing (flatbread, grilled chicken, lettuce/cabbage, Monterey-Cheddar blend) (fixed), Avocado Lime Ranch Dressing (built in - counted in the 660)
  - addable: garden-herb-ranch-dressing, zesty-apple-cider-vinaigrette, creamy-salsa-dressing, light-italian-dressing, light-balsamic-vinaigrette, fat-free-honey-mustard-dressing
- **`chick-fil-a.mains.cobb-salad-base`** — 830 cal as served
  - includes: Cobb Salad greens + nuggets + egg/bacon/cheese/corn/tomato (no bell peppers, no dressing) (fixed), Crispy Bell Peppers, Avocado Lime Ranch Dressing (designated dressing, counted in the 830)
  - addable: blue-cheese-crumbles, garden-herb-ranch-dressing, fat-free-honey-mustard-dressing, light-balsamic-vinaigrette, zesty-apple-cider-vinaigrette, creamy-salsa-dressing, light-italian-dressing
- **`chick-fil-a.mains.market-salad-base`** — 550 cal as served
  - includes: Harvest Nut Granola, Blue Cheese Crumbles, Roasted Almonds (60 Cal published; full macros NOT published - see dataGaps) (fixed), Zesty Apple Cider Vinaigrette (designated dressing, counted in the 550)
  - addable: avocado-lime-ranch-dressing, garden-herb-ranch-dressing, fat-free-honey-mustard-dressing, light-balsamic-vinaigrette, creamy-salsa-dressing, light-italian-dressing
- **`chick-fil-a.sides.side-salad`** — 470 cal as served
  - includes: Side Salad greens, Monterey-Cheddar blend, grape tomatoes (no dressing) (fixed), Avocado Lime Ranch Dressing (designated dressing, counted in the 470)
  - addable: garden-herb-ranch-dressing, fat-free-honey-mustard-dressing, light-balsamic-vinaigrette, zesty-apple-cider-vinaigrette, creamy-salsa-dressing, light-italian-dressing
- **`NEW:spicy-southwest-salad`** — 680 cal as served
  - includes: Spicy Southwest Salad greens + grilled filet + cheese/corn/black beans/tomato (no toppings, no dressing) (fixed), Seasoned Tortilla Strips, Chili Lime Pepitas, Creamy Salsa Dressing (designated dressing, counted in the 680)
  - addable: blue-cheese-crumbles, avocado-lime-ranch-dressing, garden-herb-ranch-dressing, fat-free-honey-mustard-dressing, light-balsamic-vinaigrette, zesty-apple-cider-vinaigrette, light-italian-dressing

### Gaps — not removable until sourced

- MULTIGRAIN BRIOCHE BUN INSIDE THE GRILLED SANDWICHES. The published a-la-carte bun (210 cal, 38g carb, 4.5g fat, 71g) plus Grilled Filet (110, 1, 2, 84g) plus lettuce plus tomato sums to 330 cal / 41g carb / 6.5g fat, but the Grilled Chicken Sandwich board total is 390 / 45 / 11. A 60 cal, 4g carb, 4.5g fat residual is unaccounted for even though the gram weights balance (205g calculated vs 206g published). The same residual appears identically in the Grilled Chicken Club and Grilled Club w/ No Cheese. CONSEQUENCE: do not offer bun removal or bun swaps on the Grilled Chicken Sandwich or the Grilled Chicken Club — ship bun+filet as the unsplittable `grilled-sandwich-bun-filet-base`. Lettuce, tomato, cheese and bacon add/remove on top of that block ARE exact and remain safe.
- ROASTED ALMONDS (Market Salad include). The Market Salad page declares 'Roasted Almonds — 60 Cal' as a default, but the nutrition-allergens table has no row for it. The only nut row published is 'Roasted Nut Blend' (10g, 70/1/2/6), which is a DIFFERENT item with a different calorie figure, so it cannot stand in. Protein/carb/fat for Roasted Almonds are unknown. CONSEQUENCE: do not let people remove Roasted Almonds from the Market Salad, and the Market Salad base cannot be fully decomposed (its calorie base is 550 - 230 - 70 - 30 - 60 = 160, but its macro base is indeterminate).
- PICKLES MACRO ROW. Calories are published as '0 Cal' (both in the Chicken Sandwich `includes` and `extras` arrays), but there is no gram-level protein/carb/fat row anywhere on the official site. I set them to 0 because a declared 0-calorie component forces that, not from an outside estimate — but be aware the underlying row does not exist.
- JALAPEÑOS (5 Cal), HONEY packet (25 Cal), and WRAPPED IN LETTUCE (5 Cal) appear as addable modifiers in the Chicken Sandwich `extras` array with calories only. No macro rows are published for any of them. I have deliberately omitted all three from `components` rather than invent splits.
- MODIFIER LISTS ARE PUBLISHED FOR ONLY SOME ITEMS. Only the Chick-fil-A Chicken Sandwich, the three Honey Pepper Pimento sandwiches, the Hash Brown Scramble Bowl, and the Cobb / Market / Spicy Southwest salads carry a `cfa-pdp-store` with explicit `includes` and `extras` arrays. The Spicy Chicken Sandwich, both Deluxes, the Grilled Chicken Sandwich, the Grilled Chicken Club, the Cool Wrap and the Side Salad have NO such array. Their default components above are established by exact arithmetic and by product copy, and their `addableComponents` lists are carried over from the sibling sandwich that does publish one — treat those specific add lists as inferred, not declared.
- COOL WRAP DRESSING MEMBERSHIP IS INFERRED, NOT DECLARED. Unlike the salads, the Cool Wrap page has no `includes` array stating that Avocado Lime Ranch is counted in the 660. The inference rests on the dressing appearing in the wrap's own ingredient list, on the 231g serving weight matching wrap + a 57g dressing packet, and on 45g of fat being unreachable without it. Confidence is high but it is not a published decomposition — if we let people remove the dressing we are trusting a derivation.
- OUR MENU STORES SALADS DRESSING-FREE, WHICH CONFLICTS WITH THE AS-SERVED RULE. chick-fil-a.mains.cobb-salad-base carries 520 cal, chick-fil-a.mains.market-salad-base carries 320, and chick-fil-a.sides.side-salad carries 160. The board figures are 830, 550 and 470 respectively. Under the top-down model these items need their as-served totals restored with the dressing (and topping packets) modeled as removable defaults, otherwise adding a dressing in the builder double-counts nothing but removing one is impossible.
- SPICY SOUTHWEST SALAD (680 cal as served) is a current menu item that our JSON does not carry at all — filed above as NEW:spicy-southwest-salad.
- BOARD FIGURE FOR THE CHICKEN SANDWICH IS 420, NOT 440. The task brief cited 440. Every current official surface — the item page, the nutrition-allergens table (183g serving), and the component arithmetic (bun 180 + filet 250 + pickles 0) — gives 420/29/41/18. Our menu's 420 is correct; the 440 figure is stale.

---

## raising-canes — `quantity_first` (confidence high)

6 configured items · 12 components priced · 12 gaps

### Components

| Component | kcal | P | C | F | Source |
|---|---|---|---|---|---|
| Chicken Sandwich (whole, atomic) | 830 | 47 | 69 | 41 | published |
| Crinkle-Cut Fries (a la carte / Caniac portion) | 400 | 5 | 50 | 20 | published |
| Crinkle-Cut Fries (3 Finger / Box / Sandwich combo portion) | 310 | 4 | 39 | 15 | DERIVED |
| Crinkle-Cut Fries (Kids Combo portion) | 200 | 3 | 23 | 9 | DERIVED |
| Cane's Sauce | 190 | 0 | 6 | 18 | published |
| Texas Toast (as served, buttered) | 150 | 4 | 23 | 4 | published |
| Honey Mustard | 140 | 0 | 16 | 8 | published |
| Chicken Finger | 130 | 13 | 5 | 7 | published |
| Coleslaw | 100 | 1 | 10 | 6 | published |
| Kraft Mayonnaise | 90 | 0 | 0 | 10 | published |
| Ketchup | 35 | 0 | 8 | 0 | published |
| Louisiana Hot Sauce | 0 | 0 | 0 | 0 | published |

### Configured items

- **`NEW:3-finger-combo`** — 1050 cal as served
  - includes: Chicken Fingers (fixed), Crinkle-Cut Fries (combo portion), Texas Toast, Cane's Sauce
  - addable: chicken-finger, canes-sauce, honey-mustard, ketchup, texas-toast, coleslaw, louisiana-hot-sauce, kraft-mayonnaise
- **`NEW:box-combo`** — 1290 cal as served
  - includes: Chicken Fingers (fixed), Crinkle-Cut Fries (combo portion), Texas Toast, Coleslaw, Cane's Sauce
  - addable: chicken-finger, canes-sauce, honey-mustard, ketchup, texas-toast, coleslaw, louisiana-hot-sauce, kraft-mayonnaise
- **`NEW:caniac-combo`** — 1840 cal as served
  - includes: Chicken Fingers (fixed), Crinkle-Cut Fries (full regular portion), Texas Toast, Coleslaw, Cane's Sauce
  - addable: chicken-finger, canes-sauce, honey-mustard, ketchup, texas-toast, coleslaw, louisiana-hot-sauce, kraft-mayonnaise
- **`NEW:sandwich-combo`** — 1140 cal as served
  - includes: Chicken Sandwich (3 fingers, Cane's Sauce, lettuce, toasted bun) (fixed), Crinkle-Cut Fries (combo portion)
  - addable: chicken-finger, canes-sauce, honey-mustard, ketchup, texas-toast, coleslaw, louisiana-hot-sauce, kraft-mayonnaise
- **`NEW:kids-combo`** — 650 cal as served
  - includes: Chicken Fingers (fixed), Crinkle-Cut Fries (kids portion), Cane's Sauce
  - addable: chicken-finger, canes-sauce, honey-mustard, ketchup, texas-toast, coleslaw
- **`raising-canes.entrees.chicken-sandwich`** — 830 cal as served
  - includes: Chicken Fingers (inside the sandwich) (fixed)
  - addable: canes-sauce, honey-mustard, ketchup, louisiana-hot-sauce, kraft-mayonnaise

### Gaps — not removable until sourced

- TEXAS TOAST BUTTER DELTA (the headline ask) — UNRESOLVED. The July 2025 PDF contains exactly ONE Texas Toast row (1.7 oz / 150 cal / 4.5 fat / 23 carbs / 4 protein) and no unbuttered, dry, or 'no butter' variant anywhere in the document; the menu page likewise lists only '150 Cal per slice'. There is no published pair to subtract, so the cost of the butter cannot be established. Do NOT let users remove butter from Texas Toast. (Note also that the 23 g carbs / 4 g protein of the toast are almost entirely the bread, so any butter delta is a pure fat-and-calorie figure we simply do not have.)
- CHICKEN SANDWICH INTERNALS — the menu page states the sandwich is 3 Chicken Fingers + Cane's Sauce + Lettuce + Toasted Bun, but Cane's publishes no row for the bun, the lettuce, or the in-sandwich sauce portion (which is a squeeze, not a 1.5 oz cup). Subtracting a 190-cal sauce cup from the sandwich would be an invention. Treat the sandwich as atomic: no removing sauce, bun or lettuce.
- CHICKEN SANDWICH CALORIE CONFLICT — the nutrition PDF says 830 Cal; https://www.raisingcanes.com/menu/ says 'SANDWICH — 780 Cal per sandwich'. Both are first-party and both are current as of this run. I used 830 because it is the only figure carrying a full macro row, and the Sandwich Combo derivation (1140-830=310) is what makes fries-combo cross-check cleanly against the 3 Finger and Box combos — so 830 is the internally consistent figure. Worth re-checking at the next PDF refresh.
- COMBO FRIES IS NOT AN OFFICIALLY NAMED SIZE — Cane's publishes one 'Crinkle-Cut Fries' row (400 cal). The arithmetic shows the 3 Finger, Box and Sandwich combos carry roughly 310-330 cal of fries while the Caniac carries a full ~430. Every combo's carb figure reconciles EXACTLY under this split (39 g in the three smaller combos, 50 g in the Caniac), so the split is real, but Cane's never labels it. The fries-combo and fries-kids components are DERIVED, and which combo gets which size is inferred from arithmetic rather than stated. If Loadout wants to be conservative, gate fries removal on the derived figure being flagged as an estimate-by-subtraction.
- CANIAC COMBO HAS ~30 CAL OF UNEXPLAINED RESIDUAL — re-summing 6 fingers + full regular fries + toast + coleslaw + 2 sauces gives 1810 cal / 108.5 fat / 125 carbs / 88 protein against a published 1840 / 108 / 125 / 90. Carbs are exact and fat is within 0.5 g, but calories run 30 low and protein 2 low. Any component subtraction from the Caniac inherits that ~30 cal / 2 g protein of slop.
- PARTIAL SAUCE PORTIONS — only the full 1.5 oz (43 g) cup is published. 'Light sauce', a half cup, or sauce-on-the-side-in-a-smaller-cup have no figures. Sauce can only be added or removed in whole 190-cal cups.
- 'BOX COMBO - THE POSTY WAY' (1740 cal / 89 fat / 173 carbs / 66 protein) appears in the PDF but its composition is published nowhere on the menu page. The 450-cal / 75-carb / 54-sugar gap over a standard Box Combo implies it bundles a sweetened drink and extra sauce, but I could not confirm the contents, so it cannot be decomposed. Excluded from configuredItems.
- KID'S COMBO REGIONAL VARIANTS — the PDF carries separate rows for 'Kid's Combo (Louisville, KY)' 610 cal and 'Kid's Combo (Maryland)' 420 cal with materially different macros (Maryland is 16 g fat vs 41 g standard, implying a non-fried or no-sauce formulation). Their component lists are not published, so they cannot be decomposed. The standard Kids Combo decomposition above does not apply to them.
- NO LARGE / UPSIZED FRIES FIGURE — Cane's publishes no upsized fries row, so 'make it a large fry' cannot be priced.
- NO REGIONAL OR LIMITED-TIME DIPS — the July 2025 PDF's CONDIMENTS section lists only Cane's Sauce, Honey Mustard, Ketchup, Louisiana Hot Sauce and Kraft Mayonnaise (plus sugar/sweetener/salt/pepper/lemon, all 0-10 cal). Any BBQ or seasonal sauce a store may carry has no published figure.
- HONEY MUSTARD PROTEIN prints as '< 1 g' rather than a number; recorded as 0.5 g (midpoint). This is the only non-verbatim macro value in the component set.
- TAILGATES HAVE NO PUBLISHED COMBINED TOTAL — Cane's deliberately publishes them per-unit only. A 25-finger Tailgate total would have to be computed as 25x130 + 8x190; that arithmetic is sound off published per-unit rows but there is no board figure to anchor asServedCalories to, so Tailgates are modelled as a quantityRule rather than a configuredItem.

---

## starbucks — `recipe_with_modifiers` (confidence medium)

49 configured items · 23 components priced · 16 gaps

### Components

| Component | kcal | P | C | F | Source |
|---|---|---|---|---|---|
| 2% Milk, cold, full cup | 260 | 17 | 25 | 10 | published |
| Vanilla Protein Cold Foam | 255 | 17 | 13 | 16 | DERIVED |
| 2% Milk, steamed, full cup | 200 | 13 | 19 | 8 | published |
| Salted Caramel Cream Cold Foam | 195 | 2 | 16 | 14 | DERIVED |
| Chocolate Cream Cold Foam | 195 | 3 | 16 | 14 | DERIVED |
| 2% Milk as poured into a Grande hot latte | 180 | 12 | 17 | 7 | DERIVED |
| 2% Milk as poured into a Grande iced latte | 120 | 7 | 11 | 4 | DERIVED |
| Strawberry Açaí Refresher Base + water | 90 | 0 | 23 | 0 | published |
| Vanilla Sweet Cream (dairy) | 65 | 1 | 4 | 5 | DERIVED |
| Nondairy (Oatmilk/Soymilk) Vanilla Sweet Cream | 55 | 1 | 4 | 4 | DERIVED |
| Lemonade (as the liquid that replaces water in a tea or Refresher) | 50 | 0 | 12 | 0 | DERIVED |
| Coconutmilk (as poured into a Refresher, replacing the water) | 50 | 0 | 5 | 2 | DERIVED |
| Whipped Cream (espresso-cup dollop, as on Espresso Con Panna) | 25 | 0 | 0 | 2 | DERIVED |
| Vanilla Syrup | 20 | 0 | 5 | 0 | DERIVED |
| Caramel Syrup | 20 | 0 | 5 | 0 | DERIVED |
| Espresso Shot (Signature or Blonde Roast) | 5 | 0 | 1 | 0 | published |
| Brewed Coffee / Cold Brew (unsweetened, black) | 5 | 1 | 0 | 0 | published |
| Cold Brew Coffee (unsweetened, black) | 5 | 0 | 0 | 0 | published |
| Sugar-Free Vanilla Syrup | 0 | 0 | 0 | 0 | DERIVED |
| Sugar-Free Caramel Syrup | 0 | 0 | 0 | 0 | DERIVED |
| Brewed Tea (black, green, herbal — unsweetened) | 0 | 0 | 0 | 0 | published |
| Hot or cold water | 0 | 0 | 0 | 0 | published |
| Ice | 0 | 0 | 0 | 0 | published |

### Configured items

- **`starbucks.hot-coffee.caffe-latte`** — 190 cal as served
  - includes: 2% Milk (steamed, Grande latte pour) (fixed), Espresso Shot (Signature Roast) (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump, sugar-free-caramel-syrup-pump
- **`starbucks.hot-coffee.cappuccino`** — 140 cal as served
  - includes: 2% Milk (steamed + foam, Grande cappuccino pour) (fixed), Espresso Shot (Signature Roast) (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump, sugar-free-caramel-syrup-pump
- **`starbucks.hot-coffee.blonde-vanilla-latte`** — 250 cal as served
  - includes: 2% Milk (steamed) (fixed), Blonde Espresso Shot (fixed), Vanilla Syrup
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.hot-coffee.caffe-mocha`** — 370 cal as served
  - includes: 2% Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Mocha Sauce, Whipped Cream
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, mocha-sauce-pump
- **`starbucks.hot-coffee.white-chocolate-mocha`** — 390 cal as served
  - includes: 2% Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), White Chocolate Mocha Sauce, Whipped Cream
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, white-chocolate-mocha-sauce-pump
- **`starbucks.hot-coffee.caramel-macchiato`** — 250 cal as served
  - includes: 2% Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Vanilla Syrup, Caramel Drizzle
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.hot-coffee.cinnamon-dolce-latte`** — 340 cal as served
  - includes: 2% Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Cinnamon Dolce Syrup, Whipped Cream, Cinnamon Dolce Sprinkles
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.hot-coffee.flat-white`** — 220 cal as served
  - includes: Whole Milk (steamed, Grande flat white pour) (fixed), Ristretto Espresso Shot (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.hot-coffee.cortado`** — 90 cal as served
  - includes: Whole Milk (steamed, Short cortado pour) (fixed), Ristretto Espresso Shot (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.hot-coffee.caffe-americano`** — 15 cal as served
  - includes: Espresso Shot (Signature Roast) (fixed), Hot Water (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.hot-coffee.caffe-misto`** — 110 cal as served
  - includes: Brewed Coffee (half) (fixed), 2% Milk (steamed, half cup) (fixed)
  - addable: vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.hot-coffee.steamed-milk`** — 200 cal as served
  - includes: 2% Milk (steamed, full Grande cup) (fixed)
  - addable: vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.hot-coffee.hot-chocolate`** — 370 cal as served
  - includes: 2% Milk (steamed) (fixed), Mocha Sauce, Whipped Cream, Mocha Drizzle
  - addable: espresso-shot, vanilla-syrup-pump, mocha-sauce-pump
- **`starbucks.hot-coffee.vanilla-protein-latte`** — 310 cal as served
  - includes: Protein-boosted Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Vanilla Syrup
  - addable: espresso-shot, vanilla-syrup-pump, sugar-free-vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.hot-coffee.sugar-free-vanilla-protein-latte`** — 230 cal as served
  - includes: Protein-boosted Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Sugar-Free Vanilla Syrup
  - addable: espresso-shot, sugar-free-vanilla-syrup-pump, vanilla-syrup-pump
- **`starbucks.hot-coffee.caramel-protein-latte`** — 320 cal as served
  - includes: Protein-boosted Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Caramel Syrup
  - addable: espresso-shot, caramel-syrup-pump, sugar-free-caramel-syrup-pump, vanilla-syrup-pump
- **`starbucks.hot-coffee.sugar-free-caramel-protein-latte`** — 230 cal as served
  - includes: Protein-boosted Milk (steamed) (fixed), Espresso Shot (Signature Roast) (fixed), Sugar-Free Caramel Syrup
  - addable: espresso-shot, sugar-free-caramel-syrup-pump, caramel-syrup-pump
- **`starbucks.cold-coffee.iced-caffe-latte`** — 130 cal as served
  - includes: 2% Milk (cold, Grande iced latte pour) (fixed), Espresso Shot (Signature Roast) (fixed), Ice
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.cold-coffee.iced-blonde-vanilla-latte`** — 190 cal as served
  - includes: 2% Milk (cold) (fixed), Blonde Espresso Shot (fixed), Vanilla Syrup, Ice
  - addable: espresso-shot, vanilla-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.cold-coffee.iced-caffe-mocha`** — 350 cal as served
  - includes: 2% Milk (cold) (fixed), Espresso Shot (Signature Roast) (fixed), Mocha Sauce, Whipped Cream, Ice
  - addable: espresso-shot, vanilla-syrup-pump, mocha-sauce-pump
- **`starbucks.cold-coffee.iced-white-chocolate-mocha`** — 390 cal as served
  - includes: 2% Milk (cold) (fixed), Espresso Shot (Signature Roast) (fixed), White Chocolate Mocha Sauce, Whipped Cream, Ice
  - addable: espresso-shot, vanilla-syrup-pump, white-chocolate-mocha-sauce-pump
- **`starbucks.cold-coffee.iced-caramel-macchiato`** — 250 cal as served
  - includes: 2% Milk (cold) (fixed), Espresso Shot (Signature Roast) (fixed), Vanilla Syrup, Caramel Drizzle, Ice
  - addable: espresso-shot, vanilla-syrup-pump, sugar-free-vanilla-syrup-pump
- **`starbucks.cold-coffee.iced-cinnamon-dolce-latte`** — 300 cal as served
  - includes: 2% Milk (cold) (fixed), Espresso Shot (Signature Roast) (fixed), Cinnamon Dolce Syrup, Whipped Cream, Cinnamon Dolce Sprinkles, Ice
  - addable: espresso-shot, vanilla-syrup-pump
- **`starbucks.cold-coffee.iced-shaken-espresso`** — 100 cal as served
  - includes: Espresso Shot (Signature Roast) (fixed), Classic Syrup, 2% Milk (splash), Ice
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.cold-coffee.iced-brown-sugar-oatmilk-shaken-espresso`** — 150 cal as served
  - includes: Blonde Espresso Shot (fixed), Brown Sugar Syrup, Oatmilk, Cinnamon Powder, Ice
  - addable: espresso-shot, vanilla-syrup-pump
- **`starbucks.cold-coffee.cold-brew`** — 5 cal as served
  - includes: Cold Brew Coffee (fixed), Ice
  - addable: vanilla-syrup-pump, caramel-syrup-pump, sugar-free-vanilla-syrup-pump, vanilla-sweet-cream-tall-grande, nondairy-vanilla-sweet-cream-tall-grande, espresso-shot
- **`starbucks.cold-coffee.vanilla-sweet-cream-cold-brew`** — 110 cal as served
  - includes: Cold Brew Coffee (fixed), Vanilla Syrup, Vanilla Sweet Cream, Ice
  - addable: vanilla-syrup-pump, caramel-syrup-pump, espresso-shot
- **`starbucks.cold-coffee.nondairy-vanilla-sweet-cream-cold-brew`** — 100 cal as served
  - includes: Cold Brew Coffee (fixed), Vanilla Syrup, Nondairy (Oat/Soy) Vanilla Sweet Cream, Ice
  - addable: vanilla-syrup-pump, caramel-syrup-pump, espresso-shot
- **`starbucks.cold-coffee.vanilla-sweet-cream-nitro-cold-brew`** — 70 cal as served
  - includes: Nitro Cold Brew Coffee (fixed), Vanilla Sweet Cream
  - addable: vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.cold-coffee.salted-caramel-cream-cold-brew`** — 240 cal as served
  - includes: Cold Brew Coffee (fixed), Vanilla Syrup, Salted Caramel Cream Cold Foam, Ice
  - addable: vanilla-syrup-pump, espresso-shot
- **`starbucks.cold-coffee.chocolate-cream-cold-brew`** — 240 cal as served
  - includes: Cold Brew Coffee (fixed), Vanilla Syrup, Chocolate Cream Cold Foam, Ice
  - addable: vanilla-syrup-pump, espresso-shot
- **`starbucks.cold-coffee.vanilla-protein-cream-cold-brew`** — 300 cal as served
  - includes: Cold Brew Coffee (fixed), Vanilla Syrup, Vanilla Protein Cold Foam, Ice
  - addable: vanilla-syrup-pump, espresso-shot
- **`starbucks.cold-coffee.cold-milk`** — 260 cal as served
  - includes: 2% Milk (cold, full Grande cup) (fixed)
  - addable: vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.tea.chai-latte`** — 190 cal as served
  - includes: Chai Tea Concentrate (fixed), Classic Syrup, 2% Milk (steamed) (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.tea.matcha-latte`** — 220 cal as served
  - includes: Matcha Tea Powder (sweetened) (fixed), Classic Syrup, 2% Milk (steamed) (fixed)
  - addable: espresso-shot, vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.tea.london-fog-latte`** — 180 cal as served
  - includes: Earl Grey Tea Sachet (fixed), Vanilla Syrup, 2% Milk (steamed) (fixed)
  - addable: vanilla-syrup-pump, sugar-free-vanilla-syrup-pump, caramel-syrup-pump
- **`starbucks.tea.iced-black-tea`** — 0 cal as served
  - includes: Brewed Black Tea (fixed), Water, Ice
  - addable: lemonade-grande, classic-syrup-pump, vanilla-syrup-pump
- **`starbucks.tea.iced-black-tea-lemonade`** — 50 cal as served
  - includes: Brewed Black Tea (fixed), Lemonade (replaces the water), Ice
  - addable: classic-syrup-pump, vanilla-syrup-pump
- **`starbucks.refreshers.strawberry-acai-refresher`** — 90 cal as served
  - includes: Strawberry Açaí Base + water (fixed), Freeze-Dried Strawberries, Ice
  - addable: lemonade-grande, coconutmilk-refresher-grande, vanilla-syrup-pump
- **`starbucks.refreshers.pink-drink`** — 140 cal as served
  - includes: Strawberry Açaí Base (fixed), Coconutmilk (replaces the water), Freeze-Dried Strawberries, Ice
  - addable: vanilla-syrup-pump, lemonade-grande
- **`starbucks.refreshers.strawberry-acai-lemonade-refresher`** — 140 cal as served
  - includes: Strawberry Açaí Base (fixed), Lemonade (replaces the water), Freeze-Dried Strawberries, Ice
  - addable: vanilla-syrup-pump, coconutmilk-refresher-grande
- **`starbucks.frappuccino.coffee-frappuccino`** — 230 cal as served
  - includes: Whole Milk + Frappuccino Base (blended) (fixed), Frappuccino Roast Coffee
  - addable: whipped-cream-standard, vanilla-syrup-pump, caramel-syrup-pump, mocha-sauce-pump, espresso-shot
- **`starbucks.frappuccino.mocha-frappuccino`** — 370 cal as served
  - includes: Whole Milk + Frappuccino Base (blended) (fixed), Frappuccino Roast Coffee, Mocha Sauce, Whipped Cream
  - addable: vanilla-syrup-pump, caramel-syrup-pump, espresso-shot
- **`starbucks.frappuccino.caramel-frappuccino`** — 380 cal as served
  - includes: Whole Milk + Frappuccino Base (blended) (fixed), Frappuccino Roast Coffee, Caramel Syrup, Whipped Cream, Caramel Drizzle
  - addable: vanilla-syrup-pump, mocha-sauce-pump, espresso-shot
- **`starbucks.frappuccino.vanilla-bean-creme-frappuccino`** — 380 cal as served
  - includes: Whole Milk + Frappuccino Crème Base (blended) (fixed), Vanilla Bean Powder (fixed), Whipped Cream
  - addable: vanilla-syrup-pump, caramel-syrup-pump, mocha-sauce-pump, espresso-shot
- **`starbucks.frappuccino.caramel-ribbon-crunch-frappuccino`** — 470 cal as served
  - includes: Whole Milk + Frappuccino Base (blended) (fixed), Frappuccino Roast Coffee, Dark Caramel Sauce, Whipped Cream, Caramel Drizzle, Caramel Crunch Topping
  - addable: vanilla-syrup-pump, espresso-shot
- **`starbucks.frappuccino.mocha-cookie-crumble-frappuccino`** — 480 cal as served
  - includes: Whole Milk + Frappuccino Base (blended) (fixed), Frappuccino Roast Coffee, Mocha Sauce, Chocolate Chips, Whipped Cream, Mocha Drizzle, Cookie Crumble Topping
  - addable: vanilla-syrup-pump, espresso-shot
- **`starbucks.hot-coffee.espresso-doppio`** — 10 cal as served
  - includes: Espresso Shot (Signature Roast) (fixed)
  - addable: espresso-shot, whipped-cream-espresso-dollop, vanilla-syrup-pump, caramel-syrup-pump
- **`NEW:espresso-con-panna`** — 35 cal as served
  - includes: Espresso Shot (Signature Roast) (fixed), Whipped Cream (espresso dollop)
  - addable: espresso-shot

### Gaps — not removable until sourced

- WHIPPED CREAM ON A STANDARD (Tall/Grande/Venti) BEVERAGE — the single biggest gap, and the most-requested modification. Starbucks publishes no with/without pair for it. Bracketing attempts disagree too much to publish a number: Vanilla Crème Grande 350 minus Steamed Milk Grande 200 minus 4 pumps vanilla (80) = 70 cal / 5 C / 6 F, but that ignores the milk the whip and syrup displace; adding the displacement implied by Blonde Vanilla Latte 250 minus Caffè Latte 190 (4 pumps of syrup cost only 60 net, so each pump pushes out ~5 cal of milk) pushes it to ~90 cal. A third route (Cinnamon Dolce Latte 340 minus Blonde Vanilla Latte 250 = 90 cal / 8 F) also lands near 90 but bundles the cinnamon dolce sprinkles and assumes cinnamon dolce syrup equals vanilla syrup. Range 70-90 cal, 6-8 g fat. Do not let users subtract whipped cream from a mocha/Frappuccino until Starbucks publishes it. The espresso-dollop figure (25 cal, componentKey whipped-cream-espresso-dollop) is solid but is a different, smaller dose.
- MOCHA SAUCE per pump — no isolating pair exists. Three routes disagree: Caffè Mocha Grande 370 minus Caffè Latte Grande 190, net of whipped cream, implies ~27.5 cal/pump; Mocha Frappuccino 370 minus Coffee Frappuccino 230 implies ~22; Iced Caffè Mocha 350 minus Iced Caffè Latte 130 implies ~35. Every route needs the unknown whipped-cream figure as an input, so both stay unresolved together.
- WHITE CHOCOLATE MOCHA SAUCE per pump — same blockage. Only the relative figure is derivable: White Chocolate Mocha Grande 390 minus Caffè Mocha Grande 370 = 20 cal / 4 g carb / 2 g fat across 4 pumps, i.e. white chocolate sauce runs ~5 cal, ~1 g carb and ~0.5 g fat per pump ABOVE mocha sauce. Absolute value unknown.
- DARK CARAMEL SAUCE per pump (Caramel Ribbon Crunch Frappuccino) — no isolating pair.
- CINNAMON DOLCE SYRUP per pump — no isolating pair. Every Cinnamon Dolce drink also carries whipped cream and sprinkles. It very likely equals vanilla/caramel at 20 cal / 5 g carb (Starbucks uses one standard pump table for all syrups) but that is an inference, not a subtraction.
- BROWN SUGAR SYRUP per pump — the only vehicles (Iced Brown Sugar Oatmilk Shaken Espresso, Brown Sugar Oatmilk Cortado) change shot count and oatmilk volume across sizes at the same time, so no clean single-pump step exists.
- CLASSIC SYRUP (liquid cane sugar) per pump — attempted via Iced Protein Matcha minus Iced Sugar-Free Vanilla Protein Matcha, which differ only in classic vs sugar-free vanilla, but the three sizes imply 10, 16.7 and 20 cal per pump (Tall 150-130=20 over 2 pumps; Grande 260-210=50 over 3; Venti 420-340=80 over 4). Too inconsistent to publish. Carb side is tighter at ~4-4.5 g/pump. This blocks Chai Latte, Matcha Latte, Iced Shaken Espresso and the Crème Frappuccinos from being fully decomposed.
- CHAI TEA CONCENTRATE per pump — Chai Latte carries chai and classic syrup in lockstep at every size, so neither can be separated.
- MATCHA TEA POWDER per scoop — same lockstep problem with classic syrup in Matcha Latte; and the protein-matcha route inherits the unresolved classic syrup figure.
- MILK SUBSTITUTIONS (almondmilk, oatmilk, soymilk, coconutmilk, nonfat, whole, breve/half-and-half, heavy cream, protein-boosted milk) AS A LATTE BASE — Starbucks publishes one nutrition row per drink for the DEFAULT milk only, and the web ordering page does not recalculate when you change the milk selector (verified in-browser: Grande Caffè Latte stayed at 190 cal after switching to Oatmilk). Only the 2% pour is costed. Do not offer milk swaps as a macro edit. Partial handles that exist but do not generalise: coconutmilk in a Refresher (50 cal Grande, costed above); the dairy-vs-nondairy vanilla sweet cream delta (65 vs 55 cal, costed above).
- WHOLE MILK pour in a Flat White / Cortado / Frappuccino, PROTEIN-BOOSTED MILK pour in the protein lattes, OATMILK pour in the shaken espressos, and the 2% splash in an Iced Shaken Espresso — each appears only inside drinks whose other components are themselves uncosted, so no subtraction closes.
- CARAMEL DRIZZLE and MOCHA DRIZZLE — two routes contradict each other. Iced Caramel Macchiato Grande 250 minus Iced Caffè Latte Grande 130 minus 3 pumps vanilla (60) leaves 60 cal for the drizzle, while the hot pair (Caramel Macchiato 250 minus Caffè Latte 190 minus 60) leaves 0. Unresolvable from published data.
- TOPPINGS: cinnamon dolce sprinkles, caramel crunch topping, cookie crumble topping, coconut flakes, salted brown-buttery topping, chocolate chips, cinnamon powder — none can be isolated.
- FRAPPUCCINO BASE (the crème base syrup and Frappuccino Roast) — the Coffee Frappuccino total (Grande 230) bundles whole milk, ice, base syrup and Frappuccino Roast into one figure that cannot be split. It is treated here as a single unsplittable component key (frappuccino-creme-base-grande) with no macros of its own.
- VANILLA BEAN POWDER per scoop, STRAWBERRY PUREE, and the DRIED-FRUIT SCOOPS in the Refreshers — no isolating pairs.
- GENERAL ROUNDING CAVEAT — Starbucks rounds calories to the nearest 5 or 10 and macros to whole grams, so any single subtraction can carry +/-5 cal of noise. Every figure published above is backed by at least two independent subtractions that agree, except the two full-cup milk products (which are published outright) and the Grande latte milk pour.

---

## chipotle — `bottom_up_assembly` (confidence high)

6 configured items · 28 components priced · 13 gaps

### Components

| Component | kcal | P | C | F | Source |
|---|---|---|---|---|---|
| Chips (regular) | 540 | 7 | 73 | 25 | published |
| Flour Tortilla (burrito) | 320 | 8 | 50 | 9 | published |
| Queso Blanco (side) | 240 | 10 | 7 | 18 | published |
| Guacamole | 230 | 2 | 8 | 22 | published |
| Cilantro-Lime White Rice (Normal) | 210 | 4 | 40 | 4 | published |
| Cilantro-Lime Brown Rice (Normal) | 210 | 4 | 36 | 6 | published |
| Carnitas | 210 | 23 | 0 | 12 | published |
| Chipotle Honey Chicken | 210 | 21 | 13 | 8 | published |
| Chicken (adobo) | 180 | 32 | 0 | 7 | published |
| Double Protein upgrade (adds one more standard portion) | 180 | 32 | 0 | 7 | DERIVED |
| Beef Barbacoa | 170 | 24 | 2 | 7 | published |
| Steak | 150 | 21 | 1 | 6 | published |
| Sofritas | 150 | 8 | 9 | 10 | published |
| Black Beans | 130 | 8 | 22 | 2 | published |
| Pinto Beans | 130 | 8 | 21 | 2 | published |
| Queso Blanco (entrée portion) | 120 | 5 | 4 | 9 | published |
| Sour Cream | 110 | 2 | 2 | 9 | published |
| Cheese (Monterey Jack) | 110 | 6 | 1 | 8 | published |
| Cilantro-Lime Brown Rice — LIGHT portion | 110 | 2 | 18 | 3 | published |
| Cilantro-Lime White Rice — LIGHT portion | 100 | 2 | 20 | 2 | published |
| Cilantro Lime Sauce | 80 | 2 | 3 | 6 | published |
| Roasted Chili-Corn Salsa | 80 | 3 | 16 | 2 | published |
| Tomatillo-Red Chili Salsa | 30 | 0 | 4 | 0 | published |
| Fresh Tomato Salsa | 25 | 0 | 4 | 0 | published |
| Fajita Veggies | 20 | 1 | 5 | 0 | published |
| Supergreens Salad Mix | 15 | 1 | 3 | 0 | published |
| Tomatillo-Green Chili Salsa | 15 | 0 | 4 | 0 | published |
| Romaine Lettuce | 5 | 0 | 1 | 0 | published |

### Configured items

- **`NEW:veggie-entree-protein-slot`** — 230 cal as served
  - includes: Guacamole (4 oz) (fixed)
  - addable: chipotle.rice.cilantro-lime-white, chipotle.rice.cilantro-lime-brown, chipotle.beans.black, chipotle.beans.pinto, chipotle.salsa.fresh-tomato, chipotle.salsa.roasted-corn, chipotle.salsa.tomatillo-green, chipotle.salsa.tomatillo-red, chipotle.toppings.cheese, chipotle.toppings.sour-cream, chipotle.veggies.fajita-vegetables, chipotle.veggies.romaine, chipotle.toppings.queso-entree, NEW:topping-cilantro-lime-sauce
- **`NEW:double-high-protein-bowl`** — 760 cal as served
  - includes: Adobo Chicken, double portion (2 x 4 oz) (fixed), Light White Rice, Black Beans, Fajita Veggies, Fresh Tomato Salsa, Monterey Jack Cheese, Extra Lettuce (romaine) — multiplier NOT established, see dataGaps
  - addable: chipotle.toppings.guacamole, chipotle.toppings.queso-entree, NEW:topping-cilantro-lime-sauce, chipotle.toppings.sour-cream, chipotle.salsa.roasted-corn, chipotle.salsa.tomatillo-green, chipotle.salsa.tomatillo-red
- **`NEW:double-high-protein-burrito`** — 840 cal as served
  - includes: Flour Tortilla (burrito) (fixed), Adobo Chicken, double portion (2 x 4 oz) (fixed), Fajita Veggies, Fresh Tomato Salsa, Monterey Jack Cheese, Romaine Lettuce
  - addable: chipotle.toppings.guacamole, chipotle.toppings.queso-entree, NEW:topping-cilantro-lime-sauce, chipotle.toppings.sour-cream, chipotle.rice.cilantro-lime-white, chipotle.rice.cilantro-lime-brown, chipotle.beans.black, chipotle.beans.pinto
- **`NEW:high-protein-cup-chicken`** — 180 cal as served
  - includes: Adobo Chicken (4 oz side portion) (fixed)
- **`NEW:chips-and-guacamole`** — 770 cal as served
  - includes: Chips (regular, 4 oz) (fixed), Guacamole (4 oz) (fixed)
- **`NEW:chips-and-queso-blanco`** — 780 cal as served
  - includes: Chips (regular, 4 oz) (fixed), Queso Blanco (side, 4 oz) (fixed)

### Gaps — not removable until sourced

- EXTRA rice (white or brown). The ordering UI offers a free 'Extra' portion but Chipotle publishes no nutrition for it anywhere — not in the PDF, not in the nutrition calculator (the calculator has no portion control at all), and the ordering UI keeps showing the Normal 210 cal figure with only a badge change. The Double High Protein Bowl arithmetic pins light-rice + extra-lettuce JOINTLY at 115 cal and 2g protein, which cannot isolate an 'extra' multiplier. Do not offer 'extra rice' as a removable/addable delta.
- SIDE rice portion. Same portion control (Normal/Light/Extra/Side) but no published figure for the 'Side' size.
- EXTRA LETTUCE multiplier. The Double High Protein Bowl lists 'Extra Lettuce' and the calorie residual leaves 10-15 cal for it depending on whether light white rice is read as 100 cal (Chipotle's own published 2 oz row) or 105 cal (exactly half of 210). Both fit within rounding, so 2x vs 3x romaine is not established. I modelled it as quantity 2 in the configured item purely so the bowl's components are enumerable — do not treat that 2 as sourced.
- Light/Extra portions for every station OTHER than rice. I directly verified the portion control on rice (Normal/Light/Extra/Side), protein (Normal/Double only) and guacamole (Normal/Side only). I did not enumerate the kebab menu on beans, salsas, sour cream, cheese, fajita veggies or romaine. Whatever options those carry, no non-Normal nutrition is published for any of them.
- Cilantro Lime Sauce serving size. The 80 cal / 6g fat / 2g protein / 3g carb figure is published but the oz/fl-oz portion is not stated on the calculator, the build page, or any PDF (the sauce post-dates the OCT-2024 PDF). Fiber, sugar, sodium and allergens are also unpublished for it.
- Chipotle Honey Chicken portion size, fiber, sugar and sodium. Only 210 cal / 8g fat / 21g protein / 13g carbs is published. It is flagged LIMITED TIME, so it may vanish.
- Carne Asada appears to be STALE in our menu file. chipotle.protein.carne-asada (250/29/1/14) is not on the live nutrition calculator or the live ordering build page as of 2026-08-10, and it is not in the OCT-2024 PDF either. Recommend flagging it unavailable rather than trusting it.
- High Protein Taco (190 cal / 15g protein). The total is published but the per-taco sub-portions of chicken, cheese, fajita veggies and salsa are not — a single taco clearly gets less than the 4 oz entrée portions. Not modelable as removable components, so I excluded it from configuredItems.
- High Protein-Low Calorie Bowl (36g protein) and High Protein-High Fiber Bowl (46g protein, 14g fiber): Chipotle publishes protein and fiber but NO calorie total for these two, so they cannot be given an asServedCalories.
- All six High Protein Menu items were showing 'Temporarily Unavailable' on chipotle.com on 2026-08-10. Their published numbers are still the basis for the double-protein and light-rice derivations, but the items themselves may not be orderable.
- Taco shell nutrition is unresolved. The ordering UI shows CRISPY CORN TORTILLA 200 cal and SOFT FLOUR TORTILLA 250 cal, and those figures did NOT change when I switched QUANTITY from THREE TACOS to ONE TACO. They also do not reconcile with the PDF per-shell rows (70 cal crispy corn, 80 cal soft flour taco) at either 1x or 3x. Do not derive a per-taco shell cost from these.
- Veggie entrée has a source conflict. The printed PDF says 'VEGGIE 230 cal | 4 oz — Includes our fresh guacamole and your choice of beans' (230 = exactly the 4 oz guacamole), but the live nutrition calculator and build page both list VEGGIE at 0 cal and expect guacamole to be added separately from the toppings row. Pick one convention or you will double-count 230 cal. Note the guac is genuinely free in this case — the VEGGIE card is $9.35, same as chicken/sofritas, with no +$2.95.
- Prices were read at a single store (10 E Jackson Blvd, Chicago IL 60604). The FREE vs PAID *classification* is structural and consistent across the burrito-bowl and taco flows (tacos even split the UI into 'INCLUDED TOPPINGS — choose up to five' vs a separate 'ADD-ONS' group holding exactly cilantro lime sauce, guacamole and queso), but the dollar amounts are not national. Chipotle's own PDF footnote says '*Check local menu boards for pricing.'

---
