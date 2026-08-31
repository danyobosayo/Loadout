#!/usr/bin/env python3
"""Add Chick-fil-A's drinks and coffee, from its own nutrition & allergens page.

Chick-fil-A was the last big menu with no drinks station at all, which is a
material gap and not a cosmetic one: a large Chick-fil-A Lemonade is 380 cal —
more than a Chicken Sandwich minus its bun.

Sizes come through as Small / Medium / Large with the gram weight in the serving
line. The parent row is always the Medium, so it's dropped in favour of its own
sub-items rather than shipped as a fourth, unlabelled copy.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/chick-fil-a.json")
P = "chick-fil-a"

table = json.loads(open(f"{SP}/cfa_tabledata.json").read())
NUT = {m["menu"]: m["items"] for m in table["nutrition"]}
ALG = {m["menu"]: {i["title"]: i for i in m["items"]} for m in table["allergens"]}
for menu, items in ALG.items():
    for item in list(items.values()):
        for sub in item.get("sub_items", []):
            items.setdefault(sub["title"], sub)

ALLERGEN_KEY = {"milk": "milk", "egg": "egg", "soy": "soy", "wheat": "wheat",
                "sesame": "sesame", "tree_nuts": "treenut", "peanut": "peanut",
                "fish": "fish"}
SIZE_RE = re.compile(r"^(Small|Medium|Large)\s+(.*)$")

# Catering gallons. A gallon is not a drink someone logs against a meal, and 27
# of them would more than double this station — the same call already made for
# Panda's cub meals.
#
# "Iced Coffee" is skipped on the Drinks menu because Chick-fil-A publishes it
# twice with different figures: 661 g / 200 cal here, and 624 g / 110 cal as a
# sub of the Coffee menu's Iced Coffee. The Drinks figure is byte-identical to
# the Mocha Iced Coffee row, so which drink it actually describes is ambiguous.
# The Coffee menu's four rows (plain 110, Vanilla 210, Mocha 200, Caramel 260)
# are internally consistent, so those are the ones that ship.
SKIP_PARENTS = {"Gallon Beverages", "Seasonal Gallon Beverages", "Iced Coffee"}

# Chick-fil-A sells the Frosted Coffees on its Treats menu, and that is where
# they already live. They appear on the Coffee menu too; carrying both would put
# the same drink in two stations under two ids.
SKIP_COFFEE = {"Frosted Coffee"}


def clean(text):
    return re.sub(r"\s+", " ", text.replace("®", "").replace("™", "")).strip()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", clean(text).lower()).strip("-")


def fields_of(row):
    return {f["label"]: f["value"] for f in row["fields"]}


def allergens_of(menu, title):
    row = ALG[menu].get(title)
    if not row:
        return []
    return sorted(ALLERGEN_KEY[f["key"]] for f in row["fields"]
                  if f.get("value") == "1" and f["key"] in ALLERGEN_KEY)


def build(menu, title, *, name=None, group=None, label=None, default=False):
    f = fields_of(SOURCE[menu][title])
    display = clean(name or title)
    d = {
        "id": f"{P}.drinks.{slug(name or title)}",
        "name": display,
        "servingDescription": str(f.get("Serving Size", "1 serving")),
        "macros": {"calories": float(f["Calories"]), "proteinGrams": float(f["Protein (g)"]),
                   "carbGrams": float(f["Carbohydrates (g)"]), "fatGrams": float(f["Fat (g)"])},
    }
    if group:
        d["sizeGroup"] = f"{P}.size.drinks.{group}"
        d["sizeLabel"] = label
        d["isDefaultSize"] = default
    d["allergens"] = allergens_of(menu, title)
    d["notes"] = None
    d["iconName"] = None
    # Nothing on a drinks menu is meat, pork, honey or alcohol.
    d["dietaryMarkers"] = []
    return d


SOURCE = {}
for menu in ("Drinks", "Coffee"):
    SOURCE[menu] = {}
    for parent in NUT[menu]:
        SOURCE[menu][parent["title"]] = parent
        for sub in parent.get("sub_items", []):
            SOURCE[menu][sub["title"]] = sub

items, seen = [], set()


def add(entry):
    if entry["id"] in seen:
        return False
    seen.add(entry["id"])
    items.append(entry)
    return True


# ---------------------------------------------------------------------- drinks
for parent in NUT["Drinks"]:
    title = parent["title"]
    if title in SKIP_PARENTS:
        continue
    subs = parent.get("sub_items", [])
    sized = [s for s in subs if SIZE_RE.match(s["title"])]
    if sized:
        group = slug(title)
        for sub in sized:
            label = SIZE_RE.match(sub["title"]).group(1)
            add(build("Drinks", sub["title"], name=f"{clean(title)} ({label})",
                      group=group, label=label, default=label == "Medium"))
    else:
        add(build("Drinks", title))

# ---------------------------------------------------------------------- coffee
for parent in NUT["Coffee"]:
    if parent["title"] in SKIP_COFFEE:
        continue
    subs = parent.get("sub_items", [])
    if subs:
        for sub in subs:
            add(build("Coffee", sub["title"]))
    else:
        add(build("Coffee", parent["title"]))

menu = json.loads(OUT.read_text())
menu["categories"] = [c for c in menu["categories"] if c["id"] != "drinks"]
hidden = [c for c in menu["categories"] if c.get("isHidden")]
menu["categories"] = [c for c in menu["categories"] if not c.get("isHidden")]
menu["categories"].append({
    "id": "drinks", "name": "Drinks", "selectionRule": {"kind": "selectMany"},
    "items": items, "iconName": None, "isCompleteMeal": False,
})
menu["categories"] += hidden
OUT.write_text(json.dumps(menu, indent=1) + "\n")

groups = {i.get("sizeGroup") or i["id"] for i in items}
print(f"{len(items)} drink items in {len(groups)} rows")
print("skipped as catering:", ", ".join(sorted(SKIP_PARENTS)))
print("total items:", sum(len(c["items"]) for c in menu["categories"]))
