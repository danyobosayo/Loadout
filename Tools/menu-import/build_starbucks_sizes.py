#!/usr/bin/env python3
"""Collapse Starbucks' 427 rows into the ~100 drinks they actually are.

Every drink shipped as one row per size: "Caffè Latte", "Caffè Latte (Tall)",
"Caffè Latte (Venti)", "Caffè Latte (Short)". Two thirds of the scrolling was
Tall/Venti duplicates of something already on screen.

The `SizeGroup` machinery already existed and was already tested — the data just
never carried `sizeGroup`. This fills it in. It is purely a *display* change:
every size keeps its own id and its own macros, so a saved recipe still points at
the exact cup that was chosen.

The trap this script is mostly written around: **not every parenthetical is a
size.** "Pike Place Roast (Medium)" is a roast level, "(No Added Sugar)" is a
recipe variant. Only labels in the known size vocabulary are ever stripped.
"""
import json
import pathlib
import re

OUT = pathlib.Path("Loadout/Resources/Menus/starbucks.json")

# Cup sizes, then the espresso-shot sizes, which behave identically — one drink,
# several pours. Anything not in here is part of the drink's name.
CUP_SIZES = ["Short", "Tall", "Grande", "Venti", "Trenta", "Kids"]
SHOT_SIZES = ["Solo", "Doppio", "Triple", "Quad"]
SIZES = {s.lower(): s for s in CUP_SIZES + SHOT_SIZES}

# What you get if you say nothing, per family. Grande is Starbucks' default cup;
# Doppio is the standard two-shot espresso.
PREFERRED_DEFAULT = ["Grande", "Doppio", "Tall", "Short", "Solo"]

SERVING_RE = re.compile(r"^([A-Za-z]+)\s*\(")
SUFFIX_RE = re.compile(r"\s*\(([^)]+)\)\s*$")


def size_of(item):
    """The item's size label, or None when it isn't a sized drink at all.

    Read from `servingDescription` ("Grande (16 fl oz)"), which is the only
    field that reliably carries it — the Grande rows have no name suffix.
    """
    match = SERVING_RE.match(item["servingDescription"])
    if not match:
        return None
    return SIZES.get(match.group(1).lower())


def base_name(name, label):
    """The name with its size suffix removed — and nothing else removed."""
    match = SUFFIX_RE.search(name)
    if match and label and match.group(1).lower() == label.lower():
        return name[: match.start()].strip()
    return name.strip()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


menu = json.loads(OUT.read_text())
grouped = collapsed = 0

for category in menu["categories"]:
    families = {}
    for item in category["items"]:
        label = size_of(item)
        if not label:
            continue
        families.setdefault(slug(base_name(item["name"], label)), []).append((item, label))

    for key, members in families.items():
        # A family of one is just an item; dressing it as a picker adds a
        # control that can't be used.
        if len(members) < 2:
            continue
        labels = [label for _, label in members]
        default = next((d for d in PREFERRED_DEFAULT if d in labels), None)
        if default is None:
            # No familiar default in this family — fall back to the smallest cup
            # present, so a data oddity degrades to "smallest wins" rather than
            # to no selection at all.
            default = min(labels, key=lambda l: (CUP_SIZES + SHOT_SIZES).index(l))

        group_id = f"{menu['id']}.size.{category['id']}.{key}"
        for item, label in members:
            item["sizeGroup"] = group_id
            item["sizeLabel"] = label
            item["isDefaultSize"] = label == default
        grouped += 1
        collapsed += len(members)

OUT.write_text(json.dumps(menu, indent=1) + "\n")

total = sum(len(c["items"]) for c in menu["categories"])
rows = total - collapsed + grouped
print(f"{grouped} size groups covering {collapsed} items")
print(f"{total} items -> {rows} rows on screen")
