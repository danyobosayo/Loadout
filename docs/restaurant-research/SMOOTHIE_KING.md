# Smoothie King flagship ordering review

Reviewed: 2026-08-31

## First-party sources

- [National smoothie menu](https://www.smoothieking.com/menu/smoothies/)
- [Nutrition calculator and methodology](https://www.smoothieking.com/nutrition/)
- Individual first-party product pages, which embed the complete Nutrition Facts
  rows used by `Tools/menu-import/build_smoothie_king.py`.
- [Official online ordering](https://order.smoothieking.com/), reviewed at
  store 1128, 3903 Lemmon Ave., Dallas, Texas. No order, payment, sign-in, or
  account change was made.

## Current ordering behavior

- A location menu is organized into Be Well, Feel Energized, Get Fit, Manage
  Weight, Fruit Classics, GLP-1 Support, Kids, seasonal collections, Smoothie
  Bowls, Power Eats, bundles, and packaged snacks.
- A standard adult smoothie normally requires one of three sizes: 20, 32, or
  44 ounces. High Protein Greek Yogurt Gut Health Pineapple Mango is the one
  current exception, with a published 40-ounce top size. The reviewed Dallas
  order page preselected 32 ounces. Smoothie King's
  nutrition FAQ identifies 20 ounces as the standard recipe basis, so Loadout
  defaults to 20 and always exposes the other two cups.
- Kids smoothies publish one 12-ounce standard recipe.
- After size, the order page offers recipe removals, then up to eight enhancers,
  up to eight fruits and vegetables, up to eight protein add-ons, up to two
  energy add-ons, and up to eight extras. Availability varies by product and
  location.
- The national menu's purpose categories and a location's ordering categories
  are not identical. Loadout uses the stable national purpose categories and
  sources all macro rows from the corresponding national product pages.

## Nutrition and customization boundary

The current product pages publish complete calories, protein, carbohydrate, and
fat for each offered size. The importer transcribes those rows directly; it
does not scale a 20-ounce smoothie into the larger cups.

The same pages expose a live recipe calculator, but nominal ingredient records
are not trustworthy removal deltas. For example, the source record for one
Turbinado ingredient portion is about 51 calories, while removing Turbinado
from the 20-ounce Banana Boat changes the calculator from 440 to 360 calories.
That recipe uses a different effective quantity. Loadout therefore does not
offer ingredient removals or substitutions yet.

Enhancers are different: Smoothie King publishes them as separate add-on
servings with complete macro contributions that do not vary by cup size in the
source. Loadout exposes the 16 current complete rows and omits enhancer records
whose first-party macro data is incomplete.

## Scope and exclusions

- The stable menu includes 113 smoothie concepts represented by 323 exact
  size-level rows, plus 16 enhancer servings. Size groups collapse those rows
  to one searchable row per conceptual smoothie.
- Eight pumpkin products are excluded as a current fall campaign. The reviewed
  Dallas menu also described its watermelon collection as limited-time; those
  products are excluded even when a location still displays them.
- Smoothie bowls, Power Eats, bundles, and generic packaged snacks are not part
  of this first flagship smoothie pass. They are distinct ordering/data models,
  not unsupported rows hidden inside the smoothie categories.
- Collagen Power Pineapple Kale and the collagen enhancer carry an animal-derived
  marker. Other allergen rows come directly from the product or enhancer source.

## Verification facts

- Original High Protein Banana: 20 oz 330/27P/33C/12F; 32 oz
  490/41P/49C/19F; 44 oz 660/54P/65C/25F.
- Banana Boat: 20 oz 440/10P/91C/5F; 32 oz 650/15P/138C/8F; 44 oz
  870/20P/182C/11F.
- Repeated live generation produced menu SHA-256
  `fb45e9447e6c6124b6e9be583ae006ce309c378e4627738c1c575c362d0405e4`
  and formats SHA-256
  `f56f636c110ee6f11577fb4ba1cb214fec37cfaf9b8d77b9425bcb7ca4df20ea`.

## Owner QA

- Compare Get Fit, Manage Weight, Be Well, Fruit Classics, GLP-1, and Kids
  ordering against the native app on a physical iPhone.
- Choose 20, 32, and 44 ounces for Original High Protein Banana and confirm the
  three macro sets above. Confirm Kids products remain 12 ounces.
- Add Gladiator Protein, Whey Protein, and one wellness enhancer separately;
  compare each tray delta with the native nutrition display.
- Confirm pumpkin, watermelon, and other limited-time blends are absent.
- Confirm Loadout does not offer a removal/substitution control that implies an
  unsupported macro delta.
- Search for Gladiator, vegan, Greek yogurt, and Banana Boat; confirm one row per
  smoothie rather than three duplicate cup rows.
- Edit the tray, save and reopen a recipe, then log/export the final smoothie
  and enhancer exactly once.
