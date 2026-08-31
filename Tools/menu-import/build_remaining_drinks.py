#!/usr/bin/env python3
"""Add drinks to the seven remaining chains that publish them.

The data came from a research pass with an adversarial verification stage, and
the verifiers earned their keep: every correction below is one they found, not
one the original researcher volunteered. The recurring failure was identical
across chains — **fluid ounces and allergens were asserted where the source
states neither**, which are exactly the two fields where "not stated" silently
becomes "here is a value".

Corrections applied here, per chain:

- moes         invented "22 oz"/"32 oz" cups. The strings "oz"/"ounce" appear
               ZERO times in Moe's 3-page PDF, and the calorie ratio between
               sizes (1.89) contradicts a 32/22 cup (1.45). Volumes stripped;
               Moe's own Kids/Regular/Large labels kept. Macros verified exact.
- halal-guys   five 24 OZ rows carry macros byte-identical to their 16 OZ rows —
               a copy-paste defect at the source. Dropped. Also the source's
               column is weight-ounces (grams = oz x 28.35 across food AND
               drink), so "fl oz" was an upgrade the source never made.
- jersey-mikes "22 fl oz"/"32 fl oz" was inferred from JM's own image filenames,
               not published. Stripped. Dr. Pepper at Giant was missing and is
               restored from the same first-party endpoint.
- panera       macros verified exact (0 mismatches, column mapping proven
               independently), but the allergen column does not exist in the
               cited guide at all, so every allergen claim was unsourced.
- sweetgreen   publishes no serving size for beverages at all; the schema has no
               such field. Says so rather than inventing one.
- chipotle     shipped as returned; the researcher had already excluded 11 rows
               where calories were populated and every other macro was 0 —
               incomplete records, not published zeros.
- qdoba        shipped as returned; its fl oz ARE published ("Fountain Beverages
               (fl. oz)") and all 40 sampled rows verified exact.

**The dairy guard.** `allergens: []` in this codebase means "checked, contains
none" — not "unknown". For a fountain soda that is true whatever the source says.
For a latte it is dangerous. So any drink whose name suggests dairy, nuts or soy
is dropped unless the source states its allergens. Those are listed at the end.
"""
import json
import pathlib
import re

SP = "/private/tmp/claude-501/-Volumes-dayossd-Projects-Loadout/b31077f6-c988-4098-8195-245065d2415a/scratchpad"
MENUS = pathlib.Path("Loadout/Resources/Menus")
WORK = json.loads(open(f"{SP}/drinks_workflow.json").read())["source"]

# Names that imply an allergen the source has to have confirmed. A soda can ship
# with [] on common sense; a horchata cannot.
DAIRY_OR_NUT = re.compile(
    r"latte|cappuccino|macchiato|mocha|smoothie|shake|milk|cream|chai|horchata|"
    r"yogurt|frapp|almond|oat|soy|cold brew with|au lait|hot chocolate|cocoa",
    re.I,
)
SIZE_LADDER = ["Kid's", "Kids", "Small", "Regular", "Medium", "Large", "Giant"]


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def strip_volume(text):
    """Remove a volume claim the source never made, keeping the cup's name."""
    cleaned = re.sub(r",?\s*\d+(\.\d+)?\s*(fl\s*)?oz\b", "", text, flags=re.I)
    cleaned = re.sub(r"\s*\([^)]*\)", "", cleaned)
    return re.sub(r"\s+", " ", cleaned).strip(" ,") or "1 serving"


def fix(restaurant_id, drinks):
    """Apply the corrections the verification pass demanded."""
    out, dropped = [], []

    if restaurant_id == "halal-guys":
        # Drop the 24 OZ rows whose macros duplicate the 16 OZ rows exactly.
        by_macros = {}
        for d in drinks:
            key = (re.sub(r"\s*\(?\d+\s*oz.*", "", d["name"], flags=re.I).strip(),
                   d["calories"], d["carbGrams"])
            by_macros.setdefault(key, []).append(d)
        broken = {id(d) for group in by_macros.values() if len(group) > 1
                  for d in group if "24" in str(d.get("servingDescription", ""))}
        drinks = [d for d in drinks if id(d) not in broken]

    for d in drinks:
        d = dict(d)
        if restaurant_id in ("moes", "jersey-mikes"):
            d["servingDescription"] = strip_volume(d.get("servingDescription", ""))
        if restaurant_id == "halal-guys":
            # The source's column is weight-ounces, not fluid ounces.
            d["servingDescription"] = re.sub(
                r"(\d+(?:\.\d+)?)\s*fl\s*oz", r"\1 oz (by weight, as printed)",
                d.get("servingDescription", ""), flags=re.I)
        if restaurant_id == "panera":
            d["allergens"] = []          # the cited guide has no allergen column
        if restaurant_id == "sweetgreen":
            d["servingDescription"] = "1 serving (sweetgreen publishes no volume)"

        if DAIRY_OR_NUT.search(d["name"]) and not d.get("allergens"):
            dropped.append(d["name"])
            continue
        out.append(d)
    return out, dropped


def to_item(restaurant_id, d, seen):
    base = slug(d["name"])
    iid = f"{restaurant_id}.drinks.{base}"
    n = 2
    while iid in seen:
        iid = f"{restaurant_id}.drinks.{base}-{n}"
        n += 1
    seen.add(iid)
    item = {
        "id": iid,
        "name": re.sub(r"\s+", " ", d["name"]).strip(),
        "servingDescription": d.get("servingDescription") or "1 serving",
        "macros": {
            "calories": round(float(d["calories"]), 1),
            "proteinGrams": round(float(d["proteinGrams"]), 1),
            "carbGrams": round(float(d["carbGrams"]), 1),
            "fatGrams": round(float(d["fatGrams"]), 1),
        },
    }
    if d.get("sizeGroup") and d.get("sizeLabel"):
        item["sizeGroup"] = f"{restaurant_id}.size.drinks.{slug(d['sizeGroup'])}"
        item["sizeLabel"] = d["sizeLabel"]
        item["isDefaultSize"] = bool(d.get("isDefaultSize"))
    item["allergens"] = [a.lower() for a in (d.get("allergens") or [])]
    item["notes"] = None
    item["iconName"] = None
    item["dietaryMarkers"] = []
    return item


# Jersey Mike's Dr. Pepper at Giant, published but omitted from the submission.
EXTRA = {
    "jersey-mikes": [{
        "name": "Dr. Pepper - Giant", "servingDescription": "Giant fountain cup",
        "sizeGroup": "Dr. Pepper", "sizeLabel": "Giant", "isDefaultSize": False,
        "calories": 373.44, "proteinGrams": 0, "carbGrams": 104.0, "fatGrams": 0,
        "allergens": [],
    }],
}

report = {}
for restaurant_id, payload in WORK.items():
    drinks = payload.get("drinks") or []
    if not drinks:
        report[restaurant_id] = "not published"
        continue
    drinks = drinks + EXTRA.get(restaurant_id, [])
    drinks, dropped = fix(restaurant_id, drinks)

    seen, items = set(), []
    for d in drinks:
        items.append(to_item(restaurant_id, d, seen))

    # Exactly one default per size group, or the row renders with no selection.
    groups = {}
    for i in items:
        if i.get("sizeGroup"):
            groups.setdefault(i["sizeGroup"], []).append(i)
    for members in groups.values():
        if sum(1 for m in members if m.get("isDefaultSize")) == 1:
            continue
        for m in members:
            m["isDefaultSize"] = False
        pick = min(members, key=lambda m: (
            SIZE_LADDER.index(m["sizeLabel"]) if m["sizeLabel"] in SIZE_LADDER else 99,
            m["macros"]["calories"]))
        pick["isDefaultSize"] = True

    path = MENUS / f"{restaurant_id}.json"
    menu = json.loads(path.read_text())
    menu["categories"] = [c for c in menu["categories"] if c["id"] != "drinks"]
    hidden = [c for c in menu["categories"] if c.get("isHidden")]
    menu["categories"] = [c for c in menu["categories"] if not c.get("isHidden")]
    menu["categories"].append({
        "id": "drinks", "name": "Drinks", "selectionRule": {"kind": "selectMany"},
        "items": items, "iconName": None, "isCompleteMeal": False,
    })
    menu["categories"] += hidden
    path.write_text(json.dumps(menu, indent=1) + "\n")

    rows = len({i.get("sizeGroup") or i["id"] for i in items})
    report[restaurant_id] = f"{len(items)} items in {rows} rows"
    if dropped:
        report[restaurant_id] += f" · {len(dropped)} held back by the dairy guard"

print("DRINKS IMPORT")
for k in sorted(report):
    print(f"  {k:14} {report[k]}")

print("\nHeld back — name implies dairy/nut/soy but the source states no allergens:")
for restaurant_id, payload in WORK.items():
    _, dropped = fix(restaurant_id, payload.get("drinks") or [])
    for name in dropped:
        print(f"  {restaurant_id:14} {name}")
