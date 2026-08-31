# CAVA flagship audit

Last checked: 2026-08-31

This is durable source and flow evidence, not a second backlog. Follow-up work
belongs on the Dayo Product OS item for CAVA.

## Sources

- Official nutrition page: <https://cava.com/nutrition>
- Current Nutrition and Allergen Guide: `KT5_26_AN_STND_RECAN11148`, created
  2026-06-15 and linked from the nutrition page
- Official ordering flow: <https://cava.com/menu>
- Store used for the public flow check: Streeterville, 270 E Ontario Street,
  Chicago, IL 60611

The downloadable guide is the macro authority. The ordering site is the
authority for the sequence, selection limits, and currently orderable menu.

## Public ordering sequence

1. Choose Pickup or Delivery. Pickup is the default.
2. Search by city, state, or ZIP, or use current location. Signing in is
   optional at this stage.
3. Select a store, then browse Featured, Build Your Own, Bowls, Pitas, Sides,
   Kids Meal, Drinks, and Desserts.
4. Build Your Own offers Greens + Grains Bowl, Grains Bowl, Salad Bowl, and
   Pita.
5. The builder keeps a live price and calorie total. Required choices keep Add
   to bag disabled.
6. Adding a valid item returns to the menu with the bag count updated. This
   audit stopped there, before checkout, sign-in, payment, or order submission.

## Builder rules observed

- Greens + Grains: one green and one grain, each shown as a half portion.
- Dips + Spreads: up to three scoops; selecting the same dip again adds another
  scoop.
- Mains: one full portion or two half portions. Extra mains are a separate
  action.
- Toppings: uncapped in the displayed instruction.
- Dressings: up to two.
- Sides, desserts, and drinks: optional.
- Pita does not offer a base/greens station. Its pita is implicit in the format.

Loadout's existing portion interaction already represents the main rule: one
protein is full, and selecting a second changes both to halves.

## 2026-08-31 data refresh

- Retired Sumac Sour Cream + Onion Pita Chips and added Harissa BBQ Pita Chips.
- Replaced Strawberry Citrus with Strawberry Ginger and updated its three size
  values.
- Removed Pineapple Apple Mint Juice and Tangerine Aleppo because they are no
  longer in the current guide.
- Kept the existing non-seasonal bases, mains, toppings, dips, dressings,
  desserts, and remaining drinks after a row-by-row guide comparison.
- Corrected the stored caps to three dips and two dressings.
- Added drinks to every guided format, removed bases from Pita, and corrected
  the Pita dip prompt.

Kids Meal components remain excluded for now. They use their own portions and
assembly path; adding the individual rows without the flow would imply support
the app does not yet provide.

## Source discrepancy requiring monitoring

At Streeterville, the live builder displayed 310 calories for the empty pita,
35 for tzatziki, and 45 for traditional hummus. The current downloadable guide
lists Whole Pita as 320, Tzatziki as 30, and Hummus as 50. Loadout retains the
guide values because CAVA's nutrition page explicitly presents that document as
the detailed nutrition source. Owner QA should compare the current native app
and one in-store nutrition view before treating the ordering-site figures as a
macro-source replacement.

## Remaining owner QA

- On a physical iPhone, compare the CAVA native app's Pickup flow with the web
  sequence above; App Store consumer binaries are not available to the iOS
  simulator.
- Confirm one full main and a two-half-main order both match Loadout's tray.
- Confirm three dip scoops, two dressings, one side, and one drink can be
  represented without losing quantities or sizes.
- Compare the pita, tzatziki, and hummus calorie discrepancy in the native app
  and at a restaurant.
- Verify one existing named bowl and one named pita against their official
  ingredient list and Loadout preset summary.
