#!/usr/bin/env python3
"""Apply the reviewed stable Starbucks flagship catalog policy.

This is deliberately narrower than mirroring every live product. Seasonal
promotions are volatile, while the official Protein and Energy Refresher
families are durable menu sections and materially useful for macro tracking.
Generic packaged drinks and plain milk are excluded under Loadout's shared
restaurant-drink policy.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import unicodedata
import urllib.error
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "Loadout" / "Resources" / "Menus" / "starbucks.json"
DETAIL_URL = "https://www.starbucks.com/apiproxy/v1/ordering/{number}/{form}"

REMOVE_NAMES = {
    # Retired specialty drinks from the prior national snapshot.
    "Blue Coconut Refresher",
    "Tropical Butterfly Refresher",
    "Blue Coconut Lemonade Refresher",
    "Butterfly Drink",
    "Ocean Drink",
    # No longer present in the official national food tree.
    "Truffle, Mushroom & Brie Egg Bites",
    "Cheese & Fruit Protein Box",
    "Eggs & Cheddar Protein Box",
    # Generic packaged beverages belong outside restaurant-specific menus.
    "Koia Cacao Bean Nutrition Shake",
    "Koia Vanilla Bean Nutrition Shake",
    "Horizon Organic Lowfat Milk",
    "Horizon Organic Lowfat Chocolate Milk",
    # Plain milk is not a Starbucks-specific beverage concept.
    "Cold Milk",
    "Steamed Milk",
}

# New durable first-party menu families. Products under The Latest / Pumpkin
# Picks remain excluded; those need a distinct seasonal refresh policy.
ADDITIONS = [
    ("cold-coffee", 40621, "Iced", []),
    ("tea", 28243, "Iced", ["milk"]),
    ("refreshers", 40992, "Iced", []),
    ("refreshers", 41000, "Iced", ["treenut"]),
    ("refreshers", 40495, "Iced", []),
    ("refreshers", 40993, "Iced", []),
    ("refreshers", 40494, "Iced", []),
    ("refreshers", 40497, "Iced", []),
    ("refreshers", 40772, "Iced", []),
    ("refreshers", 40498, "Iced", []),
    ("refreshers", 41001, "Iced", ["treenut"]),
    ("refreshers", 40496, "Iced", []),
    ("refreshers", 40499, "Iced", []),
    ("refreshers", 40771, "Iced", ["treenut"]),
    ("refreshers", 40500, "Iced", []),
    ("refreshers", 40997, "Iced", []),
    ("refreshers", 40502, "Iced", []),
    ("refreshers", 40501, "Iced", []),
]


def slug(value: object) -> str:
    plain = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", plain.lower()).strip("-")


def clean_name(value: str) -> str:
    return value.replace("®", "").replace("™", "").replace(" Blended Beverage", "").strip()


def fetch_json(url: str, attempts: int = 4) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 LoadoutMenuAudit/1.0"
            ),
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.load(response)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            if attempt == attempts:
                raise
            time.sleep(attempt * 2)
    raise AssertionError("unreachable")


def product_detail(number: int, form: str, cache_dir: Path | None) -> dict:
    cache_path = cache_dir / f"{number}-{form.lower()}.json" if cache_dir else None
    if cache_path and cache_path.exists():
        payload = json.loads(cache_path.read_text())
    else:
        payload = fetch_json(DETAIL_URL.format(number=number, form=form.lower()))
        if cache_path:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_text(json.dumps(payload, ensure_ascii=False))
    products = payload.get("products") or []
    if len(products) != 1:
        raise ValueError(f"{number}/{form}: expected one product, got {len(products)}")
    return products[0]


def macro_value(nutrition: dict, fact_id: str) -> float:
    facts = nutrition.get("additionalFacts") or []
    fact = next((row for row in facts if row.get("id") == fact_id), None)
    if fact is None or fact.get("value") is None:
        raise ValueError(f"Missing {fact_id}")
    return float(fact["value"])


def item_rows(category_id: str, product: dict, allergens: list[str]) -> list[dict]:
    name = clean_name(product["name"])
    base_slug = slug(name)
    sizes = product.get("sizes") or []
    if not sizes:
        raise ValueError(f"{name}: no sizes")
    default_size = next((size["name"] for size in sizes if size.get("default")), None)
    if default_size is None:
        default_size = "Grande" if any(size["name"] == "Grande" for size in sizes) else sizes[0]["name"]
    group_id = f"starbucks.size.{category_id}.{base_slug}"

    output = []
    for size in sizes:
        nutrition = size.get("nutrition") or {}
        serving = str((nutrition.get("servingSize") or {}).get("displayValue") or "").strip()
        label = size["name"]
        suffix = "" if label == default_size else f"-{slug(label)}"
        output.append({
            "id": f"starbucks.{category_id}.{base_slug}{suffix}",
            "name": name if label == default_size else f"{name} ({label})",
            "servingDescription": f"{label} ({serving})" if serving else label,
            "macros": {
                "calories": float((nutrition.get("calories") or {})["displayValue"]),
                "proteinGrams": macro_value(nutrition, "protein"),
                "carbGrams": macro_value(nutrition, "totalCarbs"),
                "fatGrams": macro_value(nutrition, "totalFat"),
            },
            "allergens": allergens,
            "notes": "Official standard recipe; Starbucks does not recalculate published nutrition after customization.",
            "iconName": None,
            "dietaryMarkers": [],
            "sizeGroup": group_id if len(sizes) > 1 else None,
            "sizeLabel": label if len(sizes) > 1 else None,
            "isDefaultSize": label == default_size if len(sizes) > 1 else False,
        })
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--cache-dir", type=Path)
    args = parser.parse_args()

    menu = json.loads(OUT.read_text())
    removed = []
    for category in menu["categories"]:
        kept = []
        for item in category["items"]:
            base = re.sub(r"\s*\([^)]*\)$", "", item["name"])
            if item["name"] in REMOVE_NAMES or base in REMOVE_NAMES:
                removed.append(item["id"])
            else:
                kept.append(item)
        category["items"] = kept

    existing_names = {
        re.sub(r"\s*\([^)]*\)$", "", item["name"])
        for category in menu["categories"]
        for item in category["items"]
    }
    added = []
    by_category = {category["id"]: category for category in menu["categories"]}
    for category_id, number, form, allergens in ADDITIONS:
        product = product_detail(number, form, args.cache_dir)
        name = clean_name(product["name"])
        if name in existing_names:
            continue
        rows = item_rows(category_id, product, allergens)
        by_category[category_id]["items"].extend(rows)
        existing_names.add(name)
        added.extend(row["id"] for row in rows)
        print(f"added {name}: {len(rows)} sizes", flush=True)

    print(f"removed {len(removed)} stale/generic rows; added {len(added)} current size rows")
    if args.write:
        OUT.write_text(json.dumps(menu, indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
