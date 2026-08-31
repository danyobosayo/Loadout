#!/usr/bin/env python3
"""Add Chick-fil-A's missing breakfast items and its whole Treats menu.

Everything here — macros AND allergens — comes out of the `tableData` blob
embedded in Chick-fil-A's own nutrition & allergens page, so nothing is typed by
hand or inferred from a name.

Also fixes three names this project broke itself: when the salads were restored
to their as-served totals (with the designated dressing counted in), they kept
their old "(no dressing)" names. A Cobb Salad reading 830 cal while calling
itself "no dressing" is worse than either state on its own.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/chick-fil-a.json")
P = "chick-fil-a"

table = json.loads(open(f"{SP}/cfa_tabledata.json").read())
NUT = {m["menu"]: {i["title"]: i for i in m["items"]} for m in table["nutrition"]}
ALG = {m["menu"]: {i["title"]: i for i in m["items"]} for m in table["allergens"]}
for menu in list(NUT):
    for item in list(NUT[menu].values()):
        for sub in item.get("sub_items", []):
            NUT[menu].setdefault(sub["title"], sub)
    for item in list(ALG[menu].values()):
        for sub in item.get("sub_items", []):
            ALG[menu].setdefault(sub["title"], sub)

ALLERGEN_KEY = {"milk": "milk", "egg": "egg", "soy": "soy", "wheat": "wheat",
                "sesame": "sesame", "tree_nuts": "treenut", "peanut": "peanut",
                "fish": "fish"}


def clean(title):
    """Strip the ® / ™ noise Chick-fil-A puts in its own titles."""
    return re.sub(r"\s+", " ", title.replace("®", "").replace("™", "")).strip()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", clean(text).lower()).strip("-")


def lookup(menu, title):
    nutrition = NUT[menu][title]
    fields = {f["label"]: f["value"] for f in nutrition["fields"]}
    allergens = sorted(
        ALLERGEN_KEY[f["key"]]
        for f in ALG[menu][title]["fields"]
        if f.get("value") == "1" and f["key"] in ALLERGEN_KEY
    )
    return fields, allergens


def item(menu, title, markers, *, category_prefix, name=None, notes=None,
         size_group=None, size_label=None, is_default=False):
    fields, allergens = lookup(menu, title)
    d = {
        "id": f"{P}.{category_prefix}.{slug(name or title)}",
        "name": clean(name or title),
        "servingDescription": str(fields.get("Serving Size", "1 serving")),
        "macros": {
            "calories": float(fields["Calories"]),
            "proteinGrams": float(fields["Protein (g)"]),
            "carbGrams": float(fields["Carbohydrates (g)"]),
            "fatGrams": float(fields["Fat (g)"]),
        },
    }
    if size_group:
        d["sizeGroup"] = f"{P}.size.{size_group}"
        d["sizeLabel"] = size_label
        d["isDefaultSize"] = is_default
    d["allergens"] = allergens
    d["notes"] = notes
    d["iconName"] = None
    d["dietaryMarkers"] = markers
    return d


menu = json.loads(OUT.read_text())
cat = {c["id"]: c for c in menu["categories"]}

# ---------------------------------------------------------------- name fixes
RENAMES = {
    "Cobb Salad (no dressing)": "Cobb Salad",
    "Market Salad (no dressing)": "Market Salad",
    "Side Salad (no dressing)": "Side Salad",
}
renamed = 0
for category in menu["categories"]:
    for existing in category["items"]:
        if existing["name"] in RENAMES:
            existing["name"] = RENAMES[existing["name"]]
            renamed += 1

# ----------------------------------------------------------------- breakfast
# The muffins are the same builds as the biscuits on a different bread, so the
# markers follow the biscuits: bacon and sausage are pork, chicken is not.
breakfast = [
    item("Breakfast", "Chicken, Egg & Cheese Muffin", ["meat"], category_prefix="breakfast"),
    item("Breakfast", "Bacon, Egg & Cheese Muffin", ["meat", "pork"], category_prefix="breakfast"),
    item("Breakfast", "Sausage, Egg & Cheese Muffin", ["meat", "pork"], category_prefix="breakfast"),
    item("Breakfast", "Buttery Biscuit", [], category_prefix="breakfast"),
    item("Breakfast", "English Muffin", [], category_prefix="breakfast"),
    # Flagged honey deliberately. Chick-fil-A does not publish an ingredient list
    # here, and the Chick-n-Minis built on these rolls DO carry honey — from the
    # honey butter spread, which a plain side of rolls may or may not get. An
    # over-flag shows a warning to someone avoiding honey; an under-flag feeds it
    # to them. Only one of those is recoverable.
    item("Breakfast", "4 ct Mini Yeast Rolls", ["honey"], category_prefix="breakfast",
         notes="Marked as containing honey conservatively: Chick-fil-A publishes no "
               "ingredient list for the rolls sold on their own, and the Chick-n-Minis "
               "built on them do contain honey."),
]

# --------------------------------------------------------------------- sides
sides = [
    item("Sides", "Chicken Tortilla Soup", ["meat"], category_prefix="sides"),
    item("Sides", "Buddy Fruits® Apple Sauce", [], category_prefix="sides"),
]

# ------------------------------------------------------------------- entrées
# "Honey Pepper" is in the name, so honey is declared, not guessed. Chick-fil-A
# publishes no pork component for these, so no pork marker.
entrees = [
    item("Entrées", "Honey Pepper Pimento Sandwich w/ Chick-fil-A® Filet",
         ["honey", "meat"], category_prefix="entrees"),
    item("Entrées", "Honey Pepper Pimento Sandwich w/ Spicy Filet",
         ["honey", "meat"], category_prefix="entrees"),
    item("Entrées", "Honey Pepper Pimento Sandwich w/ Grilled Filet",
         ["honey", "meat"], category_prefix="entrees"),
]

# -------------------------------------------------------------------- treats
# Nothing on this menu contains meat, pork, honey or alcohol — they are dairy
# desserts, a cookie, a brownie and blended drinks.
SIMPLE_TREATS = [
    "Chocolate Fudge Brownie", "Frosted Sodas", "Peach Milkshake", "Frosted Coffee",
    "Cookies & Cream Milkshake", "Chocolate Milkshake", "Strawberry Milkshake",
    "Vanilla Milkshake", "Chick-fil-A® Icedream® Cone", "Chick-fil-A® Icedream® Cup",
    "Dr Pepper® Float", "Caramel Frosted Coffee", "Mocha Frosted Coffee",
    "Vanilla Frosted Coffee",
]
treats = [item("Treats", t, [], category_prefix="treats") for t in SIMPLE_TREATS]

# The frosted lemonades come in a regular and a diet-lemonade build — one drink
# at two recipes, which is what a size group models: same row, pick one.
for base in ["Frosted Lemonade", "Peach Frosted Lemonade", "Pineapple Dragonfruit Frosted Lemonade"]:
    group = slug(base)
    treats.append(item("Treats", base, [], category_prefix="treats",
                       size_group=group, size_label="Regular", is_default=True))
    diet = f"{base} w/ Diet Lemonade"
    if diet in NUT["Treats"]:
        # Peach is published with identical macros for both builds, unlike the
        # other two flavours which save 60-70 cal on diet. That is what
        # Chick-fil-A prints, so it ships as printed rather than "corrected".
        same = lookup("Treats", diet)[0]["Calories"] == lookup("Treats", base)[0]["Calories"]
        treats.append(item("Treats", diet, [], category_prefix="treats",
                           size_group=group, size_label="Diet",
                           notes=("Chick-fil-A publishes identical nutrition for the regular and "
                                  "diet-lemonade builds of this one.") if same else None))

# One cookie, and only one. Chick-fil-A lists a "6 pack Chocolate Chunk Cookie"
# but publishes it PER COOKIE — same 78 g serving, same 370 cal as a single.
# Shipping that as a "6 ct" size would read as six cookies for 370 calories, off
# by a factor of six in the direction that matters. Someone buying a six-pack
# sets the quantity to 6, which is what the stepper is for.
treats.append(item("Treats", "Chocolate Chunk Cookie", [], category_prefix="treats"))

# ------------------------------------------------------------------ assemble
existing_ids = {i["id"] for c in menu["categories"] for i in c["items"]}
added = 0
for target, items in [("breakfast", breakfast), ("sides", sides), ("entrees", entrees)]:
    for new in items:
        if new["id"] not in existing_ids:
            cat[target]["items"].append(new)
            added += 1

menu["categories"] = [c for c in menu["categories"] if c["id"] != "treats"]
pantry = [c for c in menu["categories"] if c.get("isHidden")]
menu["categories"] = [c for c in menu["categories"] if not c.get("isHidden")]
menu["categories"].append({
    "id": "treats", "name": "Treats", "selectionRule": {"kind": "selectMany"},
    "items": treats, "iconName": None, "isCompleteMeal": False,
})
menu["categories"] += pantry   # hidden stations stay last

OUT.write_text(json.dumps(menu, indent=1) + "\n")

print(f"renamed: {renamed} (the '(no dressing)' salads now match their as-served macros)")
print(f"added: {added} to existing stations + {len(treats)} treats")
print("total items:", sum(len(c["items"]) for c in menu["categories"]))
for c in menu["categories"]:
    print(f"   [{c['id']:11}] {len(c['items']):>3}{'  (hidden)' if c.get('isHidden') else ''}")
