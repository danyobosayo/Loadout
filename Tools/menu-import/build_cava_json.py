"""
Tools/menu-import/build_cava_json.py

Converts cava-source.csv into Loadout/Resources/Menus/cava.json, shaped
to PROJECT.md §5/§6. Run after editing the CSV (or build_cava_csv.py
followed by this).

Only the four locked macros (cal/p/c/f) are emitted — fiber/sugar/sodium
stay in the CSV for future use.
"""

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CSV_PATH = Path(__file__).resolve().parent / "cava-source.csv"
JSON_PATH = ROOT / "Loadout" / "Resources" / "Menus" / "cava.json"

# (display name, selectionRule, category-fallback icon) per category id.
# Selection rules reflect CAVA's standard build:
#   - bases:     one base per bowl/pita
#   - dips:      "choose 2" by default at CAVA, can pay for more
#   - mains:     selectMany so users can mix proteins (split chicken+lamb)
#                — the quantity stepper expresses "double protein" too
#   - toppings:  unrestricted
#   - dressings: typically one per bowl
#   - sides:     unrestricted; these are addons, not part of the bowl
CATEGORY_META = {
    "bases":     ("Bases",     {"kind": "selectUpTo", "max": 1}, "lettuce"),
    "dips":      ("Dips & Spreads", {"kind": "selectUpTo", "max": 2}, "hummus"),
    "mains":     ("Mains",     {"kind": "selectMany"},             "chickenGrilled"),
    "toppings":  ("Toppings",  {"kind": "selectMany"},             "vegetables"),
    "dressings": ("Dressings", {"kind": "selectUpTo", "max": 1},   "oil"),
    "sides":     ("Sides",     {"kind": "selectMany"},             "breadPita"),
}


def parse_macro(s: str) -> float | None:
    if s is None or s.strip() == "":
        return None
    return float(s)


def main() -> None:
    with CSV_PATH.open() as f:
        rows = list(csv.DictReader(f))

    categories: dict[str, dict] = {}
    skipped: list[str] = []

    for row in rows:
        cat_id = row["category"]
        if cat_id not in categories:
            name, rule, fallback_icon = CATEGORY_META.get(
                cat_id, (cat_id.title(), {"kind": "selectMany"}, None)
            )
            categories[cat_id] = {
                "id": cat_id,
                "name": name,
                "selectionRule": rule,
                "items": [],
                "iconName": fallback_icon,
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
            "iconName":           row.get("icon") or None,
        })

    restaurant = {
        "id": "cava",
        "name": "CAVA",
        "schemaVersion": 1,
        "dataSource": {
            "url": "https://cava.com/nutrition",
            "fetchedAt": "2026-05-09",
            "fetchedBy": "manual",
            "notes": (
                "Per CAVA Nutrition and Allergen Guide PDF "
                "(code CAVA-REC-GID-0326-AllergReg). The PDF reports "
                "per-recipe macros without explicit gram/oz weights, so "
                "every servingDescription is '1 portion' (with '1 pita' / "
                "'1 piece' for sides where it's clearly singular). "
                "Curated bowls/pitas, kids meals, and drinks are "
                "intentionally excluded — see build_cava_csv.py."
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
    if skipped:
        print(f"Skipped {len(skipped)} rows with incomplete macros:")
        for s in skipped:
            print(f"  - {s}")


if __name__ == "__main__":
    main()
