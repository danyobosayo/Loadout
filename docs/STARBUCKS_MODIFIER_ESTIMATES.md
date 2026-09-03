# Starbucks modifier nutrition estimates

Last reviewed: 2026-09-03

## Calculation policy

Loadout keeps Starbucks' official standard-recipe calories and macros as the
baseline. An untouched drink therefore remains exact. When a customer changes a
recipe, Loadout adds or subtracts only the estimated contribution of the changed
ingredient and labels the result “Estimated nutrition.”

Preparation-only choices such as temperature, roast, decaf, ristretto, and milk
foam remain macro-neutral. Allergens and dietary suitability are not inferred
from these estimates.

## Evidence and estimates

| Modifier | Estimate used | Basis |
|---|---:|---|
| Espresso shot | 5 cal, 0.5 P, 1 C, 0 F | Starbucks US publishes Doppio espresso as 10 cal, 1 P, 2 C, 0 F. |
| Flavored syrup pump | 20 cal, 5 C | Starbucks' first-party Canada add-on table; also reconciles closely with current US vanilla drinks and default pump counts. |
| Brown sugar syrup pump | 10 cal, 3 C | Half-dose pump used by shaken espresso; scaled from the regular syrup estimate. |
| Sugar-free syrup, Splenda, or stevia | 0 | First-party add-on table for sugar-free syrup; packet sweeteners rounded to zero macros. |
| Mocha sauce pump | 25 cal, 1 P, 7 C, 0.5 F | Starbucks' first-party Canada add-on table. |
| White mocha / other sauce pump | 30 cal, 7 C, 0.5 F | Difference between current US latte and sauce-based drink totals after subtracting whip; dark caramel uses 45 cal because its official analogue is richer. |
| Whipped cream | 50–70 cal hot; 80–110 cal iced | Starbucks' first-party Canada size-specific add-on table. Light is half and extra is 1.5 portions. |
| Caramel drizzle | 15 cal, 4 C | Starbucks' first-party Canada add-on table. Mocha drizzle uses 5 cal, 1 C from the same table. |
| Vanilla sweet cream cold foam | 110 cal, 1 P, 9 C, 7 F | Current US cold-foam and sweet-cream drink analogues. |
| Flavored dairy cold foam | 195 cal, 2 P, 16 C, 14 F | Grande Salted Caramel or Chocolate Cream Cold Brew minus cold brew and two vanilla pumps. |
| Nondairy cold foam | 110 cal, 2 P, 9 C, 7 F | Current US nondairy cold-foam drinks minus cold brew and two vanilla pumps. |
| Protein cold foam | about 255 cal, 13–17 P, 13 C, 16 F | Grande Vanilla Protein Cream Cold Brew minus cold brew and two vanilla pumps; Starbucks states 13 g for strawberry and 15–18 g for protein foams. |
| Milk swap | Per-ounce milk profile × estimated drink volume | Standard milk composition plus Starbucks drink analogues. Hot milk-forward drinks use about 75% of cup volume, iced milk-forward drinks 50%, Frappuccinos 25%, shaken espresso 2–3 oz, and coffee splashes 2 oz. |
| Crunch / crumble topping | 30 cal, 5 C, 1 F | Portion analogue across standard Frappuccino recipes. Other dry toppings use 10 cal, 2 C. |

## First-party sources

- Starbucks US ordering API: https://www.starbucks.com/apiproxy/v1/ordering/menu
  and product detail records under /apiproxy/v1/ordering/{product}/{form}.
- Starbucks US Espresso nutrition:
  https://www.starbucks.com/menu/product/410/hot/nutrition
- Starbucks US Salted Caramel Cream Cold Brew:
  https://www.starbucks.com/menu/product/2122795/iced/nutrition
- Starbucks US Vanilla Protein Cream Cold Brew:
  https://www.starbucks.com/menu/product/40624/iced/nutrition
- Starbucks US protein customization guide:
  https://www.starbucks.com/discover/protein-drinks/
- Starbucks first-party Canada “Nutrition by the Cup” add-on table:
  https://about.starbucks.com/uploads/2019/01/nutrition-1.pdf

These are best estimates, not laboratory measurements of a hand-built drink.
Portioning varies by barista, ice, foam, cup geometry, and the amount of room
left in the cup. Replace any estimate when Starbucks publishes a stronger
customized value.
