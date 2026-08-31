#!/usr/bin/env python3
"""Build Smoothie King's stable smoothie menu from its first-party pages.

The national menu page supplies the current category/product index. Each
product page embeds a JSON nutrition record with the complete standard recipe
for every offered cup size. Limited-time pumpkin and watermelon products are
excluded under Loadout's durable flagship rule.

Only enhancer rows with four complete published macros are emitted as add-ons.
Ingredient removals and substitutions are deliberately not modeled: the live
calculator applies recipe- and size-specific deltas that cannot be recovered
reliably from the nominal ingredient record alone.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent
MENUS = ROOT / "Loadout" / "Resources" / "Menus"
FORMATS = ROOT / "Loadout" / "Resources" / "Formats"
BASE_URL = "https://www.smoothieking.com"
INDEX_URL = f"{BASE_URL}/menu/smoothies/"
NEXT_DATA = re.compile(
    r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',
    re.DOTALL,
)

SECTION_ORDER = [
    "get-fit",
    "feel-energized",
    "manage-weight",
    "be-well",
    "fruit-classics",
    "glp-1",
    "kids",
]
SEASONAL_TOKENS = ("pumpkin", "watermelon")
ALLERGEN_MAP = {
    "milk": "milk",
    "dairy": "milk",
    "egg": "egg",
    "eggs": "egg",
    "wheat": "wheat",
    "soy": "soy",
    "peanut": "peanut",
    "peanuts": "peanut",
    "almond": "treenut",
    "almonds": "treenut",
    "pecan": "treenut",
    "pecans": "treenut",
    "cashew": "treenut",
    "cashews": "treenut",
    "walnut": "treenut",
    "walnuts": "treenut",
    "coconut": "treenut",
    "tree nut": "treenut",
    "tree nuts": "treenut",
    "fish": "fish",
    "shellfish": "shellfish",
    "sesame": "sesame",
}


def fetch(url: str, attempts: int = 3) -> str:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 LoadoutMenuAudit/1.0"
            ),
            "Accept": "text/html,application/xhtml+xml",
        },
    )
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return response.read().decode("utf-8")
        except (urllib.error.URLError, TimeoutError):
            if attempt == attempts:
                raise
            time.sleep(attempt * 1.5)
    raise AssertionError("unreachable")


def page_props(document: str) -> dict:
    match = NEXT_DATA.search(document)
    if not match:
        raise ValueError("Page has no __NEXT_DATA__ payload")
    return json.loads(html.unescape(match.group(1)))["props"]["pageProps"]


def number(value: object, field: str) -> float:
    if value is None or value == "":
        raise ValueError(f"Missing {field}")
    return float(value)


def rounded(value: object, field: str) -> float:
    return round(number(value, field), 1)


def macro_value(value: object) -> float:
    # The product payload uses null for label-zero nutrients. The same page's
    # rendered Nutrition Facts panel explicitly displays those values as 0g.
    return 0.0 if value is None or value == "" else round(float(value), 1)


def slug_piece(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", "-", str(value).lower()).strip("-")


def allergens(raw: object) -> list[str]:
    if not raw:
        return []
    tokens = [token.strip().lower() for token in re.split(r"[,;/]", str(raw))]
    result: list[str] = []
    unknown: list[str] = []
    for token in tokens:
        if not token:
            continue
        mapped = ALLERGEN_MAP.get(token)
        if mapped is None:
            unknown.append(token)
        elif mapped not in result:
            result.append(mapped)
    if unknown:
        raise ValueError(f"Unknown Smoothie King allergens: {unknown}")
    return result


def macros(row: dict) -> dict:
    return {
        "calories": macro_value(row.get("calories")),
        "proteinGrams": macro_value(row.get("protein")),
        "carbGrams": macro_value(row.get("carbs")),
        "fatGrams": macro_value(row.get("fat")),
    }


def item_rows(section_slug: str, product: dict, detail: dict) -> list[dict]:
    nutrition_block = detail["nutritionInfoSmoothieEnhancer"]
    rows = nutrition_block.get("nutritionInfo") or []
    if not rows:
        raise ValueError(f"{product['slug']}: no nutrition rows")

    ingredients = (detail.get("productPageFields") or {}).get("ingredientsText") or ""
    product_allergens = allergens(nutrition_block.get("allergens"))
    markers = ["meat"] if "collagen" in ingredients.lower() else []
    group = f"smoothie-king.size.{product['slug']}"
    multiple_sizes = len(rows) > 1
    sizes = [int(number(row.get("servingSize"), "servingSize")) for row in rows]
    default_size = 20 if 20 in sizes else sizes[0]

    output = []
    for row, size in zip(rows, sizes):
        item = {
            "id": (
                f"smoothie-king.{section_slug}.{product['slug']}."
                f"{slug_piece(size)}-oz"
            ),
            "name": product["title"],
            "servingDescription": f"{size} fl oz — standard recipe",
            "macros": macros(row),
            "allergens": product_allergens,
            "notes": (
                f"Official standard recipe ingredients: {ingredients}. "
                "Removal and substitution deltas are not modeled."
            ),
            "iconName": None,
            "dietaryMarkers": markers,
        }
        if multiple_sizes:
            item.update({
                "sizeGroup": group,
                "sizeLabel": f"{size} oz",
                "isDefaultSize": size == default_size,
            })
        output.append(item)
    return output


def enhancer_items(groups: list[dict]) -> list[dict]:
    candidates = [entry for entry in groups if entry.get("slug") == "enhancers"]
    if not candidates:
        raise ValueError("Customizer payload has no Enhancers group")
    # The page currently carries a legacy ingredient-shaped enhancer group and
    # the current enhancer records. Prefer the group with actual `kind=enhancer`
    # rows instead of silently importing both copies.
    group = max(
        candidates,
        key=lambda entry: sum(
            item.get("kind") == "enhancer" for item in entry.get("items", [])
        ),
    )

    output = []
    for source in group.get("items", []):
        nutrition = source.get("nutrition") or {}
        if source.get("kind") != "enhancer" or not source.get("hasNutritionData"):
            continue
        if any(nutrition.get(key) is None for key in ("calories", "protein", "carbs", "fat")):
            continue
        output.append({
            "id": f"smoothie-king.enhancers.{source['slug']}",
            "name": source["title"],
            "servingDescription": "1 published enhancer serving",
            "macros": macros(nutrition),
            "allergens": allergens(nutrition.get("allergens")),
            "notes": "Separate add-on serving from Smoothie King's official nutrition customizer.",
            "iconName": None,
            "dietaryMarkers": ["meat"] if "collagen" in source["title"].lower() else [],
        })
    if not output:
        raise ValueError("No complete enhancer rows")
    return output


def build(delay: float) -> tuple[dict, dict, list[str]]:
    index = page_props(fetch(INDEX_URL))
    sections_by_slug = {section["slug"]: section for section in index["sections"]}
    missing_sections = set(SECTION_ORDER) - set(sections_by_slug)
    if missing_sections:
        raise ValueError(f"Missing Smoothie King sections: {sorted(missing_sections)}")

    categories = []
    excluded: list[str] = []
    customizer_groups: list[dict] | None = None

    for section_slug in SECTION_ORDER:
        section = sections_by_slug[section_slug]
        items = []
        for product in section["products"]:
            if any(token in product["slug"] for token in SEASONAL_TOKENS):
                excluded.append(product["slug"])
                continue
            url = f"{BASE_URL}/menu/smoothies/{section_slug}/{product['slug']}/"
            detail = page_props(fetch(url))
            smoothie = detail["smoothie"]
            if smoothie["slug"] != product["slug"]:
                raise ValueError(f"URL mismatch: expected {product['slug']}, got {smoothie['slug']}")
            items.extend(item_rows(section_slug, product, smoothie))
            if customizer_groups is None:
                customizer_groups = detail["customizerIngredientGroups"]
            print(f"fetched {section_slug}/{product['slug']}", flush=True)
            if delay:
                time.sleep(delay)

        categories.append({
            "id": section_slug,
            "name": section["title"],
            "selectionRule": {"kind": "selectOne"},
            "items": items,
            "iconName": "station.drop",
            "isCompleteMeal": True,
        })

    assert customizer_groups is not None
    categories.append({
        "id": "enhancers",
        "name": "Enhancers",
        "selectionRule": {"kind": "selectUpTo", "max": 8},
        "items": enhancer_items(customizer_groups),
        "iconName": "station.sparkle",
        "isCompleteMeal": False,
    })

    menu = {
        "id": "smoothie-king",
        "name": "Smoothie King",
        "schemaVersion": 1,
        "orderingModel": "recipe",
        "dataSource": {
            "url": INDEX_URL,
            "fetchedAt": date.today().isoformat(),
            "fetchedBy": "Tools/menu-import/build_smoothie_king.py",
            "notes": (
                "Every smoothie macro is a complete standard-recipe row embedded in "
                "Smoothie King's current first-party product page. Adult smoothies normally "
                "use 20/32/44 fl oz; High Protein Greek Yogurt Gut Health Pineapple Mango "
                "currently publishes 20/32/40 fl oz. Kids products use their published single "
                "size. The official nutrition FAQ identifies 20 oz as the standard "
                "nutrition basis, so it is Loadout's default even though the reviewed Dallas "
                "ordering site preselected 32 oz. Current pumpkin and watermelon campaigns "
                "are excluded as seasonal. Only enhancer servings with complete first-party "
                "macros are offered. Removals and substitutions are omitted because the live "
                "calculator applies product- and size-specific deltas that are not represented "
                "trustworthily by the nominal ingredient records."
            ),
        },
        "categories": categories,
    }

    formats = {
        "restaurantId": "smoothie-king",
        "formats": [
            {
                "id": section_slug,
                "name": sections_by_slug[section_slug]["title"],
                "blurb": sections_by_slug[section_slug]["description"],
                "autoAdd": [],
                "prompts": [{
                    "categoryId": section_slug,
                    "promptCopy": "Choose your smoothie",
                    "choose": "one",
                    "required": True,
                }],
                "optionalCategoryIds": [] if section_slug == "kids" else ["enhancers"],
            }
            for section_slug in SECTION_ORDER
        ],
    }
    return menu, formats, excluded


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--delay",
        type=float,
        default=0.15,
        help="polite delay between first-party product requests",
    )
    args = parser.parse_args()

    menu, formats, excluded = build(max(0, args.delay))
    menu_path = MENUS / "smoothie-king.json"
    formats_path = FORMATS / "smoothie-king.formats.json"
    menu_path.write_text(json.dumps(menu, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    formats_path.write_text(
        json.dumps(formats, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    smoothie_count = sum(
        len(category["items"])
        for category in menu["categories"]
        if category["id"] != "enhancers"
    )
    print(
        f"wrote {smoothie_count} smoothie size rows, "
        f"{len(menu['categories'][-1]['items'])} enhancers; "
        f"excluded {len(excluded)} seasonal products"
    )


if __name__ == "__main__":
    main()
