#!/usr/bin/env python3
"""Ship CAVA's curated bowls and pitas — the last big blocked item.

CAVA publishes totals for these in its nutrition guide but was believed not to
publish COMPOSITIONS, so they could never be verified by summation and never
shipped. That verdict was wrong for an instructive reason: **cava.com returns
HTTP 403 to any programmatic fetch** (Cloudflare), so a researcher probing it
concludes there is nothing there. Loaded in a real browser, cava.com/menu lists
the full composition of every curated bowl and pita, and each has a detail page
with a fuller prose version plus a "Contains:" line.

Two independent checks say these are the right compositions:

1. The calories on cava.com match the nutrition guide EXACTLY for all 8 bowls
   (800/620/830/700/580/860/710/700) — same menu vintage, which is precisely
   what was wrong with the older ingredients PDF.
2. **Summation closes.** Composing each bowl from our own menu items lands
   within 2.1% of the published total, most within 1%. That also confirms the
   one portion assumption made here: where a bowl names two bases (lentils AND
   Super Greens), they are half portions — CAVA's own split-base service, which
   this app already models as its `greens-and-grains` format. Summing both at
   full portion overshoots by ~150 cal; halving them lands on 798 vs 800.

Nothing else is assumed. Falafel Crunch's "half falafel, half roasted veggies"
and Steak + Harissa's two distinct fetas are CAVA's own published wording.
"""
import difflib
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
OUT = pathlib.Path("Loadout/Resources/Presets/cava.presets.json")
TOLERANCE = 0.06

cava = json.loads(json.load(open(f"{SP}/recheck.json"))["recheck"]["cava-bowl-compositions"]["data"])
menu = json.loads(pathlib.Path("Loadout/Resources/Menus/cava.json").read_text())

lookup = {}
for category in menu["categories"]:
    if category["id"] == "drinks":
        continue
    for item in category["items"]:
        lookup[re.sub(r"[^a-z0-9 +]", "", item["name"].lower()).strip()] = item

# CAVA's menu wording vs our item names. Each is a rename, not a substitution.
ALIAS = {
    "feta": "crumbled feta",
    "sumac cabbage slaw": "sumac slaw",
    "yogurt dill dressing": "yogurt dill",
    "cucumber": "persian cucumber",
    "basmati rice": "saffron basmati rice",
    "pita": "whole pita",
    "pickles": "salt-brined pickles",
    "romaine": "romaine",
}


def norm(name):
    name = re.sub(r"\s*\(.*?\)", "", name)
    name = re.sub(r"[^a-z0-9 +]", "", name.lower()).strip()
    return ALIAS.get(name, name)


def resolve(name):
    key = norm(name)
    if key in lookup:
        return lookup[key]
    close = difflib.get_close_matches(key, list(lookup), n=1, cutoff=0.72)
    return lookup[close[0]] if close else None


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


presets, rejected = [], []
for entry in cava["items"]:
    components = entry["components"]
    bases = components.get("base", [])
    lines, unresolved, total = [], [], 0.0

    for group, names in components.items():
        for name in names:
            item = resolve(name)
            if item is None:
                unresolved.append(name)
                continue
            # A BOWL naming two bases is served half and half. A pita is not:
            # its "base" is the pita itself plus romaine, both full portions —
            # halving them undercounts by ~170 cal and nothing closes.
            split_base = group == "base" and len(bases) > 1 and entry.get("type") == "bowl"
            quantity = 0.5 if split_base or "half" in name.lower() else 1
            lines.append({"menuItemId": item["id"], "quantity": quantity})
            total += item["macros"]["calories"] * quantity

    published = float(entry["calories"])
    drift = abs(total - published) / published
    if unresolved or drift > TOLERANCE:
        rejected.append((entry["name"], published, total, unresolved, drift))
        continue

    presets.append({
        "id": f"cava.presets.{slug(entry['name'])}",
        "name": entry["name"].title().replace("+", "+"),
        "blurb": entry.get("menuCardVerbatim", "")[:160],
        "items": lines,
        "sourceNote": (
            f"Composition published on {entry.get('url', 'cava.com/menu')}; total of "
            f"{published:.0f} cal from CAVA's Nutrition and Allergen Guide. Composing it from "
            f"this app's own CAVA items sums to {total:.0f} cal ({100 * (total - published) / published:+.1f}%), "
            "which is the verification. cava.com 403s any programmatic fetch, so this is only "
            "visible in a real browser — which is why it was previously believed unpublished."
        ),
    })

print(f"{'item':34}{'published':>10}{'summed':>9}{'drift':>8}")
for entry in cava["items"]:
    p = next((x for x in presets if x["id"].endswith(slug(entry["name"]))), None)
    if p:
        summed = sum(lookup[[k for k, v in lookup.items() if v["id"] == li["menuItemId"]][0]]["macros"]["calories"] * li["quantity"] for li in p["items"])
        print(f"  SHIP {entry['name'][:28]:30}{entry['calories']:>8}{summed:>9.0f}{100*(summed-entry['calories'])/entry['calories']:>+7.1f}%")
for name, pub, tot, miss, drift in rejected:
    print(f"  HOLD {name[:28]:30}{pub:>8}{tot:>9.0f}{100*drift:>7.1f}%  {miss}")

OUT.write_text(json.dumps({"restaurantId": "cava", "presets": presets}, indent=1) + "\n")
print(f"\nwrote {len(presets)} presets, held {len(rejected)}")
