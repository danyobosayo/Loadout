#!/usr/bin/env python3
"""Add Subway's named subs — the thing you actually order there.

Subway shipped as components only: breads, proteins, cheeses, veggies, sauces.
You could build a sandwich but you could not pick an Italian B.M.T., which is how
essentially everyone orders at Subway.

Macros come from Subway's own "U.S. NUTRITION INFORMATION" PDF (January 2026),
linked from subway.com/en-us/menunutrition/nutrition. An independent verifier
reconstructed that table by coordinate rather than reading order — to rule out
column drift — and matched all 30 six-inch rows exactly, with Atwater deviating
at most 3.7%.

**Footlongs are Subway's own arithmetic, not ours.** The PDF tabulates per
6-inch and prints, directly under the table: "Double values for footlong
nutrition information (one footlong=two 6" servings)". So a footlong row is a
deterministic derivation from a published figure — the same class as subtracting
two published totals — and a customer following Subway's own instruction lands on
the identical number.

**Allergens and dietary markers ship as UNKNOWN, deliberately.** Subway publishes
allergens and ingredients per COMPONENT (Genoa Salami, Artisan Italian bread…),
never per sandwich, and the nutrition PDF states no build for the 33 standard
subs — not the bread, not whether cheese is on it, not which vegetables count. So
a sub's allergen set is not derivable from anything Subway publishes. `nil` means
"not checked" in this codebase and renders that way in the menu; `[]` would mean
"checked, contains none", which on a wheat-bearing, cheese-bearing sandwich would
be a dangerous lie.

That also means the research pass's own `containsMeat`/`containsPork` flags are
dropped here. The verifier caught them being wrong in both directions: B.M.T.
(Genoa salami, pepperoni, ham) carried neither flag, while Veggie Delite asserted
a hard `false` the source never states.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Menus/subway.json")
P = "subway"

NOTE = ("Subway publishes allergens and ingredients per component, never per "
        "sandwich, and states no build for this sub — so its allergens and "
        "meat content are not derivable from anything Subway publishes.")

items = json.loads(open(f"{SP}/subway_workflow.json").read())["source"]["subway"]["items"]


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


built, seen = [], set()
for raw in items:
    label = raw.get("sizeLabel") or ""
    group = raw.get("sizeGroup") or raw["name"]
    iid = f"{P}.subs.{slug(raw['name'])}.{slug(label) or 'one'}"
    if iid in seen:
        continue
    seen.add(iid)
    built.append({
        "id": iid,
        "name": raw["name"] if not label else f"{raw['name']} ({label})",
        # Trim the researcher's provenance prose out of the user-facing line;
        # it belongs in `notes` and in this file's docstring, not on a menu row.
        "servingDescription": re.sub(r";.*$", "", raw["servingDescription"]).strip(),
        "macros": {
            "calories": float(raw["calories"]),
            "proteinGrams": float(raw["proteinGrams"]),
            "carbGrams": float(raw["carbGrams"]),
            "fatGrams": float(raw["fatGrams"]),
        },
        "sizeGroup": f"{P}.size.subs.{slug(group)}",
        "sizeLabel": label,
        # 6-inch is what the nutrition table is built on and the smaller of the
        # two; Subway never states a menu default, so the smaller wins rather
        # than us inventing one.
        "isDefaultSize": label == "6-inch",
        "allergens": None,
        "notes": NOTE,
        "iconName": None,
        "dietaryMarkers": None,
    })

menu = json.loads(OUT.read_text())
menu["categories"] = [c for c in menu["categories"] if c["id"] != "subs"]
for c in menu["categories"]:
    c["isHeadline"] = False
# Subs lead: they are what someone came to order.
menu["categories"].insert(0, {
    "id": "subs", "name": "Subs", "selectionRule": {"kind": "selectMany"},
    "items": built, "iconName": None, "isCompleteMeal": True, "isHeadline": True,
})
OUT.write_text(json.dumps(menu, indent=1) + "\n")

groups = {i["sizeGroup"] for i in built}
print(f"{len(built)} sub rows in {len(groups)} groups")
print("total items:", sum(len(c['items']) for c in menu["categories"]))
for c in menu["categories"]:
    print(f"   [{c['id']:10}] {len(c['items']):>3}{'  HEADLINE' if c.get('isHeadline') else ''}")
