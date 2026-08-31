#!/usr/bin/env python3
"""Rebuild Raising Cane's as a top-down, configure-from-a-combo menu.

Cane's is not a build-your-own line. Nobody walks in and assembles a tray from
fingers, fries and slaw — they order a Box Combo and then say "extra sauce, no
slaw". So this menu leads with the five combos as configured items, keeps the
a la carte pieces beneath for the people who do order that way, and adds the
full published drinks list, which the old food-only menu left out entirely.

Every macro here is verbatim from the July 2025 first-party PDF except two
derived fries portions and one flagged estimate; see VERIFY below.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/raising-canes.json")
P = "raising-canes"


def macros(kcal, protein, carb, fat):
    return {"calories": float(kcal), "proteinGrams": float(protein),
            "carbGrams": float(carb), "fatGrams": float(fat)}


def item(iid, name, serving, m, allergens=None, markers=None, components=None,
         size_group=None, size_label=None, is_default_size=False,
         estimated=False, notes=None):
    d = {"id": iid, "name": name, "servingDescription": serving, "macros": m}
    if size_group:
        d["sizeGroup"] = size_group
        d["sizeLabel"] = size_label
        d["isDefaultSize"] = is_default_size
    if components:
        d["components"] = components
    if estimated:
        d["isEstimated"] = True
    d["allergens"] = allergens
    d["notes"] = notes
    d["iconName"] = None
    d["dietaryMarkers"] = markers or []
    return d


def comp(iid, qty=1, default=True, removable=True):
    return {"menuItemId": iid, "quantity": float(qty),
            "isDefault": default, "isRemovable": removable}


# ---------------------------------------------------------------- components
# Published a la carte rows, reused verbatim as combo components.
FINGER = macros(130, 13, 5, 7)
FRIES_FULL = macros(400, 5, 50, 20)
TOAST = macros(150, 4, 23, 4)
SLAW = macros(100, 1, 10, 6)
SAUCE = macros(190, 0, 6, 18)
SANDWICH = macros(830, 47, 69, 41)

# DERIVED, not published. Cane's prints one "Crinkle-Cut Fries" row (400 cal)
# but the combos plainly carry a smaller fry. Sandwich Combo minus Chicken
# Sandwich reconciles on ALL FOUR macros exactly (1140-830=310, 51-47=4,
# 108-69=39, 56-41=15), and that same 310/4/39/15 then closes the carb column
# EXACTLY on the 3 Finger (83) and Box (98) combos too. Three independent
# subtractions agreeing to the gram is a derivation, not an estimate.
FRIES_COMBO = macros(310, 4, 39, 15)
# Kids Combo minus 2 fingers minus a sauce, exact on all four: 650-260-190=200,
# 29-26-0=3, 39-10-6=23, 41-14-18=9.
FRIES_KIDS = macros(200, 3, 23, 9)

CHICKEN_ALLERGENS = ["egg", "milk", "wheat"]

pantry = [
    item(f"{P}.pantry.fries-combo", "Crinkle-Cut Fries (combo portion)",
         "combo portion", FRIES_COMBO, allergens=[], markers=[],
         notes="Derived by subtraction from three published combo totals; Cane's does not publish this portion separately."),
    item(f"{P}.pantry.fries-kids", "Crinkle-Cut Fries (kid's portion)",
         "kid's portion", FRIES_KIDS, allergens=[], markers=[],
         notes="Derived by subtraction from the published Kid's Combo total."),
]

# ------------------------------------------------------------------- combos
# Extras every combo accepts, matching what the counter will actually add.
EXTRAS = [
    comp(f"{P}.entrees.chicken-finger", default=False),
    comp(f"{P}.dips.canes-sauce", default=False),
    comp(f"{P}.dips.honey-mustard", default=False),
    comp(f"{P}.dips.ketchup", default=False),
    comp(f"{P}.sides.texas-toast", default=False),
    comp(f"{P}.sides.coleslaw", default=False),
    comp(f"{P}.sides.crinkle-cut-fries", default=False),
    comp(f"{P}.sauces.louisiana-hot-sauce", default=False),
    comp(f"{P}.sauces.kraft-mayonnaise", default=False),
]

combos = [
    item(f"{P}.combos.box-combo", "Box Combo", "1 combo — 4 fingers",
         macros(1290, 62, 98, 72), allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             # The fingers are what the combo IS; taking them off leaves a side
             # order, not a Box Combo. Unremovable, therefore hidden.
             comp(f"{P}.entrees.chicken-finger", qty=4, removable=False),
             comp(f"{P}.pantry.fries-combo"),
             comp(f"{P}.sides.texas-toast"),
             comp(f"{P}.sides.coleslaw"),
             comp(f"{P}.dips.canes-sauce"),
         ] + EXTRAS),
    item(f"{P}.combos.3-finger-combo", "3 Finger Combo", "1 combo — 3 fingers",
         macros(1050, 48, 83, 59), allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             comp(f"{P}.entrees.chicken-finger", qty=3, removable=False),
             comp(f"{P}.pantry.fries-combo"),
             comp(f"{P}.sides.texas-toast"),
             comp(f"{P}.dips.canes-sauce"),
         ] + EXTRAS),
    item(f"{P}.combos.caniac-combo", "Caniac Combo", "1 combo — 6 fingers",
         macros(1840, 90, 125, 108), allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             comp(f"{P}.entrees.chicken-finger", qty=6, removable=False),
             comp(f"{P}.sides.crinkle-cut-fries"),
             comp(f"{P}.sides.texas-toast"),
             comp(f"{P}.sides.coleslaw"),
             comp(f"{P}.dips.canes-sauce", qty=2),
         ] + EXTRAS),
    item(f"{P}.combos.sandwich-combo", "Sandwich Combo", "1 combo",
         macros(1140, 51, 108, 56), allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             comp(f"{P}.entrees.chicken-sandwich", removable=False),
             comp(f"{P}.pantry.fries-combo"),
         ] + EXTRAS),
    item(f"{P}.combos.kids-combo", "Kid's Combo", "1 combo — 2 fingers",
         macros(650, 29, 39, 41), allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             comp(f"{P}.entrees.chicken-finger", qty=2, removable=False),
             comp(f"{P}.pantry.fries-kids"),
             comp(f"{P}.dips.canes-sauce"),
         ] + EXTRAS),
]

# ------------------------------------------------------------------ entrees
entrees = [
    item(f"{P}.entrees.chicken-finger", "Chicken Finger", "1 finger — 1.9 oz (55 g)",
         FINGER, allergens=CHICKEN_ALLERGENS, markers=["meat"]),
    item(f"{P}.entrees.naked-bird", "Chicken Finger (Naked)", "1 finger, no breading",
         macros(70, 13, 0, 2), allergens=[], markers=["meat"], estimated=True,
         notes="Off-menu request for unbreaded fingers. Cane's publishes no figure for these; "
               "this is a widely-circulated community estimate, not official data. It is "
               "internally consistent — protein matches the breaded finger exactly and Atwater "
               "closes to the calorie — but treat it as approximate."),
    item(f"{P}.entrees.chicken-sandwich", "Chicken Sandwich", "10.4 oz (296 g)",
         SANDWICH, allergens=CHICKEN_ALLERGENS, markers=["meat"],
         components=[
             # Cane's publishes the sandwich whole. The bun, lettuce and the
             # in-sandwich sauce squeeze have no published rows, so nothing
             # inside it can be costed — it is atomic. Extras only.
             comp(f"{P}.entrees.chicken-finger", qty=3, removable=False),
         ] + [c for c in EXTRAS if "fries" not in c["menuItemId"]]),
]

sides = [
    item(f"{P}.sides.crinkle-cut-fries", "Crinkle-Cut Fries", "5.1 oz (144 g)",
         FRIES_FULL, allergens=[], markers=[]),
    item(f"{P}.sides.texas-toast", "Texas Toast", "1 slice — 1.7 oz (48 g)",
         TOAST, allergens=["milk", "soy", "wheat"], markers=[]),
    item(f"{P}.sides.coleslaw", "Coleslaw", "1 serving — 3 oz (85 g)",
         SLAW, allergens=["egg"], markers=[]),
]

dips = [
    item(f"{P}.dips.canes-sauce", "Cane's Sauce", "1 serving — 1.5 oz (43 g)",
         SAUCE, allergens=["egg", "soy"], markers=[]),
    item(f"{P}.dips.honey-mustard", "Honey Mustard", "1 serving — 1.5 oz (43 g)",
         macros(140, 0.5, 16, 8), allergens=["egg", "soy"], markers=["honey"]),
    item(f"{P}.dips.ketchup", "Ketchup", "1 packet", macros(35, 0, 8, 0),
         allergens=[], markers=[]),
]

sauces = [
    item(f"{P}.sauces.louisiana-hot-sauce", "Louisiana Hot Sauce", "1 packet",
         macros(0, 0, 0, 0), allergens=[], markers=[]),
    item(f"{P}.sauces.kraft-mayonnaise", "Kraft Mayonnaise", "1 packet",
         macros(90, 0, 0, 10), allergens=["egg"], markers=[]),
]

# ------------------------------------------------------------------- drinks
SIZE_RE = re.compile(r"^(.*?)\s*-\s*(Kid[’']s|Regular|Large|Jug)$")


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


rows = json.load(open(f"{SP}/canes_drinks.json"))
drinks, groups = [], {}
for r in rows:
    m = SIZE_RE.match(r["name"].replace("Unsweet- ", "Unsweet - "))
    base = m.group(1).strip() if m else r["name"]
    label = m.group(2).replace("’", "'") if m else None
    key = slug(base)
    groups.setdefault(key, []).append((base, label, r))

for key, members in groups.items():
    for base, label, r in members:
        sized = label is not None and len(members) > 1
        name = base if sized else r["name"]
        # Regular is the cup you get if you say nothing; when a drink has no
        # Regular row (the juice pouch, the milk box) it stands alone anyway.
        drinks.append(item(
            f"{P}.drinks.{key}" + (f".{slug(label)}" if sized else ""),
            name if not sized else f"{base} ({label})",
            r["serving"],
            macros(r["cal"], r["protein"], r["carb"], r["fat"]),
            allergens=["milk"] if "Milk" in base else [],
            markers=[],
            size_group=f"{P}.drinks.{key}" if sized else None,
            size_label=label if sized else None,
            is_default_size=(label == "Regular"),
        ))

# ------------------------------------------------------------------- verify
def total(m, k):
    return m[k]


def check(built, published, label):
    """Re-sum a combo from its components and report the residual.

    The published figure is authoritative and ships as-is; this only proves the
    component split is sane, so that REMOVING a part subtracts a real number.
    """
    deltas = {k: round(published[k] - built[k], 1) for k in published}
    print(f"  {label:16} published {published['calories']:>6.0f} · "
          f"sum {built['calories']:>6.0f} · residual "
          + " ".join(f"{k[0].upper()}{v:+g}" for k, v in deltas.items()))
    return deltas


by_id = {i["id"]: i for i in pantry + entrees + sides + dips + sauces + combos}
print("VERIFY — combos re-summed from components")
for c in combos:
    acc = macros(0, 0, 0, 0)
    for part in c["components"]:
        if not part["isDefault"]:
            continue
        src = by_id[part["menuItemId"]]["macros"]
        for k in acc:
            acc[k] += src[k] * part["quantity"]
    check(acc, c["macros"], c["name"])

# ------------------------------------------------------------------- assemble
old = json.load(open(OUT))
menu = {
    "id": P,
    "name": "Raising Cane's",
    "orderingModel": "configuration",
    "schemaVersion": old["schemaVersion"],
    "dataSource": old["dataSource"],
    "categories": [
        {"id": "combos", "name": "Combos", "selectionRule": {"kind": "selectMany"},
         "items": combos, "iconName": None, "isCompleteMeal": True},
        {"id": "entrees", "name": "Chicken", "selectionRule": {"kind": "selectMany"},
         "items": entrees, "iconName": None, "isCompleteMeal": False},
        {"id": "sides", "name": "Sides", "selectionRule": {"kind": "selectMany"},
         "items": sides, "iconName": None, "isCompleteMeal": False},
        {"id": "dips", "name": "Dipping Sauces", "selectionRule": {"kind": "selectUpTo", "max": 3},
         "items": dips, "iconName": None, "isCompleteMeal": False},
        {"id": "sauces", "name": "Condiment Packets", "selectionRule": {"kind": "selectMany"},
         "items": sauces, "iconName": None, "isCompleteMeal": False},
        {"id": "drinks", "name": "Drinks", "selectionRule": {"kind": "selectMany"},
         "items": drinks, "iconName": None, "isCompleteMeal": False},
        {"id": "pantry", "name": "Combo portions", "selectionRule": {"kind": "selectMany"},
         "items": pantry, "iconName": None, "isCompleteMeal": False, "isHidden": True},
    ],
}
menu["dataSource"]["notes"] = (
    menu["dataSource"]["notes"].split("PRESET TOTALS DO NOT EQUAL")[0]
    + "COMBOS RECONCILE ONCE THE COMBO FRY IS SPLIT OUT. An earlier pass summed combos "
      "using the a la carte 400-cal fries and overshot by 2-8%. Cane's serves a smaller "
      "fry in the 3 Finger, Box and Sandwich combos and a smaller one still in the Kid's, "
      "but publishes neither. Sandwich Combo minus Chicken Sandwich gives 310/4/39/15 on "
      "all four macros exactly, and that figure then closes the carb column EXACTLY on the "
      "3 Finger (83 g) and Box (98 g) combos. Kid's Combo minus 2 fingers minus a sauce "
      "gives 200/3/23/9, exact on all four. Both live in a hidden `pantry` station so they "
      "resolve as components but cannot be ordered. Remaining residuals are small and "
      "one-directional (3 Finger -10 cal, Box -20, Caniac -30, Sandwich and Kid's exact); "
      "the published total ships as-is and components only ever subtract from it.\n\n"
      "COMBO TOTALS ARE DRINK-FREE, and each equals the low end of the menu page's calorie "
      "range, i.e. a zero-calorie drink. Drinks are therefore a separate station you add to "
      "a combo rather than something baked into the combo figure.\n\n"
      "DRINKS are the full published list, 87 rows across 4 cup sizes (Kid's 12 fl oz, "
      "Regular 22, Large 32, Jug 1 gallon), collapsed into size groups. Cane's own cup "
      "names are kept rather than normalised to S/M/L — replicating your real order matters "
      "more than cross-chain tidiness, and the fluid ounces make sizes comparable anyway.\n\n"
      "ONE ESTIMATED ITEM. Chicken Finger (Naked) carries isEstimated=true. Cane's publishes "
      "nothing for unbreaded fingers and the delta cannot be derived from any published pair, "
      "so this is a community figure (70 cal / 13 P / 0 C / 2 F), shown flagged rather than "
      "presented as sourced. It is the only non-published, non-derived macro in this file."
)

OUT.write_text(json.dumps(menu, indent=1) + "\n")
counts = {c["id"]: len(c["items"]) for c in menu["categories"]}
print("\nwrote", OUT, counts, "· total", sum(counts.values()), "items")
