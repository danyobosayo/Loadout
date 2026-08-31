#!/usr/bin/env python3
"""Apply Loadout's audited Panda Express curation rules.

The bundled JSON remains the reviewed nutrition snapshot. This script is an
idempotent curator: it removes temporary items and generic fountain drinks,
normalizes the current order-builder names, and records the live serving rule
for Super Greens. It intentionally does not fetch a private scratch export or
invent macros for a current item that is absent from Panda's nutrition table.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "Loadout" / "Resources" / "Menus" / "panda-express.json"
PRESETS_OUT = ROOT / "Loadout" / "Resources" / "Presets" / "panda-express.presets.json"

APPROVED_CRAFTED_DRINKS = {
    "panda-express.drinks.peach-lychee-refresher":
        "Peach Lychee Flavored Refresher",
    "panda-express.drinks.pomegranate-pineapple-lemonade":
        "Pomegranate Pineapple Flavored Lemonade",
    "panda-express.drinks.watermelon-mango-refresher":
        "Watermelon Mango Flavored Refresher",
}

EXCLUDED_ITEM_IDS = {
    # Current promotional entrée. PROJECT.md excludes limited-time items.
    "panda-express.entrees.hot-orange-chicken",
    # Former crafted drink no longer present at the reviewed live location.
    "panda-express.drinks.mango-guava-tea",
}

BALANCED_PROTEIN_PRESETS = {
    "restaurantId": "panda-express",
    "presets": [
        {
            "id": "panda-express.presets.double-protein-plate",
            "name": "Double Protein Plate",
            "blurb": "Double teriyaki chicken with half rice and half greens. 875 kcal, 76g protein.",
            "items": [
                {
                    "menuItemId": "panda-express.entrees.grilled-teriyaki-chicken",
                    "quantity": 2,
                },
                {
                    "menuItemId": "panda-express.sides.white-steamed-rice",
                    "quantity": 0.5,
                },
                {
                    "menuItemId": "panda-express.sides.super-greens",
                    "quantity": 0.5,
                },
            ],
            "sourceNote": (
                "Composition and published 875 kcal / 76 g protein from Panda Express's "
                "live Balanced Protein Plates builder at Golden Link Blvd. & E Aurora Rd "
                "(reviewed 2026-08-31). The builder offers Teriyaki Sauce separately and "
                "does not include it in the plate's displayed total, so the preset omits it."
            ),
        },
        {
            "id": "panda-express.presets.harmonious-macros-plate",
            "name": "Harmonious Macros Plate",
            "blurb": "Teriyaki chicken and broccoli beef with Super Greens. 555 kcal, 57g protein.",
            "items": [
                {
                    "menuItemId": "panda-express.entrees.grilled-teriyaki-chicken",
                    "quantity": 1,
                },
                {
                    "menuItemId": "panda-express.entrees.broccoli-beef",
                    "quantity": 1,
                },
                {
                    "menuItemId": "panda-express.sides.super-greens",
                    "quantity": 1,
                },
            ],
            "sourceNote": (
                "Composition and published 555 kcal / 57 g protein from Panda Express's "
                "live Balanced Protein Plates builder at Golden Link Blvd. & E Aurora Rd "
                "(reviewed 2026-08-31). The builder offers Teriyaki Sauce separately and "
                "does not include it in the plate's displayed total, so the preset omits it."
            ),
        },
    ],
}


def main() -> None:
    menu = json.loads(OUT.read_text(encoding="utf-8"))
    categories = {category["id"]: category for category in menu["categories"]}

    entrees = categories["entrees"]["items"]
    entrees[:] = [item for item in entrees if item["id"] not in EXCLUDED_ITEM_IDS]

    original_orange = next(
        item for item in entrees
        if item["id"] == "panda-express.entrees.orange-chicken"
    )
    original_orange["name"] = "The Original Orange Chicken"

    # The live combo builder offers Super Greens as an entrée slot at the same
    # 130 calories as the 10 oz side. Panda's nutrition table separately lists
    # a 7 oz / 90 calorie "super greens entree" row. Use the amount the current
    # order builder actually places in the meal, with the side row supplying all
    # four supported macros rather than extrapolating from calories alone.
    side_greens = next(
        item for item in categories["sides"]["items"]
        if item["id"] == "panda-express.sides.super-greens"
    )
    entree_greens = next(
        item for item in entrees
        if item["id"] == "panda-express.entrees.super-greens-entree"
    )
    entree_greens.update({
        "name": "Super Greens",
        "servingDescription": "1 entree slot (10.0 oz live-builder serving)",
        "macros": side_greens["macros"],
        "notes": (
            "The reviewed live builder shows the full 130-calorie Super Greens "
            "serving in an entree slot; Panda's table also lists a separate "
            "7 oz / 90 calorie entree row."
        ),
    })

    drinks = categories["drinks"]["items"]
    approved = []
    for item in drinks:
        if item["id"] not in APPROVED_CRAFTED_DRINKS:
            continue
        item["name"] = APPROVED_CRAFTED_DRINKS[item["id"]]
        item.pop("sizeGroup", None)
        item.pop("sizeLabel", None)
        item.pop("isDefaultSize", None)
        approved.append(item)
    categories["drinks"]["items"] = approved

    missing = set(APPROVED_CRAFTED_DRINKS) - {item["id"] for item in approved}
    if missing:
        raise ValueError(f"Missing approved Panda crafted drinks: {sorted(missing)}")

    menu["dataSource"] = {
        "url": "https://www.pandaexpress.com/nutritioninformation",
        "fetchedAt": "2026-08-31",
        "fetchedBy": "manual-browser-review",
        "notes": (
            "Food macros come from Panda Express's current US nutrition table. "
            "Ordering rules and availability were checked at Golden Link Blvd. "
            "& E Aurora Rd. Generic fountain and retail drinks, current Hot "
            "Orange Chicken, and former Mango Guava Tea are intentionally "
            "excluded. Three 24 oz Panda Crafted Beverages with complete "
            "official macros remain. Strawberry Dragonfruit is visible in the "
            "live menu but omitted because the nutrition table has no row for it."
        ),
    }

    OUT.write_text(json.dumps(menu, indent=1) + "\n", encoding="utf-8")
    PRESETS_OUT.write_text(
        json.dumps(BALANCED_PROTEIN_PRESETS, indent=2) + "\n",
        encoding="utf-8",
    )
    visible_items = sum(len(category["items"]) for category in menu["categories"])
    print(
        f"Wrote {OUT.relative_to(ROOT)}: {visible_items} items; "
        f"{len(approved)} Panda Crafted Beverages; "
        f"{len(BALANCED_PROTEIN_PRESETS['presets'])} Balanced Protein Plates"
    )


if __name__ == "__main__":
    main()
