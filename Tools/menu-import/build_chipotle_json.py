"""Build Loadout's durable Chipotle menu from the audited CSV.

The CSV retains the older first-party fountain tables for provenance, but the
app intentionally ships only Chipotle's distinctive Tractor beverages. Current
ordering rules that combine ingredients from several stations are represented
as hidden, format-only categories.
"""

import csv
import json
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CSV_PATH = Path(__file__).resolve().parent / "chipotle-source.csv"
JSON_PATH = ROOT / "Loadout" / "Resources" / "Menus" / "chipotle.json"

CATEGORY_META = {
    "tortilla": ("Tortilla", {"kind": "selectUpTo", "max": 1}, "wheatFlat"),
    "rice": ("Rice", {"kind": "selectUpTo", "max": 1}, "riceWhiteBowl"),
    "beans": ("Beans", {"kind": "selectUpTo", "max": 1}, "beansPan"),
    "protein": ("Protein", {"kind": "selectMany"}, "chicken"),
    "veggies": ("Veggies", {"kind": "selectMany"}, "vegetables"),
    "salsa": ("Salsa", {"kind": "selectMany"}, "salsa"),
    "toppings": ("Toppings", {"kind": "selectMany"}, "cheeseSlice"),
    "dressing": ("Dressing", {"kind": "selectUpTo", "max": 1}, "oil"),
    "chips": ("Chips", {"kind": "selectUpTo", "max": 1}, "chipsBaked"),
    "drinks": ("Drinks", {"kind": "selectMany"}, None),
}

TRACTOR_DRINKS = {
    "chipotle.drinks.tractor-berry-22": (
        "chipotle.drinks.22-fl-oz-tractor-organic-berry-agua-fresca",
        "22 fl oz Tractor Organic Berry Agua Fresca", "Regular", True,
        "chipotle.size.drinks.tractor-organic-berry-agua-fresca",
    ),
    "chipotle.drinks.tractor-berry-32": (
        "chipotle.drinks.32-fl-oz-tractor-organic-berry-agua-fresca",
        "32 fl oz Tractor Organic Berry Agua Fresca", "Large", False,
        "chipotle.size.drinks.tractor-organic-berry-agua-fresca",
    ),
    "chipotle.drinks.tractor-watermelon-22": (
        "chipotle.drinks.22-fl-oz-tractor-organic-watermelon-limeade",
        "22 fl oz Tractor Organic Watermelon Limeade", "Regular", True,
        "chipotle.size.drinks.tractor-organic-watermelon-limeade",
    ),
    "chipotle.drinks.tractor-watermelon-32": (
        "chipotle.drinks.32-fl-oz-tractor-organic-watermelon-limeade",
        "32 fl oz Tractor Organic Watermelon Limeade", "Large", False,
        "chipotle.size.drinks.tractor-organic-watermelon-limeade",
    ),
    "chipotle.drinks.tractor-lemonade-22": (
        "chipotle.drinks.22-fl-oz-tractor-organic-lemonade",
        "22 fl oz Tractor Organic Lemonade", "Regular", True,
        "chipotle.size.drinks.tractor-organic-lemonade",
    ),
    "chipotle.drinks.tractor-lemonade-32": (
        "chipotle.drinks.32-fl-oz-tractor-organic-lemonade",
        "32 fl oz Tractor Organic Lemonade", "Large", False,
        "chipotle.size.drinks.tractor-organic-lemonade",
    ),
    "chipotle.drinks.tractor-mandarin-22": (
        "chipotle.drinks.22-fl-oz-tractor-organic-mandarin-agua-fresca",
        "22 fl oz Tractor Organic Mandarin Agua Fresca", "Regular", True,
        "chipotle.size.drinks.tractor-organic-mandarin-agua-fresca",
    ),
    "chipotle.drinks.tractor-mandarin-32": (
        "chipotle.drinks.32-fl-oz-tractor-organic-mandarin-agua-fresca",
        "32 fl oz Tractor Organic Mandarin Agua Fresca", "Large", False,
        "chipotle.size.drinks.tractor-organic-mandarin-agua-fresca",
    ),
}

TACO_TOPPING_IDS = [
    "chipotle.rice.cilantro-lime-white", "chipotle.rice.cilantro-lime-brown",
    "chipotle.beans.black", "chipotle.beans.pinto",
    "chipotle.salsa.fresh-tomato", "chipotle.salsa.roasted-corn",
    "chipotle.salsa.tomatillo-green", "chipotle.salsa.tomatillo-red",
    "chipotle.toppings.sour-cream", "chipotle.veggies.fajita-vegetables",
    "chipotle.toppings.cheese", "chipotle.veggies.romaine",
]

QUESADILLA_SIDE_IDS = [
    "chipotle.salsa.fresh-tomato", "chipotle.salsa.roasted-corn",
    "chipotle.salsa.tomatillo-green", "chipotle.salsa.tomatillo-red",
    "chipotle.toppings.sour-cream",
    "chipotle.rice.cilantro-lime-white", "chipotle.rice.cilantro-lime-brown",
    "chipotle.beans.black", "chipotle.beans.pinto",
    "chipotle.dressing.chipotle-honey-vinaigrette",
]

TACO_ADD_ON_IDS = [
    "chipotle.toppings.guacamole", "chipotle.toppings.queso-entree",
]

QUESADILLA_ADD_ON_IDS = [
    "chipotle.toppings.guacamole", "chipotle.toppings.queso-side",
]

BURRITO_OPTION_IDS = [
    "chipotle.tortilla.flour-burrito",
]

# Retain historical source rows in the CSV, but never ship temporary proteins
# in the durable menu. The current Pollo Asado and earlier Carne Asada are both
# excluded under PROJECT.md's no-limited-time-items policy.
EXCLUDED_ITEM_IDS = {
    "chipotle.protein.carne-asada",
    "chipotle.protein.pollo-asado",
}


def number(value: str) -> float:
    return float(value)


def markers(item_id: str) -> list[str]:
    if item_id in {
        "chipotle.protein.chicken", "chipotle.protein.steak",
        "chipotle.protein.barbacoa", "chipotle.protein.carnitas",
    }:
        result = ["meat"]
        if item_id.endswith("carnitas"):
            result.append("pork")
        return result
    if item_id == "chipotle.dressing.chipotle-honey-vinaigrette":
        return ["honey"]
    return []


def allergens(item_id: str) -> list[str]:
    if item_id in {
        "chipotle.tortilla.flour-burrito", "chipotle.tortilla.flour-taco",
    }:
        return ["wheat"]
    if item_id == "chipotle.protein.sofritas":
        return ["soy"]
    if item_id in {
        "chipotle.toppings.cheese", "chipotle.toppings.sour-cream",
        "chipotle.toppings.queso-entree", "chipotle.toppings.queso-side",
        "chipotle.toppings.queso-large",
    }:
        return ["milk"]
    return []


def make_item(row: dict[str, str]) -> dict:
    item_id = row["id"]
    item = {
        "id": item_id,
        "name": "Beef Barbacoa" if item_id == "chipotle.protein.barbacoa" else row["name"],
        "servingDescription": row["servingDescription"],
        "macros": {
            "calories": number(row["calories"]),
            "proteinGrams": number(row["protein_g"]),
            "carbGrams": number(row["carbs_g"]),
            "fatGrams": number(row["fat_g"]),
        },
        "allergens": allergens(item_id),
        "notes": row["notes"] or None,
        "iconName": row.get("icon") or None,
        "dietaryMarkers": markers(item_id),
    }
    if item_id in TRACTOR_DRINKS:
        new_id, name, size_label, is_default, size_group = TRACTOR_DRINKS[item_id]
        item.update({
            "id": new_id,
            "name": name,
            "sizeGroup": size_group,
            "sizeLabel": size_label,
            "isDefaultSize": is_default,
        })
    return item


def hidden_category(
    category_id: str,
    name: str,
    source_ids: list[str],
    by_id: dict[str, dict],
    selection_rule: dict | None = None,
) -> dict:
    items = []
    for source_id in source_ids:
        source = deepcopy(by_id[source_id])
        suffix = source_id.removeprefix("chipotle.").replace(".", "-")
        source["id"] = f"chipotle.{category_id}.{suffix}"
        source["notes"] = f"Format-only copy of {source_id}."
        items.append(source)
    return {
        "id": category_id,
        "name": name,
        "selectionRule": selection_rule or {"kind": "selectMany"},
        "items": items,
        "iconName": None,
        "isCompleteMeal": False,
        "isHidden": True,
    }


def main() -> None:
    rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))
    categories: dict[str, dict] = {}
    by_id: dict[str, dict] = {}

    for row in rows:
        category_id = row["category"]
        if row["id"] in EXCLUDED_ITEM_IDS:
            continue
        if category_id == "drinks" and row["id"] not in TRACTOR_DRINKS:
            continue
        name, rule, fallback_icon = CATEGORY_META[category_id]
        category = categories.setdefault(category_id, {
            "id": category_id,
            "name": name,
            "selectionRule": rule,
            "items": [],
            "iconName": fallback_icon,
            "isCompleteMeal": False,
        })
        item = make_item(row)
        category["items"].append(item)
        by_id[row["id"]] = item

    categories["taco-toppings"] = hidden_category(
        "taco-toppings", "Included Toppings", TACO_TOPPING_IDS, by_id,
    )
    categories["quesadilla-sides"] = hidden_category(
        "quesadilla-sides", "Included Sides", QUESADILLA_SIDE_IDS, by_id,
    )
    categories["taco-add-ons"] = hidden_category(
        "taco-add-ons", "Add-Ons", TACO_ADD_ON_IDS, by_id,
    )
    categories["quesadilla-add-ons"] = hidden_category(
        "quesadilla-add-ons", "Add-Ons", QUESADILLA_ADD_ON_IDS, by_id,
    )
    categories["burrito-options"] = hidden_category(
        "burrito-options", "Double Wrap", BURRITO_OPTION_IDS, by_id,
        {"kind": "selectUpTo", "max": 1},
    )
    categories["burrito-options"]["items"][0].update({
        "id": "chipotle.burrito-options.double-wrap",
        "name": "Extra Flour Tortilla (Double Wrap)",
        "notes": "Format-only second tortilla for Chipotle's Double Wrap option.",
    })

    restaurant = {
        "id": "chipotle",
        "name": "Chipotle",
        "schemaVersion": 1,
        "dataSource": {
            "url": "https://www.chipotle.com/nutrition-calculator",
            "fetchedAt": "2026-08-31",
            "fetchedBy": "manual",
            "notes": (
                "Stable ingredient macros checked against Chipotle's current calculator and "
                "March 2025 US nutrition PDF. Ordering rules checked at restaurant 1800. "
                "Limited-time items and generic fountain/bottled drinks are intentionally excluded."
            ),
        },
        "categories": list(categories.values()),
    }
    JSON_PATH.write_text(json.dumps(restaurant, indent=1) + "\n", encoding="utf-8")
    visible = [c for c in restaurant["categories"] if not c.get("isHidden")]
    item_count = sum(len(c["items"]) for c in visible)
    print(f"Wrote {JSON_PATH.relative_to(ROOT)}: {len(visible)} visible categories, {item_count} items")


if __name__ == "__main__":
    main()
