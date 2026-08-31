#!/usr/bin/env python3
"""Migrate Chick-fil-A to as-served totals with removable components.

Two things were wrong and both were wrong *numbers*, not missing features:

1. The salads were stored DRESSING-FREE (Cobb 520, Market 320, Side Salad 160)
   while the menu board says 830, 550 and 470. Chick-fil-A hands you the salad
   with its designated dressing on it. Someone reading 520 for a Cobb was being
   undercounted by an entire 310-cal dressing.
2. The Cool Wrap's 660 already includes its built-in Avocado Lime Ranch, so
   adding a dressing from the dressings station double-counted it, and removing
   the one you actually get was impossible.

Both are fixed the same way: the published as-served figure is the item's macros,
and the dressing becomes a removable component. Every restored total is checked
by addition against the published board figure below — see VERIFY.
"""
import json
import pathlib

MENU = pathlib.Path("Loadout/Resources/Menus/chick-fil-a.json")
FORMATS = pathlib.Path("Loadout/Resources/Formats/chick-fil-a.formats.json")
P = "chick-fil-a"


def macros(kcal, protein, carb, fat):
    return {"calories": float(kcal), "proteinGrams": float(protein),
            "carbGrams": float(carb), "fatGrams": float(fat)}


def add(a, b):
    return {k: a[k] + b[k] for k in a}


def item(iid, name, serving, m, allergens=None, markers=None, notes=None):
    return {"id": iid, "name": name, "servingDescription": serving, "macros": m,
            "allergens": allergens, "notes": notes, "iconName": None,
            "dietaryMarkers": markers or []}


def comp(iid, qty=1, default=True, removable=True):
    return {"menuItemId": iid, "quantity": float(qty),
            "isDefault": default, "isRemovable": removable}


menu = json.loads(MENU.read_text())
by_id = {i["id"]: i for c in menu["categories"] for i in c["items"]}
cat = {c["id"]: c for c in menu["categories"]}

# ------------------------------------------------------------------ dressings
# Four of the seven were missing entirely, which is why "swap the dressing"
# could not be expressed at all.
NEW_DRESSINGS = [
    ("garden-herb-ranch-dressing", "Garden Herb Ranch Dressing", macros(280, 1, 2, 29), ["egg", "milk"]),
    ("creamy-salsa-dressing", "Creamy Salsa Dressing", macros(290, 1, 2, 31), ["egg", "milk"]),
    ("light-balsamic-vinaigrette", "Light Balsamic Vinaigrette", macros(80, 0, 10, 4), []),
    ("fat-free-honey-mustard-dressing", "Fat-Free Honey Mustard Dressing", macros(90, 0, 22, 0), []),
]
for slug, name, m, allergens in NEW_DRESSINGS:
    iid = f"{P}.dressings.{slug}"
    if iid not in by_id:
        it = item(iid, name, "1 packet", m, allergens=allergens,
                  markers=["honey"] if "honey" in slug else [])
        cat["dressings"]["items"].append(it)
        by_id[iid] = it

# ------------------------------------------------------------------- toppings
# Buns, cheeses and salad packets are what a sandwich is actually modified with.
TOPPINGS = [
    ("buttery-white-bun", "Buttery White Bun", "1 bun", macros(180, 5, 29, 6), ["milk", "soy", "wheat"]),
    ("white-bun-unbuttered", "White Bun (unbuttered)", "1 bun", macros(150, 5, 28, 1), ["soy", "wheat"]),
    ("multigrain-brioche-bun", "Multigrain Brioche Bun", "1 bun", macros(210, 7, 38, 4), ["milk", "soy", "wheat"]),
    ("gluten-free-bun", "Gluten Free Bun", "1 bun", macros(180, 3, 37, 4), []),
    ("american-cheese", "American Cheese", "1 slice", macros(50, 3, 1, 4), ["milk"]),
    ("colby-jack-cheese", "Colby Jack Cheese", "1 slice", macros(80, 5, 0, 7), ["milk"]),
    ("pepper-jack-cheese", "Pepper Jack Cheese", "1 slice", macros(80, 4, 0, 6), ["milk"]),
    ("applewood-smoked-bacon", "Applewood Smoked Bacon", "1 serving", macros(50, 4, 0, 4), []),
    ("green-leaf-lettuce", "Green Leaf Lettuce", "1 serving", macros(5, 0, 1, 0), []),
    ("tomato", "Tomato", "1 slice", macros(5, 0, 1, 0), []),
    ("dill-pickle-chips", "Dill Pickle Chips", "2 chips", macros(0, 0, 0, 0), []),
    ("crispy-red-bell-peppers", "Crispy Red Bell Peppers", "1 packet", macros(80, 1, 6, 6), ["wheat"]),
    ("seasoned-tortilla-strips", "Seasoned Tortilla Strips", "1 packet", macros(70, 1, 8, 4), []),
    ("chili-lime-pepitas", "Chili Lime Pepitas", "1 packet", macros(80, 4, 2, 7), []),
    ("harvest-nut-granola", "Harvest Nut Granola", "1 packet", macros(70, 1, 10, 2), ["treenut"]),
    ("blue-cheese-crumbles", "Blue Cheese Crumbles", "1 packet", macros(30, 2, 0, 2), ["milk"]),
    ("roasted-nut-blend", "Roasted Nut Blend", "1 packet", macros(70, 1, 2, 6), ["peanut", "treenut"]),
]
MEAT = {"applewood-smoked-bacon"}
topping_items = [
    item(f"{P}.toppings.{slug}", name, serving, m, allergens=allergens,
         markers=["meat", "pork"] if slug in MEAT else [])
    for slug, name, serving, m, allergens in TOPPINGS
]
if "toppings" not in cat:
    menu["categories"].append({
        "id": "toppings", "name": "Toppings & Buns",
        "selectionRule": {"kind": "selectMany"}, "items": topping_items,
        "iconName": None, "isCompleteMeal": False,
    })
    cat["toppings"] = menu["categories"][-1]
for it in topping_items:
    by_id[it["id"]] = it

# -------------------------------------------------------------------- pantry
# Derived bases. Neither is orderable — you cannot ask for "a Cool Wrap without
# the wrap" — but both must resolve so a component can subtract against them.
PANTRY = [
    (f"{P}.pantry.cool-wrap-no-dressing", "Cool Wrap (before dressing)", macros(350, 42, 29, 13),
     "Derived: the published 660 Cool Wrap minus its built-in Avocado Lime Ranch. "
     "Closes exactly on all four macros."),
    (f"{P}.pantry.grilled-bun-filet", "Grilled sandwich bun + filet", macros(380, 28, 43, 11),
     "Derived block. The a-la-carte multigrain bun plus grilled filet leaves a 60-cal "
     "residual against the board figure, identically across all three grilled sandwiches, "
     "so bun and filet ship fused and neither can be removed."),
    (f"{P}.pantry.cobb-no-dressing", "Cobb Salad (before dressing)", macros(520, 40, 28, 28), None),
    (f"{P}.pantry.market-no-dressing", "Market Salad (before dressing)", macros(320, 28, 26, 12), None),
    (f"{P}.pantry.side-salad-no-dressing", "Side Salad (before dressing)", macros(160, 5, 11, 10), None),
    (f"{P}.pantry.southwest-no-toppings", "Spicy Southwest Salad (before toppings)", macros(240, 27, 15, 7),
     "Derived: the published 680 minus tortilla strips, pepitas and Creamy Salsa dressing."),
]
pantry_items = [item(i, n, "component", m, allergens=[], notes=note) for i, n, m, note in PANTRY]
# A derived base inherits its parent's published allergens and markers, filled in
# after the parents are final. Removing a dressing can only ever drop an allergen,
# never add one, so inheriting is the conservative direction — it may over-flag,
# which fails safe. Leaving them null would read as "not checked" and trip
# DietaryTests.everyItemIsFlagged, which walks hidden stations too.
PANTRY_PARENT = {
    f"{P}.pantry.cool-wrap-no-dressing": f"{P}.entrees.chick-fil-a-cool-wrap",
    f"{P}.pantry.grilled-bun-filet": f"{P}.entrees.grilled-chicken-sandwich",
    f"{P}.pantry.cobb-no-dressing": f"{P}.mains.cobb-salad-base",
    f"{P}.pantry.market-no-dressing": f"{P}.mains.market-salad-base",
    f"{P}.pantry.side-salad-no-dressing": f"{P}.sides.side-salad",
    f"{P}.pantry.southwest-no-toppings": f"{P}.mains.spicy-southwest-salad",
}
if "pantry" not in cat:
    menu["categories"].append({
        "id": "pantry", "name": "Components", "selectionRule": {"kind": "selectMany"},
        "items": pantry_items, "iconName": None, "isCompleteMeal": False, "isHidden": True,
    })
for it in pantry_items:
    by_id[it["id"]] = it

# ------------------------------------------------------------------ verify
checks = []


def restore(item_id, base_id, extras, published_calories, label):
    """Set an item to its as-served total, built from sourced parts.

    `published_calories` is the menu-board figure. If our addition doesn't land
    on it, the composition is wrong and the script says so rather than shipping
    a number nobody can source.
    """
    total = by_id[base_id]["macros"]
    for eid, qty in extras:
        for _ in range(qty):
            total = add(total, by_id[eid]["macros"])
    checks.append((label, published_calories, total["calories"]))
    by_id[item_id]["macros"] = total
    return total


DRESS = f"{P}.dressings"
TOP = f"{P}.toppings"

restore(f"{P}.mains.cobb-salad-base", f"{P}.pantry.cobb-no-dressing",
        [(f"{DRESS}.avocado-lime-ranch-dressing", 1)], 830, "Cobb Salad")
by_id[f"{P}.mains.cobb-salad-base"]["components"] = [
    comp(f"{P}.pantry.cobb-no-dressing", removable=False),
    comp(f"{DRESS}.avocado-lime-ranch-dressing"),
] + [comp(f"{DRESS}.{s}", default=False) for s, *_ in NEW_DRESSINGS] + [
    comp(f"{DRESS}.zesty-apple-cider-vinaigrette", default=False),
    comp(f"{DRESS}.light-italian-dressing", default=False),
    comp(f"{TOP}.blue-cheese-crumbles", default=False),
]

restore(f"{P}.mains.market-salad-base", f"{P}.pantry.market-no-dressing",
        [(f"{DRESS}.zesty-apple-cider-vinaigrette", 1)], 550, "Market Salad")
by_id[f"{P}.mains.market-salad-base"]["components"] = [
    comp(f"{P}.pantry.market-no-dressing", removable=False),
    comp(f"{DRESS}.zesty-apple-cider-vinaigrette"),
] + [comp(f"{DRESS}.{s}", default=False) for s, *_ in NEW_DRESSINGS] + [
    comp(f"{DRESS}.avocado-lime-ranch-dressing", default=False),
    comp(f"{DRESS}.light-italian-dressing", default=False),
]

restore(f"{P}.sides.side-salad", f"{P}.pantry.side-salad-no-dressing",
        [(f"{DRESS}.avocado-lime-ranch-dressing", 1)], 470, "Side Salad")
by_id[f"{P}.sides.side-salad"]["components"] = [
    comp(f"{P}.pantry.side-salad-no-dressing", removable=False),
    comp(f"{DRESS}.avocado-lime-ranch-dressing"),
] + [comp(f"{DRESS}.{s}", default=False) for s, *_ in NEW_DRESSINGS] + [
    comp(f"{DRESS}.zesty-apple-cider-vinaigrette", default=False),
    comp(f"{DRESS}.light-italian-dressing", default=False),
]

# Cool Wrap: the 660 stays put; the built-in dressing simply becomes removable.
checks.append(("Cool Wrap", 660, add(by_id[f"{P}.pantry.cool-wrap-no-dressing"]["macros"],
                                     by_id[f"{DRESS}.avocado-lime-ranch-dressing"]["macros"])["calories"]))
by_id[f"{P}.entrees.chick-fil-a-cool-wrap"]["components"] = [
    comp(f"{P}.pantry.cool-wrap-no-dressing", removable=False),
    comp(f"{DRESS}.avocado-lime-ranch-dressing"),
] + [comp(f"{DRESS}.{s}", default=False) for s, *_ in NEW_DRESSINGS] + [
    comp(f"{DRESS}.zesty-apple-cider-vinaigrette", default=False),
    comp(f"{DRESS}.light-italian-dressing", default=False),
]

# Spicy Southwest Salad — a current menu item we did not carry at all.
southwest = item(f"{P}.mains.spicy-southwest-salad", "Spicy Southwest Salad", "1 salad",
                 macros(0, 0, 0, 0), allergens=["milk", "wheat"], markers=["meat"])
cat["mains"]["items"].append(southwest)
by_id[southwest["id"]] = southwest
restore(southwest["id"], f"{P}.pantry.southwest-no-toppings",
        [(f"{TOP}.seasoned-tortilla-strips", 1), (f"{TOP}.chili-lime-pepitas", 1),
         (f"{DRESS}.creamy-salsa-dressing", 1)], 680, "Spicy Southwest Salad")
southwest["components"] = [
    comp(f"{P}.pantry.southwest-no-toppings", removable=False),
    comp(f"{TOP}.seasoned-tortilla-strips"),
    comp(f"{TOP}.chili-lime-pepitas"),
    comp(f"{DRESS}.creamy-salsa-dressing"),
    comp(f"{TOP}.blue-cheese-crumbles", default=False),
    comp(f"{DRESS}.avocado-lime-ranch-dressing", default=False),
    comp(f"{DRESS}.garden-herb-ranch-dressing", default=False),
]

# ----------------------------------------------------------------- sandwiches
BUN_SWAPS = [f"{TOP}.white-bun-unbuttered", f"{TOP}.multigrain-brioche-bun", f"{TOP}.gluten-free-bun"]
CHEESES = [f"{TOP}.american-cheese", f"{TOP}.colby-jack-cheese", f"{TOP}.pepper-jack-cheese"]
FIXINGS = [f"{TOP}.applewood-smoked-bacon", f"{TOP}.green-leaf-lettuce", f"{TOP}.tomato"]

# (item, default components, extras) — fried sandwiches are bun + filet + pickles.
SANDWICHES = {
    "chick-fil-a-chicken-sandwich": ([f"{TOP}.buttery-white-bun", f"{TOP}.dill-pickle-chips"], None),
    "spicy-chicken-sandwich": ([f"{TOP}.buttery-white-bun", f"{TOP}.dill-pickle-chips"], None),
    "chick-fil-a-deluxe-sandwich": (
        [f"{TOP}.buttery-white-bun", f"{TOP}.dill-pickle-chips", f"{TOP}.green-leaf-lettuce",
         f"{TOP}.tomato", f"{TOP}.american-cheese"], None),
    "spicy-deluxe-sandwich": (
        [f"{TOP}.buttery-white-bun", f"{TOP}.dill-pickle-chips", f"{TOP}.green-leaf-lettuce",
         f"{TOP}.tomato", f"{TOP}.pepper-jack-cheese"], None),
    "grilled-chicken-sandwich": ([f"{TOP}.green-leaf-lettuce", f"{TOP}.tomato"], f"{P}.pantry.grilled-bun-filet"),
    "grilled-chicken-club-sandwich": (
        [f"{TOP}.green-leaf-lettuce", f"{TOP}.tomato", f"{TOP}.colby-jack-cheese",
         f"{TOP}.applewood-smoked-bacon"], f"{P}.pantry.grilled-bun-filet"),
}
for slug, (defaults, fused) in SANDWICHES.items():
    target = by_id[f"{P}.entrees.{slug}"]
    components = []
    if fused:
        # The grilled bun+filet block can't be split (see the 60-cal residual in
        # COMPONENT_DATA.md), so it is present, unremovable and therefore hidden.
        components.append(comp(fused, removable=False))
    components += [comp(d) for d in defaults]
    extras = [e for e in BUN_SWAPS + CHEESES + FIXINGS if e not in defaults]
    if fused:
        extras = [e for e in extras if e not in BUN_SWAPS]  # no bun swaps on grilled
    components += [comp(e, default=False) for e in extras]
    target["components"] = components

# ------------------------------------------------------------------- assemble
for child, parent in PANTRY_PARENT.items():
    by_id[child]["allergens"] = list(by_id[parent].get("allergens") or [])
    by_id[child]["dietaryMarkers"] = list(by_id[parent].get("dietaryMarkers") or [])

menu["orderingModel"] = "configuration"

print("VERIFY — restored totals vs the published board figure")
ok = True
for label, published, built in checks:
    flag = "OK " if abs(published - built) < 0.5 else "!! "
    if flag != "OK ":
        ok = False
    print(f"  {flag}{label:24} board {published:>5.0f} · built {built:>6.0f}")

if not ok:
    raise SystemExit("composition does not match the board figure — not writing")

MENU.write_text(json.dumps(menu, indent=1) + "\n")
if FORMATS.exists():
    FORMATS.unlink()
    print("\nremoved chick-fil-a.formats.json — the menu is the entry point now")
print("wrote", MENU, "·", sum(len(c["items"]) for c in menu["categories"]), "items")
