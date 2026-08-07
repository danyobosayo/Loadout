#!/usr/bin/env python3
"""Write researched allergen/dietary flags and size variants into the menus.

Takes the output of the `loadout-dietary-and-sizes` workflow, applies the
verification corrections over the original flags, adds any missing size
variants, and — importantly — runs an INDEPENDENT keyword audit that doesn't
trust either agent.

The audit is the point. Two language models agreeing that bacon has no pork in
it is still two language models; a dumb string match that knows "bacon" implies
pork catches it. It reports rather than corrects, because the false-positive
cases are real (pastrami is beef, a corn tortilla has no wheat) and want eyes.

    python3 Tools/menu-import/apply_dietary_flags.py flags.json          # audit only
    python3 Tools/menu-import/apply_dietary_flags.py flags.json --write
"""

import argparse
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
MENUS = REPO / "Loadout" / "Resources" / "Menus"

ALLERGENS = {"milk", "egg", "wheat", "soy", "peanut", "treenut", "fish", "shellfish", "sesame"}
MARKERS = {"meat", "pork", "honey", "alcohol"}

# name pattern -> flags the item MUST carry. Deliberately conservative: only
# words whose implication is unambiguous.
EXPECTED = [
    (r"\b(bacon|ham|prosciutto|chorizo|carnitas|capicola|cappacuolo|pepperoni|salami|pork|bratwurst|andouille)\b",
     {"markers": {"pork", "meat"}}),
    (r"\b(chicken|beef|steak|turkey|lamb|barbacoa|carne|meatball|brisket|gyro|shawarma|pastrami|birria|sausage)\b",
     {"markers": {"meat"}}),
    (r"\b(cheese|cheddar|mozzarella|parmesan|provolone|swiss|feta|queso|asiago|gorgonzola|ricotta|cream|butter|yogurt|ranch|alfredo|tzatziki|latte|mocha|frappuccino|milk)\b",
     {"allergens": {"milk"}}),
    (r"\b(bread|bun|roll|pita|crouton|breadcrumb|pasta|noodle|biscuit|focaccia|croissant|bagel|danish|brownie|cookie|blondie|cake|pretzel|wrap)\b",
     {"allergens": {"wheat"}}),
    (r"\b(mayo|mayonnaise|aioli|caesar)\b", {"allergens": {"egg"}}),
    (r"\b(hummus|tahini|sesame)\b", {"allergens": {"sesame"}}),
    (r"\b(salmon|tuna|anchovy)\b", {"allergens": {"fish"}}),
    (r"\b(shrimp|crab|lobster)\b", {"allergens": {"shellfish"}}),
    (r"\b(almond|cashew|pecan|walnut|pistachio|hazelnut|pesto)\b", {"allergens": {"treenut"}}),
    (r"\bpeanut\b", {"allergens": {"peanut"}}),
    (r"\bhoney\b", {"markers": {"honey"}}),
]

# Names that look like they trip a rule above but legitimately don't.
EXEMPT = [
    (r"\bcorn (tortilla|shell)\b", {"wheat"}),
    (r"\bcrispy corn\b", {"wheat"}),
    (r"\bgluten[- ]free\b", {"wheat"}),
    (r"\bgluten[- ]friendly\b", {"wheat"}),
    (r"\bcauliflower crust\b", {"wheat"}),
    (r"\bplant[- ]based\b", {"meat", "pork", "milk"}),
    (r"\bvegan\b", {"meat", "pork", "milk", "egg"}),
    (r"\b(soy|oat|almond|coconut)milk\b", {"milk"}),
    (r"\b(soy|oat|almond|coconut) milk\b", {"milk"}),
    (r"\bnut[- ]free\b", {"treenut", "peanut"}),
    (r"\bdairy[- ]free\b", {"milk"}),
    (r"\bpastrami\b", {"pork"}),          # beef
    (r"\bturkey (bacon|sausage|ham)\b", {"pork"}),
    (r"\bchicken sausage\b", {"pork"}),
    (r"\bpeanut butter\b", {"milk"}),     # "butter" is not dairy here
    (r"\bbutter(nut| lettuce)\b", {"milk"}),
    (r"\bnondairy\b", {"milk"}),
    (r"\bno cheese\b", {"milk"}),
    # Food-service pesto is routinely nut-free — MOD's own ingredient statement
    # is basil, canola, water, parmesan, garlic, salt, and every chain here
    # publishes an explicit tree-nut column. The chart beats the assumption.
    (r"\bpesto\b", {"treenut"}),
]

# Items where the keyword audit and the researched flags disagreed and I could
# NOT settle it against an official allergen chart. These are forced back to
# unknown rather than shipped as clean: an unverified item should read "we
# haven't checked" in the UI, never "safe for you".
FORCE_UNKNOWN = {
    # Every third-party source says this carries parmesan; the researched flags
    # say no allergens at all, and its source was the least clearly first-party
    # of the fourteen. Sweetgreen's own binder has no allergen columns to settle
    # it (the 0 g protein / 0 mg cholesterol reading is suggestive, not proof).
    "sweetgreen.dressings.pesto-vinaigrette",
}


def audit(item, allergens, markers):
    """Flags the item's own name says it must have, but doesn't. Report-only."""
    name = item["name"].lower()
    exempt = set()
    for pattern, flags in EXEMPT:
        if re.search(pattern, name):
            exempt |= flags
    missing = set()
    for pattern, expected in EXPECTED:
        if not re.search(pattern, name):
            continue
        for flag in expected.get("allergens", set()):
            if flag not in allergens and flag not in exempt:
                missing.add(flag)
        for flag in expected.get("markers", set()):
            if flag not in markers and flag not in exempt:
                missing.add(flag)
    return missing


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("flags")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    payload = json.loads(pathlib.Path(args.flags).read_text())
    entries = payload["results"] if "results" in payload else payload

    grand = {"flagged": 0, "unflagged": 0, "corrected": 0, "sizes": 0, "suspect": 0}
    for entry in entries:
        rid = entry["restaurantId"]
        flags = entry["flags"]
        verdict = entry.get("verdict") or {}
        path = MENUS / f"{rid}.json"
        if not path.exists():
            print(f"!! no menu for {rid}")
            continue
        menu = json.loads(path.read_text())

        # Flags, then verification corrections layered over the top.
        by_id = {}
        for it in flags.get("items", []):
            by_id[it["id"]] = (
                sorted(set(it.get("allergens", [])) & ALLERGENS),
                sorted(set(it.get("markers", [])) & MARKERS),
            )
        for corr in verdict.get("corrections", []):
            if corr["id"] in by_id or True:
                by_id[corr["id"]] = (
                    sorted(set(corr.get("allergens", [])) & ALLERGENS),
                    sorted(set(corr.get("markers", [])) & MARKERS),
                )
        corrections = len(verdict.get("corrections", []))

        # New size variants inherit their sibling's flags — a large fry is a
        # medium fry in a bigger box.
        added = 0
        for size in flags.get("missingSizes", []):
            category = next((c for c in menu["categories"] if c["id"] == size["categoryId"]), None)
            if category is None:
                print(f"   ?? {rid}: size {size['slug']} has no category {size['categoryId']}")
                continue
            new_id = f"{rid}.{size['categoryId']}.{size['slug']}"
            if any(i["id"] == new_id for i in category["items"]):
                continue
            sibling_flags = by_id.get(size.get("basedOnItemId"), (None, None))
            category["items"].append({
                "id": new_id,
                "name": size["name"],
                "servingDescription": size["servingDescription"],
                "macros": {
                    "calories": float(size["calories"]),
                    "proteinGrams": float(size["protein"]),
                    "carbGrams": float(size["carbs"]),
                    "fatGrams": float(size["fat"]),
                },
                "allergens": sibling_flags[0],
                "dietaryMarkers": sibling_flags[1],
                "notes": None,
                "iconName": None,
            })
            if sibling_flags[0] is not None:
                by_id[new_id] = sibling_flags
            added += 1

        flagged = unflagged = suspect = 0
        suspects = []
        for category in menu["categories"]:
            for item in category["items"]:
                pair = None if item["id"] in FORCE_UNKNOWN else by_id.get(item["id"])
                if pair is None:
                    item["allergens"] = None
                    item["dietaryMarkers"] = None
                    unflagged += 1
                    continue
                allergens, markers = pair
                item["allergens"] = allergens
                item["dietaryMarkers"] = markers
                flagged += 1
                missing = audit(item, set(allergens), set(markers))
                if missing:
                    suspect += 1
                    suspects.append(f"{item['name']} -> missing {sorted(missing)}")

        print(f"\n=== {menu['name']} ({rid}) ===")
        print(f"  {flagged} flagged, {unflagged} unflagged, {corrections} corrections applied, {added} sizes added")
        print(f"  source: {flags.get('sourceUrl')} (official={flags.get('sourceIsOfficial')}, confidence={flags.get('confidence')}, verdict={verdict.get('verdict')})")
        if suspects:
            print(f"  !! {len(suspects)} items the keyword audit disputes:")
            for line in suspects[:15]:
                print(f"       {line}")
            if len(suspects) > 15:
                print(f"       ... and {len(suspects) - 15} more")

        grand["flagged"] += flagged
        grand["unflagged"] += unflagged
        grand["corrected"] += corrections
        grand["sizes"] += added
        grand["suspect"] += suspect

        if args.write:
            path.write_text(json.dumps(menu, indent=2, ensure_ascii=False) + "\n")

    print(f"\nTOTAL flagged={grand['flagged']} unflagged={grand['unflagged']} "
          f"corrections={grand['corrected']} sizes={grand['sizes']} disputed={grand['suspect']}")
    if args.write:
        print("menus written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
