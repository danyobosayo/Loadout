# Chipotle flagship ordering review

Reviewed: 2026-08-31

## First-party sources

- [Nutrition calculator](https://www.chipotle.com/nutrition-calculator)
- [Online ordering](https://www.chipotle.com/order/build/burrito-bowl)
- March 2025 US nutrition PDF linked from the calculator
- Live builder checked against restaurant 1800 at 1516 N Naper Blvd,
  Naperville, Illinois. No order, payment, sign-in, or account change was made.

## Durable menu scope

Loadout includes Chipotle's stable ingredients and four distinctive Tractor
beverages in Regular and Large sizes:

- Organic Berry Agua Fresca
- Organic Mandarin Agua Fresca
- Organic Lemonade
- Organic Watermelon Limeade

Ordinary fountain soda, bottled water, milk, Jarritos, Poppi, and other retail
drinks are intentionally omitted. A future shared soda calculator can cover
generic soda by drink and cup size without duplicating it in every restaurant.

Limited-time items are also omitted. At this review, that includes Pollo Asado,
Chili Lime Chips, Cilantro Lime Sauce, and the historical Carne Asada row that
remains in the source CSV only for provenance.

## Ordering behavior represented in Loadout

- Burrito Bowl: optional rice and beans, one protein or veggie choice, then
  toppings and optional sides.
- Burrito: the bowl path plus one flour tortilla. A format-only Double Wrap
  station adds the live builder's second 320-calorie tortilla without exposing
  it as another independent tortilla in Build Your Own.
- Three Tacos and Single Taco: one shell style, protein or veggie, up to five
  included toppings, then paid add-ons. The official calculator publishes shell
  macros for three tacos, so the bundled ingredient stores one third of that
  serving and each format applies the appropriate multiplier.
- Salad: Supergreens and Chipotle-Honey Vinaigrette are selected by default in
  the live builder and are seeded by the format.
- Quesadilla: one flour tortilla, three cheese portions, protein or fajita
  vegetables inside, and up to three included sides. Paid guacamole and queso
  are kept separate from the included side station.
- Cheese Quesadilla: the official Cheese Only path is separate because it has
  no protein requirement and includes a full guacamole portion. The format
  seeds tortilla, three cheese portions, and guacamole before the same optional
  fajita-vegetable and three-side flow.

## Preserved limitations and owner QA

- Owner QA should confirm that the Double Wrap station and extra-tortilla tray
  label read clearly and match the live builder's intent.
- Confirm each format's starting items, caps, size switching, macro totals, and
  edit/remove behavior on the shared General iOS simulator before the flagship
  pass is considered complete.
