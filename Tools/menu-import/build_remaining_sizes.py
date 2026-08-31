#!/usr/bin/env python3
"""Collapse the remaining size duplicates — Panera, Jersey Mike's, Qdoba.

Every family here was read against its own data before being grouped, because
`SizeGroup`'s own rule is that curation decides and code obeys: "Chicken Noodle
Soup - Cup" and "- Bowl" are one dish, but two rows sharing a prefix are not
automatically one dish.

**Moe's is deliberately left alone** — see the note at the bottom.
"""
import json
import pathlib
import re

MENUS = pathlib.Path("Loadout/Resources/Menus")


def apply(restaurant_id, families):
    """`families` is [(category_id, group_key, [(item_name, size_label)], default)]."""
    path = MENUS / f"{restaurant_id}.json"
    menu = json.loads(path.read_text())
    by_category = {c["id"]: {i["name"]: i for i in c["items"]} for c in menu["categories"]}
    applied = 0

    for category_id, key, members, default in families:
        items = by_category[category_id]
        missing = [name for name, _ in members if name not in items]
        if missing:
            raise SystemExit(f"{restaurant_id}/{key}: no such item {missing}")
        for name, label in members:
            items[name]["sizeGroup"] = f"{restaurant_id}.size.{key}"
            items[name]["sizeLabel"] = label
            items[name]["isDefaultSize"] = label == default
        applied += 1

    path.write_text(json.dumps(menu, indent=1) + "\n")
    rows = sum(len(c["items"]) for c in menu["categories"]) - sum(len(m) for _, _, m, _ in families) + applied
    print(f"{restaurant_id:14} {applied} groups · "
          f"{sum(len(c['items']) for c in menu['categories'])} items -> {rows} rows")


# ---------------------------------------------------------------------- panera
# 8 soups, each in Cup / Bowl / Bread Bowl. A cup is what a You Pick Two pairs
# with, so it's the default.
panera = json.loads((MENUS / "panera.json").read_text())
SOUP_SUFFIX = re.compile(r"^(.*?)\s*-\s*(Cup|Bowl|Bread Bowl)\s*$", re.I)
soup_families = {}
for category in panera["categories"]:
    for item in category["items"]:
        match = SOUP_SUFFIX.match(item["name"])
        if not match:
            continue
        base, label = match.group(1).strip(), match.group(2).title()
        key = re.sub(r"[^a-z0-9]+", "-", base.lower()).strip("-")
        soup_families.setdefault((category["id"], key), []).append((item["name"], label))

apply("panera", [(cat, key, members, "Cup")
                 for (cat, key), members in soup_families.items() if len(members) > 1])

# --------------------------------------------------------------- jersey mike's
# Sub rolls come in Mini / Regular / Giant; the unsuffixed row is the Regular.
# Fries are the same fries at two weights — the 5 oz is what a sub comes with.
JM_BREADS = ["White Bread", "Wheat Bread", "Rosemary Parmesan Bread",
             "Seeded Italian Bread", "Gluten Free Bread"]
jm = []
jm_items = {i["name"] for c in json.loads((MENUS / "jersey-mikes.json").read_text())["categories"]
            for i in c["items"]}
for bread in JM_BREADS:
    members = [(bread, "Regular")]
    for label in ("Mini", "Giant"):
        if f"{bread} ({label})" in jm_items:
            members.append((f"{bread} ({label})", label))
    if len(members) > 1:
        key = re.sub(r"[^a-z0-9]+", "-", bread.lower()).strip("-")
        jm.append(("breads", key, members, "Regular"))
jm.append(("sides", "french-fries",
           [("French Fries (5 oz)", "5 oz"), ("French Fries (6 oz)", "6 oz")], "5 oz"))
apply("jersey-mikes", jm)

# ----------------------------------------------------------------------- qdoba
# Portion tiers, all stated outright in Qdoba's own serving lines ("regular",
# "kids portion", "double"). The unsuffixed row is the regular scoop.
apply("qdoba", [
    ("protein", "bacon",
     [("Bacon", "2 oz"), ("Bacon (1 oz)", "1 oz")], "2 oz"),
    ("dips", "hand-crafted-guacamole",
     [("Hand Crafted Guacamole", "2 oz"), ("Hand Crafted Guacamole (4 oz)", "4 oz")], "2 oz"),
    ("dips", "three-cheese-queso",
     [("Three Cheese Queso", "2 oz"), ("Three Cheese Queso (4 oz)", "4 oz"),
      ("Three Cheese Queso (kids, 1 oz)", "1 oz")], "2 oz"),
    ("dips", "queso-diablo",
     [("Queso Diablo", "2 oz"), ("Queso Diablo (4 oz)", "4 oz")], "2 oz"),
    ("chips", "tortilla-chips",
     [("Tortilla Chips", "4 oz"), ("Tortilla Chips (Small)", "2 oz")], "4 oz"),
])

print("""
Moe's is deliberately NOT grouped. Its four rice rows are not four sizes of one
thing: "Seasoned Rice (burrito portion)" is what goes inside a burrito while
"(cup)" and "(bowl)" are sides you order. Folding them into one picker would let
someone choose "bowl" as the rice in their burrito. Four rows that mean four
different things is not the duplication this collapse exists to fix.""")
