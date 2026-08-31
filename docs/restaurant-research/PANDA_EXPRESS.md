# Panda Express flagship ordering review

Reviewed: 2026-08-31

## First-party sources

- [Nutrition and allergen table](https://www.pandaexpress.com/nutritioninformation)
- [Official online ordering](https://www.pandaexpress.com/)
- Live builder checked at Golden Link Blvd. & E Aurora Rd in Macedonia, Ohio.
  No order, payment, sign-in, or account change was made.

## Current combo behavior

- Bowl: one side and one entrée.
- Plate: one side and two entrée portions.
- Bigger Plate: one side and three entrée portions.
- The side can be one full serving or two half servings. The live builder changed
  White Steamed Rice plus Chow Mein from 520 calories to 560, confirming the
  expected half-and-half calculation: `520 / 2 + 600 / 2`.
- Premium entrées are identified in the ordering UI, but price does not affect
  macros and is not stored by Loadout.
- Loadout's À La Carte entry point tracks the standard serving published in the
  nutrition table. The online ordering category also sells container sizes, but
  the current first-party nutrition table does not publish a trustworthy
  size-to-serving multiplier for every item. Loadout does not guess those
  multipliers.

## Drinks

Restaurant menus omit ordinary fountain sodas and generic retail drinks. The
Panda menu keeps the current 24 oz Panda Crafted Beverages for which the official
nutrition table publishes complete macros:

- Peach Lychee Flavored Refresher — 210 calories, 53 g carbohydrate
- Pomegranate Pineapple Flavored Lemonade — 240 calories, 62 g carbohydrate
- Watermelon Mango Flavored Refresher — 210 calories, 53 g carbohydrate

The current order page also shows Strawberry Dragonfruit Refresher, but the
nutrition table has no corresponding row. It is omitted rather than assigned an
estimated value. Mango Guava Tea remains in the nutrition table but was absent
from the reviewed live menu, so it is also omitted.

## Source disagreements and availability

- The live builder displays SweetFire Chicken Breast as 380 calories while the
  nutrition table publishes 360 calories and the complete macro breakdown.
  Loadout retains the table's complete 360-calorie row pending clarification.
- The live builder displays Super Greens in an entrée slot at 130 calories, the
  same as the 10 oz side. The table separately lists a 7 oz, 90-calorie entrée
  row. Loadout follows the amount shown in the current combo builder and copies
  the complete 10 oz side macros rather than inferring the other macros.
- Hot Orange Chicken is shown as New and differs between the builder (580) and
  nutrition table (550). It is excluded as a promotional item under the durable
  no-limited-time-items rule.
- The nutrition table contains more regional or intermittently available items
  than the reviewed Ohio location. Loadout retains stable published items and
  documents that local availability varies.

## Balanced Protein Plates

The current ordering page publishes two named, fixed-composition plates that
are especially relevant to Loadout's fitness focus:

- Double Protein Plate — two Grilled Teriyaki Chicken portions with half White
  Steamed Rice and half Super Greens; 875 calories and 76 g protein.
- Harmonious Macros Plate — Grilled Teriyaki Chicken and Broccoli Beef with
  Super Greens; 555 calories and 57 g protein.

The builder displays Teriyaki Sauce as a separate, removable sauce choice and
does not include it in either published calorie total. The presets therefore
omit the sauce; a person who uses it can add the sourced sauce serving in the
tray.

## Owner QA

- Build a Bowl, Plate, and Bigger Plate on a physical iPhone. Confirm one full
  side or two half sides, then exactly one, two, or three entrée portions.
- Compare totals for White Rice + Chow Mein half-and-half and repeated entrée
  portions with the native Panda app.
- Open both Balanced Protein Plate cards. Confirm the named components and
  published totals, then add Teriyaki Sauce once and confirm the tray increases
  by its separate 70-calorie serving.
- Open À La Carte and confirm the “published standard serving” language is clear
  enough that it cannot be mistaken for Panda's Small/Medium/Large containers.
- Confirm only the three sourced Panda Crafted Beverages appear and that no
  fountain soda is present.
- Edit the tray, save and reopen a recipe, then log/export the final meal once.
