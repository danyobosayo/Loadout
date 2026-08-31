#!/usr/bin/env python3
"""Attach source-derived Starbucks recipe controls to bundled drinks.

Starbucks' official ordering API publishes which milk, espresso, preparation,
and flavor controls apply to each product and the standard recipe for every cup
size. It does *not* recalculate nutrition after a customization. This importer
therefore records the order controls and exact defaults, while the app continues
to display the official standard-recipe nutrition with an explicit notice.

The bundled menu remains the stable product whitelist. A live seasonal product
is never added implicitly; an unavailable bundled drink is reported for review.
Raw detail payloads may be cached on the external SSD so repeated audits are
fast and do not provoke Starbucks' edge rate limits.
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
MENU_URL = "https://www.starbucks.com/apiproxy/v1/ordering/menu"
DETAIL_URL = "https://www.starbucks.com/apiproxy/v1/ordering/{number}/{form}"
BEVERAGE_CATEGORIES = {"hot-coffee", "cold-coffee", "tea", "refreshers", "frappuccino"}
EXCLUDED_TREES = {"The Latest", "At Home Coffee", "Bottled Beverages"}

# Friendly bundled labels that intentionally differ from the live tree.
ALIASES = {
    "Pike Place Roast (Medium)": (480, "Hot"),
    "Sunsera Blonde Roast": (873068625, "Hot"),
    "Caffè Verona Dark Roast": (479, "Hot"),
    "Featured Dark Roast – Starbucks 1971 Roast": (479, "Hot"),
    "Decaf Pike Place Roast": (481, "Hot"),
    "Espresso (Doppio)": (410, "Hot"),
    "Iced Espresso (Doppio)": (410, "Iced"),
}

RENAMED_FAMILIES = {
    "Caffè Verona Dark Roast": "Featured Dark Roast – Starbucks 1971 Roast",
}

# These were present in the August 7 snapshot but are absent from the current
# national menu. The catalog refresh removes them separately; they must not make
# recipe generation fail first.
KNOWN_UNAVAILABLE = {
    "Blue Coconut Refresher",
    "Tropical Butterfly Refresher",
    "Blue Coconut Lemonade Refresher",
    "Butterfly Drink",
    "Ocean Drink",
}

GROUP_POLICY = {
    "Milk Foam": ("single", True),
    "Milk Options": ("single", False),
    "Milk Temperature": ("single", False),
    "Espresso Roast Options": ("single", False),
    "Ristretto or Long Shot": ("single", False),
    "Whipped Cream": ("single", True),
    "Espresso Shots": ("quantity", False),
    "Syrups": ("quantity", False),
    "Sauces": ("quantity", False),
    "Liquid Sweeteners": ("quantity", False),
    "Sweetener Packets": ("quantity", False),
}

GROUP_ORDER = [
    "Milk Options",
    "Espresso Shots",
    "Syrups",
    "Sauces",
    "Espresso Roast Options",
    "Ristretto or Long Shot",
    "Milk Foam",
    "Milk Temperature",
    "Whipped Cream",
    "Liquid Sweeteners",
    "Sweetener Packets",
]

POPULAR_CHOICE_ORDER = [
    "Vanilla Syrup",
    "Caramel Syrup",
    "Sugar-Free Vanilla Syrup",
    "Sugar-Free Caramel Syrup",
    "Brown Sugar Syrup",
    "Cinnamon Dolce Syrup",
]


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


def slug(value: object) -> str:
    plain = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", plain.lower()).strip("-")


def normalized_name(value: object) -> str:
    plain = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode()
    plain = plain.lower().replace("starbucks", "").replace("blended beverage", "")
    return re.sub(r"[^a-z0-9]+", " ", plain).strip()


def walk_menu(node: dict, ancestors: tuple[str, ...] = ()):
    path = ancestors + (node.get("name", ""),)
    for product in node.get("products") or []:
        yield path, product
    for child in node.get("children") or []:
        yield from walk_menu(child, path)


def live_products(tree: dict) -> tuple[dict[str, list[dict]], dict[tuple[int, str], dict]]:
    by_name: dict[str, list[dict]] = {}
    by_key: dict[tuple[int, str], dict] = {}
    for root in tree["menus"]:
        for path, product in walk_menu(root):
            if any(part in EXCLUDED_TREES for part in path):
                continue
            record = {
                "path": path,
                "name": product["name"],
                "number": int(product["productNumber"]),
                "form": product["formCode"],
            }
            key = (record["number"], record["form"])
            by_key[key] = record
            by_name.setdefault(normalized_name(record["name"]), []).append(record)
    return by_name, by_key


def menu_families(menu: dict):
    for category in menu["categories"]:
        if category["id"] not in BEVERAGE_CATEGORIES:
            continue
        families: dict[str, list[dict]] = {}
        for item in category["items"]:
            families.setdefault(item.get("sizeGroup") or item["id"], []).append(item)
        for family_id, items in families.items():
            default = next((item for item in items if item.get("isDefaultSize")), items[0])
            yield category, family_id, items, default


def choose_live(default: dict, by_name: dict[str, list[dict]], by_key: dict[tuple[int, str], dict]):
    bundled_name = default["name"]
    if default.get("sizeLabel"):
        bundled_name = re.sub(
            rf"\s*\({re.escape(default['sizeLabel'])}\)$", "", bundled_name
        )
    alias = ALIASES.get(bundled_name)
    if alias:
        return by_key.get(alias)
    candidates = list({
        (candidate["number"], candidate["form"]): candidate
        for candidate in by_name.get(normalized_name(bundled_name), [])
    }.values())
    if len(candidates) == 1:
        return candidates[0]
    if len(candidates) > 1:
        wants_iced = bundled_name.lower().startswith("iced ")
        narrowed = [candidate for candidate in candidates if (candidate["form"] == "Iced") == wants_iced]
        if len(narrowed) == 1:
            return narrowed[0]
    return None


def detail(number: int, form: str, cache_dir: Path | None, delay: float) -> dict:
    cache_path = cache_dir / f"{number}-{form.lower()}.json" if cache_dir else None
    if cache_path and cache_path.exists():
        payload = json.loads(cache_path.read_text())
    else:
        payload = fetch_json(DETAIL_URL.format(number=number, form=form.lower()))
        if cache_path:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_text(json.dumps(payload, ensure_ascii=False))
        if delay:
            time.sleep(delay)
    products = payload.get("products") or []
    if len(products) != 1:
        raise ValueError(f"{number}/{form}: expected one product, got {len(products)}")
    return products[0]


def leaf_option_groups(nodes: list[dict]):
    for node in nodes:
        products = node.get("products") or []
        if products:
            yield node["name"], products
        yield from leaf_option_groups(node.get("children") or [])


def choice_id(product_number: int, size_code: str) -> str:
    return f"starbucks.recipe.choice.{product_number}.{slug(size_code)}"


def clean_choice_name(group_name: str, value: str) -> str:
    if group_name == "Espresso Shots":
        return "Espresso Shot"
    value = re.sub(r"\s+Milk Base Option$", "", value)
    value = re.sub(r"\s+add$", "", value)
    return value


def choice_rows(group_name: str, products: list[dict], kind: str) -> list[dict]:
    output: list[dict] = []
    for product in products:
        number = int(product["productNumber"])
        form = product["form"]
        sizes = form.get("sizes") or []
        if kind == "quantity":
            add = next((size for size in sizes if size.get("sizeCode") == "add"), sizes[0] if sizes else None)
            if add:
                output.append({
                    "id": choice_id(number, add["sizeCode"]),
                    "name": clean_choice_name(group_name, form["name"]),
                    "maximumQuantity": 12,
                })
            continue
        for size in sizes:
            output.append({
                "id": choice_id(number, size["sizeCode"]),
                "name": clean_choice_name(group_name, size.get("name") or form["name"]),
                "maximumQuantity": None,
            })
    # Some option trees repeat a choice. Stable first occurrence wins.
    output = list({row["id"]: row for row in output}.values())
    if group_name == "Syrups":
        rank = {name: index for index, name in enumerate(POPULAR_CHOICE_ORDER)}
        output.sort(key=lambda row: (rank.get(row["name"], len(rank)), row["name"]))
    return output


def build_recipe(product: dict) -> dict | None:
    groups = []
    choice_to_group: dict[str, tuple[str, str]] = {}
    product_to_quantity_choice: dict[int, str] = {}

    for group_name, products in leaf_option_groups(product.get("productOptions") or []):
        policy = GROUP_POLICY.get(group_name)
        if policy is None:
            continue
        kind, allows_none = policy
        group_id = f"starbucks.recipe.group.{slug(group_name)}"
        choices = choice_rows(group_name, products, kind)
        if not choices:
            continue
        group = {
            "id": group_id,
            "name": group_name,
            "kind": kind,
            "choices": choices,
            "allowsNone": allows_none,
        }
        groups.append(group)
        for source in products:
            number = int(source["productNumber"])
            for size in source["form"].get("sizes") or []:
                cid = choice_id(number, size["sizeCode"])
                if any(choice["id"] == cid for choice in choices):
                    choice_to_group[cid] = (group_id, kind)
                    if kind == "quantity" and size["sizeCode"] == "add":
                        product_to_quantity_choice[number] = cid

    # Preserve the official editor's category order, but do not emit duplicate
    # groups if the upstream tree repeats one.
    groups = list({group["id"]: group for group in groups}.values())
    rank = {name: index for index, name in enumerate(GROUP_ORDER)}
    groups.sort(key=lambda group: (rank.get(group["name"], len(rank)), group["name"]))
    if not groups:
        return None

    defaults_by_size = {}
    for size in product.get("sizes") or []:
        selections: dict[str, str] = {}
        quantities: dict[str, int] = {}
        for entry in (size.get("recipe") or {}).get("default") or []:
            option = entry.get("productOption") or {}
            number = int(option.get("productNumber", -1))
            form = option.get("form") or {}
            size_code = entry.get("sizeCode")
            cid = choice_id(number, size_code) if size_code else None
            group_info = choice_to_group.get(cid) if cid else None
            if group_info is None and number in product_to_quantity_choice:
                cid = product_to_quantity_choice[number]
                group_info = choice_to_group.get(cid)
            if group_info is None or cid is None:
                continue
            group_id, kind = group_info
            if kind == "single":
                selections[group_id] = cid
            else:
                quantities[cid] = max(0, int(entry.get("quantity") or 0))
        defaults_by_size[size["name"]] = {
            "selections": selections,
            "quantities": quantities,
        }

    source_default = next(
        (size["name"] for size in product.get("sizes") or [] if size.get("default")),
        None,
    )
    if source_default is None and product.get("sizes"):
        source_default = product["sizes"][0]["name"]
    if source_default in defaults_by_size:
        defaults_by_size["default"] = defaults_by_size[source_default]

    return {
        "id": f"starbucks.recipe.{product['productNumber']}.{slug(product['formCode'])}",
        "groups": groups,
        "defaultsBySize": defaults_by_size,
    }


def nutrition_macros(size: dict) -> dict:
    nutrition = size.get("nutrition") or {}
    facts = {fact.get("id"): fact.get("value") for fact in nutrition.get("additionalFacts") or []}
    required = ("protein", "totalCarbs", "totalFat")
    if any(facts.get(key) is None for key in required):
        raise ValueError(f"{size.get('name')}: incomplete official macros")
    return {
        "calories": float((nutrition.get("calories") or {})["displayValue"]),
        "proteinGrams": float(facts["protein"]),
        "carbGrams": float(facts["totalCarbs"]),
        "fatGrams": float(facts["totalFat"]),
    }


def refresh_family(items: list[dict], product: dict, prior_name: str) -> None:
    sizes = product.get("sizes") or []
    by_label = {size["name"]: size for size in sizes}
    default_label = next(
        (item.get("sizeLabel") for item in items if item.get("isDefaultSize")),
        None,
    )
    if default_label is None:
        default_label = next((size["name"] for size in sizes if size.get("default")), None)
    if default_label is None and sizes:
        default_label = sizes[0]["name"]
    bundled_name = prior_name
    prior_label = next((item.get("sizeLabel") for item in items if item is not None), None)
    if prior_label:
        bundled_name = re.sub(rf"\s*\({re.escape(prior_label)}\)$", "", bundled_name)
    display_name = RENAMED_FAMILIES.get(bundled_name, bundled_name)

    for item in items:
        label = item.get("sizeLabel") or default_label
        source = by_label.get(label)
        if source is None:
            raise ValueError(f"{prior_name}: bundled size {label!r} is absent from the live detail")
        nutrition = source.get("nutrition") or {}
        serving = str((nutrition.get("servingSize") or {}).get("displayValue") or "").strip()
        item["macros"] = nutrition_macros(source)
        item["servingDescription"] = f"{label} ({serving})" if serving else label
        item["name"] = display_name if label == default_label else f"{display_name} ({label})"


def build(cache_dir: Path | None, delay: float) -> tuple[dict, list[str]]:
    menu = json.loads(OUT.read_text())
    tree = fetch_json(MENU_URL)
    by_name, by_key = live_products(tree)
    recipes: list[dict] = []
    unmatched: list[str] = []
    fetched: dict[tuple[int, str], dict] = {}

    for category, _, items, default in menu_families(menu):
        live = choose_live(default, by_name, by_key)
        if live is None:
            if default["name"] not in KNOWN_UNAVAILABLE:
                unmatched.append(f"{category['id']}/{default['name']}")
            for item in items:
                item.pop("recipeId", None)
            continue

        key = (live["number"], live["form"])
        if key not in fetched:
            fetched[key] = detail(*key, cache_dir=cache_dir, delay=delay)
            print(f"fetched {live['number']}/{live['form']} {live['name']}", flush=True)
        recipe = build_recipe(fetched[key])
        refresh_family(items, fetched[key], default["name"])
        if recipe is None:
            continue
        recipes.append(recipe)
        valid_sizes = set(recipe["defaultsBySize"])
        for item in items:
            if item.get("sizeLabel") in valid_sizes or item.get("sizeLabel") is None:
                item["recipeId"] = recipe["id"]

    if unmatched:
        raise ValueError("Unmatched bundled Starbucks drinks: " + "; ".join(unmatched))

    menu["orderingModel"] = "recipe"
    menu["drinkRecipes"] = recipes
    menu["dataSource"]["fetchedAt"] = "2026-08-31"
    item_count = sum(len(category["items"]) for category in menu["categories"])
    concept_count = sum(
        sum(item.get("isDefaultSize") is True or item.get("sizeGroup") is None for item in category["items"])
        for category in menu["categories"]
    )
    menu["dataSource"]["notes"] = (
        "CURRENT OFFICIAL SNAPSHOT. The national US category tree and every included "
        "beverage detail were re-fetched from Starbucks' first-party ordering API on "
        "2026-08-31. Food rows retain their exact August 7 first-party nutrition after "
        "their continued presence was checked in the current national tree. The bundled "
        "stable catalog contains "
        f"{concept_count} orderable concepts and {item_count} exact size/item rows. "
        "Every calorie, protein, carbohydrate, and fat value is copied from the "
        "matching official size-level nutrition record; no macro is inferred.\n\n"
        "CURATION. Durable coffee, espresso, tea, matcha, Refresher, Energy Refresher, "
        "Frappuccino, Protein beverage, and food families are included. Products "
        "confined to The Latest or Pumpkin Picks, At Home Coffee, generic bottled "
        "beverages, plain milk, and items absent from the current national menu are "
        "excluded. This follows Loadout's restaurant-drink policy: the restaurant "
        "menu carries distinctive prepared drinks, not ordinary packaged drinks or soda.\n\n"
        "SIZE AND RECIPE CONTROLS. One conceptual drink appears once with its exact "
        "official cup choices; Grande is the source default when offered, with official "
        "exceptions such as Short Cortado and Doppio espresso. Milk, preparation, "
        "espresso, shot, syrup, sauce, and sweetener controls are generated from each "
        "product's official ordering detail, including size-specific standard defaults. "
        "Starbucks' own ordering page continues to show standard-recipe nutrition after "
        "customization, so Loadout records the customized order and clearly retains the "
        "published standard macros rather than inventing modifier deltas."
    )
    return menu, [f"{len(recipes)} product recipes"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--delay", type=float, default=0.4)
    parser.add_argument("--cache-dir", type=Path)
    args = parser.parse_args()

    menu, report = build(args.cache_dir, args.delay)
    item_count = sum(len(category["items"]) for category in menu["categories"])
    recipe_items = sum(
        item.get("recipeId") is not None
        for category in menu["categories"]
        for item in category["items"]
    )
    print(f"{', '.join(report)}; {recipe_items}/{item_count} rows configurable")
    if args.write:
        OUT.write_text(json.dumps(menu, indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
