#!/usr/bin/env python3
"""Refresh CAVA's drinks station from the official nutrition guide.

Input is the text produced by:

    pdftotext -layout CAVA-guide.pdf cava-guide.txt

Pass that text file as the first argument. The script intentionally does not
download the guide: https://cava.com/nutrition is the authoritative place to
find the current PDF, and the caller should verify its date before importing.

Sizes come through as CAVA labels them (Kids 12 oz / Small 16 oz / Large 22 oz)
with the fluid ounces in the serving line, so a size is comparable across chains
even though "Small" isn't.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "Loadout/Resources/Menus/cava.json"
P = "cava"

if len(sys.argv) != 2:
    raise SystemExit("usage: build_cava_drinks.py <pdftotext-layout-output.txt>")

source_text = pathlib.Path(sys.argv[1]).expanduser().resolve()
if not source_text.is_file():
    raise SystemExit(f"nutrition text not found: {source_text}")

lines = source_text.read_text(encoding="utf-8").split("\n")
start = next(i for i, l in enumerate(lines) if l.strip() == "DRINKS*")
end = next(i for i, l in enumerate(lines) if l.strip() == "Allergen Guide")

# Rows are "Name  n n n n n n n n n n n". Long names wrap, and the wrap is not
# always clean: the Maine Root Diet Soda rows break as "Name -" / numbers /
# "Small (16 oz)", so the numbers land in the MIDDLE of the name. Handle both
# directions — stitch forward until eleven numbers appear, then, if the name was
# left dangling on a hyphen, pull the remainder off the following line.
NUMS = re.compile(r"^(.*?)\s+((?:-?[\d.]+\s+){10}-?[\d.]+)\s*$")
SIZE_FRAGMENT = re.compile(r"^(Kids|Small|Large)?\s*\(?\d+\s*oz\)?$", re.I)
HAS_SIZE = re.compile(r"\(\s*\d+\s*oz\s*\)", re.I)
body = [stripped for line in lines[start:end]
        if (stripped := line.strip())
        and not stripped.startswith(("DRINKS", "Cal.", "from Fat"))]
rows, buffer, i = [], "", 0
while i < len(body):
    candidate = f"{buffer} {body[i]}".strip() if buffer else body[i]
    m = NUMS.match(candidate)
    if not m:
        buffer = candidate
        i += 1
        continue
    name, vals = m.group(1).strip(), [float(x) for x in m.group(2).split()]
    # The name may still be incomplete: either it was cut at the hyphen
    # ("… (Fountain) -") or its size fell to the following line ("(22oz)").
    # Left unstitched, that orphan fragment glues itself onto the NEXT drink —
    # which is how "Spindrift Grapefruit" first came through as "22oz Spindrift".
    while i + 1 < len(body) and not NUMS.match(body[i + 1]) and (
        name.endswith("-") or (SIZE_FRAGMENT.match(body[i + 1]) and not HAS_SIZE.search(name))
    ):
        name = f"{name} {body[i + 1]}".strip()
        i += 1
    rows.append((name, vals))
    buffer = ""
    i += 1

SIZE = re.compile(r"^(.*?)\s*-\s*(Kids|Small|Large)\s*\((\d+)\s*oz\)\s*$", re.I)


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


groups, order = {}, []
for name, vals in rows:
    m = SIZE.match(name)
    base = m.group(1).strip() if m else name
    key = slug(base)
    if key not in groups:
        order.append(key)
        groups[key] = []
    groups[key].append((base, m.group(2).title() if m else None,
                        m.group(3) if m else None, vals))

MILK = {"chocolate-milk", "1-milk"}
items = []
for key in order:
    members = groups[key]
    sized = len(members) > 1
    for base, label, oz, vals in members:
        # cal, calFat, fat, sat, trans, chol, sodium, carb, fiber, sugar, protein
        items.append({
            "id": f"{P}.drinks.{key}" + (f".{label.lower()}" if sized else ""),
            "name": f"{base} ({label})" if sized else base,
            "servingDescription": f"{oz} fl oz" if oz else "1 serving",
            "macros": {"calories": vals[0], "proteinGrams": vals[10],
                       "carbGrams": vals[7], "fatGrams": vals[2]},
            **({"sizeGroup": f"{P}.drinks.{key}", "sizeLabel": label,
                # Small is the cup you get if you say nothing.
                "isDefaultSize": label == "Small"} if sized else {}),
            "allergens": ["milk"] if key in MILK else [],
            "notes": None,
            "iconName": None,
            "dietaryMarkers": [],
        })

menu = json.loads(OUT.read_text())
menu["categories"] = [c for c in menu["categories"] if c["id"] != "drinks"]
menu["categories"].append({
    "id": "drinks", "name": "Drinks", "selectionRule": {"kind": "selectMany"},
    "items": items, "iconName": None, "isCompleteMeal": False,
})
OUT.write_text(json.dumps(menu, indent=1) + "\n")

print(f"{len(rows)} drink rows -> {len(order)} groups/items, {len(items)} menu items")
for key in order:
    labels = [m[1] or "—" for m in groups[key]]
    print(f"  {key:34} {labels}")
