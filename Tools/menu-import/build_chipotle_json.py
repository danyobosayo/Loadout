"""
Tools/menu-import/build_chipotle_json.py

Converts chipotle-source.csv into Loadout/Resources/Menus/chipotle.json,
shaped to PROJECT.md §5/§6 (Restaurant / MenuCategory / MenuItem / DataSource
+ SelectionRule). Run after editing the CSV.

The CSV carries fiber/sugar/sodium too, but the app only tracks the four
macros locked in commit 66ac6a0, so only kcal/p/c/f are emitted.

Usage:
    python3 Tools/menu-import/build_chipotle_json.py
"""

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CSV_PATH = Path(__file__).resolve().parent / "chipotle-source.csv"
JSON_PATH = ROOT / "Loadout" / "Resources" / "Menus" / "chipotle.json"

# (display name, selection rule) per category id, in Chipotle line order.
# selectUpTo(1) = at most one of this category in a meal (typical for
# tortilla/rice/beans/dressing/chips/drinks where doubling up makes no sense
# at the line). selectMany = any number, with quantity expressing "extra"
# (proteins, veggies, salsas, toppings).
CATEGORY_META = {
    "tortilla": ("Tortilla", {"kind": "selectUpTo", "max": 1}),
    "rice":     ("Rice",     {"kind": "selectUpTo", "max": 1}),
    "beans":    ("Beans",    {"kind": "selectUpTo", "max": 1}),
    "protein":  ("Protein",  {"kind": "selectMany"}),
    "veggies":  ("Veggies",  {"kind": "selectMany"}),
    "salsa":    ("Salsa",    {"kind": "selectMany"}),
    "toppings": ("Toppings", {"kind": "selectMany"}),
    "dressing": ("Dressing", {"kind": "selectUpTo", "max": 1}),
    "chips":    ("Chips",    {"kind": "selectUpTo", "max": 1}),
}

# Drinks aren't shipped: Loadout's job is fast-food entrée + side macros
# pre-order, and 35 soda variants bury the actual food in the menu. The
# CSV keeps the drinks rows so the file stays faithful to the source PDF —
# filtering happens here. If a future restaurant treats beverages as the
# menu (e.g. Starbucks), drop its category id from this set in that
# restaurant's build script.
EXCLUDED_CATEGORIES: set[str] = {"drinks"}


def parse_macro(s: str) -> float | None:
    if s is None or s.strip() == "":
        return None
    return float(s)


def main() -> None:
    with CSV_PATH.open() as f:
        rows = list(csv.DictReader(f))

    categories: dict[str, dict] = {}
    skipped: list[str] = []
    excluded_count = 0

    for row in rows:
        cat_id = row["category"]
        if cat_id in EXCLUDED_CATEGORIES:
            excluded_count += 1
            continue
        if cat_id not in categories:
            name, rule = CATEGORY_META.get(cat_id, (cat_id.title(), {"kind": "selectMany"}))
            categories[cat_id] = {
                "id": cat_id,
                "name": name,
                "selectionRule": rule,
                "items": [],
            }

        macros = {
            "calories":     parse_macro(row["calories"]),
            "proteinGrams": parse_macro(row["protein_g"]),
            "carbGrams":    parse_macro(row["carbs_g"]),
            "fatGrams":     parse_macro(row["fat_g"]),
        }
        if any(v is None for v in macros.values()):
            skipped.append(f"{row['id']} (missing: {[k for k, v in macros.items() if v is None]})")
            continue

        categories[cat_id]["items"].append({
            "id":                 row["id"],
            "name":               row["name"],
            "servingDescription": row["servingDescription"],
            "macros":             macros,
            "allergens":          None,
            "notes":              row["notes"] or None,
        })

    restaurant = {
        "id": "chipotle",
        "name": "Chipotle",
        "schemaVersion": 1,
        "dataSource": {
            "url": "https://www.chipotle.com/nutrition-calculator",
            "fetchedAt": "2026-05-09",
            "fetchedBy": "manual",
            "notes": (
                "Per Chipotle Nutrition PDF (codes OCT-2024-US-CK / OCT-2024-US-PPS). "
                "See build_chipotle_csv.py for sourcing/exclusion notes."
            ),
        },
        "categories": list(categories.values()),
    }

    JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    with JSON_PATH.open("w") as f:
        json.dump(restaurant, f, indent=2, ensure_ascii=False)
        f.write("\n")

    total_items = sum(len(c["items"]) for c in restaurant["categories"])
    rel = JSON_PATH.relative_to(ROOT)
    print(f"Wrote {rel}: {len(restaurant['categories'])} categories, {total_items} items")
    if excluded_count:
        excluded = sorted(EXCLUDED_CATEGORIES)
        print(f"Excluded {excluded_count} rows by category: {excluded}")
    if skipped:
        print(f"Skipped {len(skipped)} rows with incomplete macros:")
        for s in skipped:
            print(f"  - {s}")


if __name__ == "__main__":
    main()
