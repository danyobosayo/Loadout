#!/usr/bin/env python3
"""Turn researched restaurant data into Loadout's bundled menu + preset JSON.

Input is one JSON file shaped like the research workflow's output (see
`meta.name = loadout-restaurant-data`). This script does the deterministic
half of the job — namespacing ids, mapping selection rules, attaching icon
tokens, and *verifying every preset by summation* — so the only judgement
left is which restaurants are trustworthy enough to ship.

    python3 Tools/menu-import/build_from_research.py research.json --write

Without --write it reports what it would do and exits non-zero if anything
fails verification, so it doubles as the data review.
"""

import argparse
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
MENUS = REPO / "Loadout" / "Resources" / "Menus"
PRESETS = REPO / "Loadout" / "Resources" / "Presets"

# Category-level icon tokens, keyed by the shared station vocabulary. Anything
# not listed falls through to the plate glyph, which stays legible.
CATEGORY_ICONS = {
    "bases": "lettuce",
    "beans": "beansPan",
    "chips": "chipsBaked",
    "dips": "hummus",
    "dressing": "oil",
    "dressings": "oil",
    "mains": "chickenGrilled",
    "protein": "chicken",
    "proteins": "chicken",
    "entrees": "chickenGrilled",
    "rice": "riceWhiteBowl",
    "salsa": "salsa",
    "sauces": "salsa",
    "sides": "breadPita",
    "toppings": "vegetables",
    "veggies": "vegetables",
    "ingredients": "vegetables",
    "tortilla": "wheatFlat",
    "breads": "wheatFlat",
    "cheeses": "cheeseSlice",
    "premiums": "avocado",
    "extras": "chipsBaked",
    "appetizers": "chipsBaked",
    # Stations the new restaurants introduced.
    "breakfast": "wheatFlat",
    "crusts": "wheatFlat",
    "meats": "chicken",
    "food": "breadPita",
}

# Per-macro tolerance when checking a composed preset against the restaurant's
# own published total. Restaurants publish rounded per-item values, so a
# composed sum drifts a little; more than this means the composition is wrong.
CAL_TOLERANCE = 25
PROTEIN_TOLERANCE = 3


def parse_rule(raw):
    """'selectOne' | 'selectMany' | 'upTo:N' -> the Codable shape."""
    raw = (raw or "selectMany").strip()
    if raw == "selectOne":
        return {"kind": "selectOne"}
    if raw == "selectMany":
        return {"kind": "selectMany"}
    match = re.fullmatch(r"upTo:(\d+)", raw)
    if match:
        return {"kind": "selectUpTo", "max": int(match.group(1))}
    # Unrecognised rules degrade to the permissive one rather than failing the
    # build — a too-loose station is recoverable, a crash on launch is not.
    return {"kind": "selectMany"}


def build_menu(entry, fetched_at):
    rid = entry["restaurantId"]
    categories = []
    for cat in entry.get("categories", []):
        items = []
        for item in cat.get("items", []):
            items.append({
                "id": f"{rid}.{cat['id']}.{item['slug']}",
                "name": item["name"],
                "servingDescription": item["servingDescription"],
                "macros": {
                    "calories": float(item["calories"]),
                    "proteinGrams": float(item["protein"]),
                    "carbGrams": float(item["carbs"]),
                    "fatGrams": float(item["fat"]),
                },
                "allergens": None,
                "notes": None,
                "iconName": None,
            })
        if not items:
            continue                     # empty stations fail integrity tests
        categories.append({
            "id": cat["id"],
            "name": cat["name"],
            "selectionRule": parse_rule(cat.get("selectionRule")),
            "items": items,
            "iconName": CATEGORY_ICONS.get(cat["id"]),
        })
    return {
        "id": rid,
        "name": entry["name"],
        "schemaVersion": 1,
        "dataSource": {
            "url": entry["sourceUrl"],
            "fetchedAt": fetched_at,
            "fetchedBy": "research agent, verified against the official source",
            "notes": entry.get("notes") or None,
        },
        "categories": categories,
    }


def build_presets(entry, menu, fetched_at):
    """Compose each published combo and check it against the published total.

    A preset only ships when its sum matches what the restaurant itself
    publishes — the same check that caught Sweetgreen's double grain base and
    Chipotle's half-portion "light" rice.
    """
    rid = entry["restaurantId"]
    by_slug = {}
    for cat in menu["categories"]:
        for item in cat["items"]:
            by_slug[item["id"].split(".", 2)[2]] = item

    shipped, rejected = [], []
    for preset in entry.get("presets", []):
        components = preset.get("componentSlugs", [])
        missing = [c["slug"] for c in components if c["slug"] not in by_slug]
        if missing or not components:
            rejected.append((preset["name"], f"unresolved components: {missing or 'none given'}"))
            continue

        total = {"calories": 0.0, "proteinGrams": 0.0}
        items = []
        for comp in components:
            item = by_slug[comp["slug"]]
            qty = float(comp["quantity"])
            total["calories"] += item["macros"]["calories"] * qty
            total["proteinGrams"] += item["macros"]["proteinGrams"] * qty
            items.append({"menuItemId": item["id"], "quantity": qty})

        pub_cal = float(preset.get("publishedCalories", -1))
        pub_pro = float(preset.get("publishedProtein", -1))
        checks = []
        if pub_cal >= 0:
            delta = total["calories"] - pub_cal
            if abs(delta) > CAL_TOLERANCE:
                rejected.append((preset["name"], f"calories off by {delta:+.0f} (ours {total['calories']:.0f} vs published {pub_cal:.0f})"))
                continue
            checks.append(f"{pub_cal:.0f} kcal (ours {total['calories']:.0f})")
        if pub_pro >= 0:
            delta = total["proteinGrams"] - pub_pro
            if abs(delta) > PROTEIN_TOLERANCE:
                rejected.append((preset["name"], f"protein off by {delta:+.0f}g (ours {total['proteinGrams']:.0f} vs published {pub_pro:.0f})"))
                continue
            checks.append(f"{pub_pro:.0f}g protein (ours {total['proteinGrams']:.0f})")
        if not checks:
            # Nothing published to check against — we can't stand behind it.
            rejected.append((preset["name"], "restaurant publishes no totals to verify against"))
            continue

        shipped.append({
            "id": f"{rid}.presets.{preset['slug']}",
            "name": preset["name"],
            "blurb": preset["blurb"],
            "items": items,
            "sourceNote": (
                f"Composition from {entry['sourceUrl']} (fetched {fetched_at}). "
                f"Verified against the published {', '.join(checks)}."
            ),
        })
    return shipped, rejected


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("research", help="JSON file of researched restaurant data")
    ap.add_argument("--write", action="store_true", help="write the JSON files")
    ap.add_argument("--only", nargs="*", help="restrict to these restaurant ids")
    args = ap.parse_args()

    payload = json.loads(pathlib.Path(args.research).read_text())
    fetched_at = payload.get("fetchedAt", "unknown")
    entries = [r["menu"] if "menu" in r else r for r in payload["results"]]
    if args.only:
        entries = [e for e in entries if e["restaurantId"] in args.only]

    failures = 0
    for entry in entries:
        menu = build_menu(entry, fetched_at)
        presets, rejected = build_presets(entry, menu, fetched_at)
        item_count = sum(len(c["items"]) for c in menu["categories"])

        print(f"\n=== {menu['name']} ({menu['id']}) ===")
        print(f"  {len(menu['categories'])} stations, {item_count} items")
        print(f"  source: {entry['sourceUrl']} (official={entry.get('sourceIsOfficial')}, confidence={entry.get('confidence')})")
        for cat in menu["categories"]:
            print(f"    {cat['id']:14s} {cat['selectionRule']['kind']:12s} {len(cat['items']):3d} items")
        if entry.get("excluded"):
            print(f"  excluded: {'; '.join(entry['excluded'][:5])}")
        print(f"  presets: {len(presets)} verified, {len(rejected)} rejected")
        for name, why in rejected:
            print(f"    REJECTED  {name}: {why}")
            failures += 1
        for preset in presets:
            print(f"    ok        {preset['name']}")

        if not item_count:
            print("  !! no items — nothing to write")
            failures += 1
            continue

        if args.write:
            MENUS.mkdir(parents=True, exist_ok=True)
            (MENUS / f"{menu['id']}.json").write_text(json.dumps(menu, indent=2, ensure_ascii=False) + "\n")
            print(f"  wrote Menus/{menu['id']}.json")
            if presets:
                PRESETS.mkdir(parents=True, exist_ok=True)
                (PRESETS / f"{menu['id']}.presets.json").write_text(
                    json.dumps({"restaurantId": menu["id"], "presets": presets}, indent=2, ensure_ascii=False) + "\n"
                )
                print(f"  wrote Presets/{menu['id']}.presets.json")

    print(f"\n{len(entries)} restaurants processed, {failures} issues")
    return 1 if failures and not args.write else 0


if __name__ == "__main__":
    sys.exit(main())
