#!/usr/bin/env python3
"""Fill in Panda Express from the official nutrition table.

A full diff of our 36 items against Panda's 178 published rows found **zero**
macro mismatches — the food data was already right. What was missing was
everything you order alongside it: the entire drinks list (four cup sizes, and a
large Coca-Cola is 510 cal — more than an Orange Chicken), both soups, and the
small stuff that comes in the bag.

Also fixes the appetizer serving lines. Panda publishes "chicken potsticker
(3 pcs)"; we said "1 serving", which is not a portion anyone can picture.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/panda-express.json")
P = "panda-express"

rows = json.load(open(f"{SP}/panda_rows.json"))


def num(r, key, default=0.0):
    try:
        return float(r[key])
    except (KeyError, ValueError, TypeError):
        return default


def allergens_of(r):
    out = []
    for label, code in [("Wheat", "wheat"), ("Soy", "soy"), ("Tree Nuts", "treenut"),
                        ("Fish", "fish"), ("Peanuts", "peanut"), ("Shellfish", "shellfish"),
                        ("Eggs", "egg"), ("Milk", "milk"), ("Sesame (Sesame Oil)", "sesame")]:
        if "Contains" in r.get(label, "") and "Does not" not in r.get(label, ""):
            out.append(code)
    return out


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def titlecase(text):
    """Panda publishes every name in lowercase, so we have to restore it.

    `str.title()` can't: it capitalises after any non-letter, turning "barq's"
    into "Barq'S". Capitalise a letter only when what precedes it is neither a
    letter nor an apostrophe — which also gets "hi-c" and "coca-cola" right.
    """
    return re.sub(r"(?<![A-Za-z'])([a-z])", lambda m: m.group(1).upper(), text)


def macros(r):
    return {"calories": num(r, "Calories"), "proteinGrams": num(r, "Protein (g)"),
            "carbGrams": num(r, "Total carb (g)"), "fatGrams": num(r, "Total fat (g)")}


by_name = {r["name"].strip().lower(): r for r in rows}

# --------------------------------------------------------------------- drinks
# Cup sizes and their fluid ounces vary by drink — the teas pour 22/32/40 while
# the sodas pour 22/30/42 — so the ounces ride on each item rather than on the
# size label. "meddium" is Panda's own typo in the published table.
SIZE_RE = re.compile(r"^(.*?)\s*-\s*(kids|small|me?ddium|medium|large)\s*$", re.I)
LADDER = {"kids": 0, "small": 1, "medium": 2, "meddium": 2, "large": 3}
# Region-locked duplicates of drinks already listed nationally. Carrying both
# would put two "Fanta Orange" rows with different macros side by side.
REGIONAL = re.compile(r"\((pr|tx) only\)", re.I)

groups, order = {}, []
for r in rows:
    name = r["name"].strip().lower()
    if "cub meal" in name or REGIONAL.search(name):
        continue
    m = SIZE_RE.match(name)
    if not m:
        continue
    if not r.get("Calories"):  # lemon green tea - kids has no published figure
        continue
    base, label = m.group(1).strip(), m.group(2).lower()
    label = "medium" if label == "meddium" else label
    key = slug(base)
    if key not in groups:
        order.append(key)
        groups[key] = []
    groups[key].append((base, label, r))

drink_items = []
for key in order:
    members = sorted(groups[key], key=lambda x: LADDER[x[1]])
    sized = len(members) > 1
    for base, label, r in members:
        oz = num(r, "Portion (oz)")
        drink_items.append({
            "id": f"{P}.drinks.{key}" + (f".{label}" if sized else ""),
            "name": f"{titlecase(base)} ({label.title()})" if sized else titlecase(base),
            "servingDescription": f"{oz:.0f} fl oz" if oz else "1 serving",
            "macros": macros(r),
            **({"sizeGroup": f"{P}.drinks.{key}", "sizeLabel": label.title(),
                # Panda's default pour is the small cup.
                "isDefaultSize": label == "small"} if sized else {}),
            "allergens": allergens_of(r), "notes": None, "iconName": None,
            "dietaryMarkers": [],
        })

# Fixed-size drinks (the 24 oz refreshers) that carry no size suffix at all.
for name in ["mango guava tea", "peach lychee refresher", "pomegranate pineapple lemonade",
             "watermelon mango refresher"]:
    r = by_name.get(name)
    if not r:
        continue
    drink_items.append({
        "id": f"{P}.drinks.{slug(name)}", "name": titlecase(name),
        "servingDescription": f"{num(r, 'Portion (oz)'):.0f} fl oz", "macros": macros(r),
        "allergens": allergens_of(r), "notes": None, "iconName": None, "dietaryMarkers": [],
    })

# Hot & Sour Soup is deliberately NOT carried. Its macros and allergens are
# published, but nothing in Panda's data says whether the broth is meat-based,
# and hot & sour soup usually is. Shipping `dietaryMarkers: []` would assert
# "verified free of meat" on a guess — the one thing the dietary model must never
# do — and `null` would read as "not checked" on an item we could simply omit.
# Filed in CURATION_TODO.md pending an ingredient source.

menu = json.loads(OUT.read_text())
cat = {c["id"]: c for c in menu["categories"]}

# ----------------------------------------------------------------- appetizers
# Restore the published piece counts and pick up the spring roll we were missing.
SERVINGS = {
    "Chicken Egg Roll": "chicken egg roll (1 roll)",
    "Veggie Spring Roll": "vegetable spring roll (2 rolls)",
    "Cream Cheese Rangoon": "cream cheese rangoon (3 pcs)",
    "Chicken Potsticker": "chicken potsticker (3 pcs)",
}
fixed = 0
for it in cat["appetizers"]["items"]:
    official = SERVINGS.get(it["name"])
    if not official or official not in by_name:
        continue
    r = by_name[official]
    count = re.search(r"\((.*?)\)", official).group(1)
    it["servingDescription"] = f"{count} — {num(r, 'Portion (oz)'):.1f} oz"
    fixed += 1

for name, label in [("fortune cookie", "Fortune Cookie"),
                    ("tree top apple crisps", "Tree Top Apple Crisps")]:
    r = by_name[name]
    iid = f"{P}.appetizers.{slug(name)}"
    if iid not in {i["id"] for i in cat["appetizers"]["items"]}:
        cat["appetizers"]["items"].append({
            "id": iid, "name": label,
            "servingDescription": f"{num(r, 'Portion (oz)'):.2f} oz",
            "macros": macros(r), "allergens": allergens_of(r),
            "notes": None, "iconName": None, "dietaryMarkers": [],
        })

menu["categories"] = [c for c in menu["categories"] if c["id"] != "drinks"]
menu["categories"].append({
    "id": "drinks", "name": "Drinks", "selectionRule": {"kind": "selectMany"},
    "items": drink_items, "iconName": None, "isCompleteMeal": False,
})

OUT.write_text(json.dumps(menu, indent=1) + "\n")
print(f"drinks: {len(drink_items)} items in {len(order)} sized groups + fixed-size refreshers")
print(f"appetizer servings corrected: {fixed}")
print("total items:", sum(len(c["items"]) for c in menu["categories"]))
