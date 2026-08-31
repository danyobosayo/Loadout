#!/usr/bin/env python3
"""Release the Panera drinks the dairy guard was holding back.

When Panera's drinks landed, every latte, smoothie and hot chocolate was withheld:
the nutrition guide they came from has no allergen column at all, and shipping
`allergens: []` on a latte would have claimed "checked, contains no milk".

Panera publishes allergens in a *separate* first-party document
(`c6-26-allergen-guide.pdf`, linked from the same nutrition page), which the
original pass never found. It carries a per-product row with eight allergen
columns, beverages included. So these can now ship with sourced allergens.

Two things this does NOT do:

- **The kids' organic milks stay held.** They are simply absent from the allergen
  guide, so there is still nothing to cite. Obvious as it may be that milk
  contains milk, `[]` here would be a claim about a product the source never
  covers, and this is a children's drink.
- **It does not invent an "iced" row.** Four drinks matched a row named e.g.
  "Caffe Latte (espresso - Hot or Iced)" — the source explicitly covers both
  temperatures in one row, which is why "Iced Caffe Latte" resolves to it.
"""
import difflib
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/panera.json")
P = "panera"
COLUMNS = ["wheat", "treenut", "peanut", "milk", "soy", "egg", "fish", "sesame"]

allergen_rows = json.loads(open(f"{SP}/panera_allergen_rows.json").read())
drinks = json.loads(open(f"{SP}/drinks_workflow.json").read())["source"][P]["drinks"]

DAIRY = re.compile(
    r"latte|cappuccino|macchiato|mocha|smoothie|shake|milk|cream|chai|horchata|"
    r"yogurt|frapp|almond|oat|soy|au lait|hot chocolate|cocoa", re.I)


def norm(text):
    text = re.sub(r"\s*-\s*\d+\s*fl oz(\s*can)?\s*$", "", text, flags=re.I)
    text = re.sub(r"\s*\(.*?\)", "", text)
    text = re.sub(r"\s*-\s*Naturally Flavored", "", text, flags=re.I)
    return re.sub(r"[^a-z0-9 ]", "", text.lower()).strip()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


# Section headers carry no values in any column and must never match a product.
products = {k: v for k, v in allergen_rows.items() if any(v)}
index = {norm(k): k for k in products}
# A row saying "Hot or Iced" covers its iced form; that is the source's own wording.
for key, original in list(index.items()):
    if "hot or iced" in original.lower():
        index.setdefault(f"iced {key}", original)


def allergens_for(name):
    key = norm(name)
    match = index.get(key)
    if not match:
        close = difflib.get_close_matches(key, list(index), n=1, cutoff=0.86)
        match = index[close[0]] if close else None
    if not match:
        return None, None
    values = dict(zip(COLUMNS, products[match]))
    if any("no major" in (v or "") for v in values.values()):
        return [], match
    return sorted(k for k, v in values.items() if v == "yes"), match


released, still_held = [], []
for drink in drinks:
    if not DAIRY.search(drink["name"]):
        continue
    found, source_row = allergens_for(drink["name"])
    if found is None:
        still_held.append(drink["name"])
        continue
    released.append({
        "id": f"{P}.drinks.{slug(drink['name'])}",
        "name": re.sub(r"\s+", " ", drink["name"]).strip(),
        "servingDescription": drink.get("servingDescription") or "1 serving",
        "macros": {
            "calories": round(float(drink["calories"]), 1),
            "proteinGrams": round(float(drink["proteinGrams"]), 1),
            "carbGrams": round(float(drink["carbGrams"]), 1),
            "fatGrams": round(float(drink["fatGrams"]), 1),
        },
        **({"sizeGroup": f"{P}.size.drinks.{slug(drink['sizeGroup'])}",
            "sizeLabel": drink["sizeLabel"],
            "isDefaultSize": bool(drink.get("isDefaultSize"))}
           if drink.get("sizeGroup") and drink.get("sizeLabel") else {}),
        "allergens": found,
        "notes": None,
        "iconName": None,
        "dietaryMarkers": [],
    })

menu = json.loads(OUT.read_text())
station = next(c for c in menu["categories"] if c["id"] == "drinks")
existing = {i["id"] for i in station["items"]}
added = [i for i in released if i["id"] not in existing]
station["items"].extend(added)

# Exactly one default per size group, or the row renders with nothing selected.
groups = {}
for item in station["items"]:
    if item.get("sizeGroup"):
        groups.setdefault(item["sizeGroup"], []).append(item)
for members in groups.values():
    if sum(1 for m in members if m.get("isDefaultSize")) == 1:
        continue
    for m in members:
        m["isDefaultSize"] = False
    min(members, key=lambda m: m["macros"]["calories"])["isDefaultSize"] = True

OUT.write_text(json.dumps(menu, indent=1) + "\n")

print(f"released {len(added)} drinks with sourced allergens")
for i in added[:8]:
    print(f"   {i['name'][:44]:46} {i['allergens']}")
print(f"\nstill held ({len(still_held)}) — absent from Panera's allergen guide:")
for n in still_held:
    print(f"   {n}")
print("\ndrinks station:", len(station["items"]), "items")
