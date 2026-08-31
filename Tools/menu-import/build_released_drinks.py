#!/usr/bin/env python3
"""Release the last six drinks the dairy guard was holding.

Both gaps closed the same way the Panera one did — the data was in a different
document or endpoint than the one originally checked, not absent:

- **Panera's two kids' milks** are absent from the allergen guide but present on
  their own product pages, under different names: the guide calls it "Kids Organic
  Chocolate Milk", the page is "Horizon Reduced Fat Organic Chocolate Milk". Both
  carry a verbatim "Contains Milk".
- **Jersey Mike's four cream sodas** are covered by `/nutrition/{product}/{size}` —
  the *same* endpoint the macros came from. The endpoint checked earlier,
  `/nutrition/allergens`, is a different and genuinely empty lookup table. Each
  flavour row carries 11 allergen booleans (all 0), a `missing_allergen_info` flag
  set to 0, and an ingredient statement reading carbonated water, sugar, caramel
  colour — so `[]` here is affirmatively stated, not assumed.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
MENUS = pathlib.Path("Loadout/Resources/Menus")
work = json.loads(open(f"{SP}/drinks_workflow.json").read())["source"]

RELEASE = {
    "panera": {"names": ["Kids Organic Chocolate Milk", "Kids Organic White Milk"],
               "allergens": ["milk"],
               "note": "Allergens from Panera's own product page (listed there as "
                       "\"Horizon Reduced Fat Organic …\"), which states \"Contains Milk\"."},
    "jersey-mikes": {"names": None, "match": "agave vanilla cream",
                     "allergens": [],
                     "note": "Allergens from Jersey Mike's /nutrition/{product}/{size} endpoint, "
                             "which reports every allergen flag 0 with missing_allergen_info 0."},
}


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


for rid, spec in RELEASE.items():
    path = MENUS / f"{rid}.json"
    menu = json.loads(path.read_text())
    station = next(c for c in menu["categories"] if c["id"] == "drinks")
    have = {i["id"] for i in station["items"]}

    def wanted(name):
        if spec["names"] is not None:
            return name in spec["names"]
        return spec["match"] in name.lower()

    added = []
    for d in work[rid]["drinks"]:
        if not wanted(d["name"]):
            continue
        iid = f"{rid}.drinks.{slug(d['name'])}"
        if iid in have:
            continue
        have.add(iid)
        added.append({
            "id": iid,
            "name": re.sub(r"\s+", " ", d["name"]).strip(),
            "servingDescription": d.get("servingDescription") or "1 serving",
            "macros": {"calories": round(float(d["calories"]), 1),
                       "proteinGrams": round(float(d["proteinGrams"]), 1),
                       "carbGrams": round(float(d["carbGrams"]), 1),
                       "fatGrams": round(float(d["fatGrams"]), 1)},
            "allergens": spec["allergens"],
            "notes": spec["note"],
            "iconName": None,
            "dietaryMarkers": [],
        })
    station["items"].extend(added)
    path.write_text(json.dumps(menu, indent=1) + "\n")
    print(f"{rid}: released {len(added)}")
    for i in added:
        print(f"   {i['name'][:46]:48} {i['macros']['calories']:>5.0f} cal  {i['allergens']}")
