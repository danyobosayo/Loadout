"""
Tools/menu-import/build_cava_csv.py

Source: CAVA Nutrition and Allergen Guide PDF, code CAVA-REC-GID-0326-AllergReg
        (workspace: ../../CAVA-REC-GID-0326-AllergReg.pdf — outside the repo)

Outputs: cava-source.csv with one row per nutritionally-distinct line item.

Schema: same as chipotle-source.csv plus the `icon` column (token from
MacroFactor's `Icon` vocabulary, used both for the in-app row icon and
the exported MacroFactor `icon` field).

CAVA portion-size convention:
    The PDF reports per-recipe macros without explicit gram/oz weights,
    unlike Chipotle's per-ounce table. Every item is therefore tagged
    `servingDescription = "1 portion"`; the dataSource.notes calls this
    out so a future revisit (or a user feedback discrepancy) can refresh
    weights from CAVA's website if they ever publish them.

Excluded from this CSV:
    - Curated Bowls / Curated Pitas: pre-built combos. Loadout's job is
      build-from-line-items; combos can be reconstructed from the parts.
    - Kids Meals: smaller portions of the same items (matches the
      Chipotle decision in build_chipotle_csv.py).
    - Drinks: per project_menu_scope_food_only memory — fast-food menus
      ship food only.
"""

import csv
from pathlib import Path

# Data — transcribed verbatim from CAVA Nutrition Guide tables
# Order: category, slug, name, serving, cal, p, c, f, fiber, sugar, sodium, notes, icon

ITEMS = [
    # Bases — bowl/pita foundation
    ("bases", "brown-rice",         "Brown Rice",          "1 portion", 310,  7, 48, 10, 5, 2,  770, "", "riceBrownBowl"),
    ("bases", "saffron-basmati",    "Saffron Basmati Rice","1 portion", 290,  5, 54,  7, 2, 1,  770, "", "riceWhiteBowl"),
    ("bases", "black-lentils",      "Black Lentils",       "1 portion", 270, 18, 37,  7,15, 3,  520, "", "lentils"),
    ("bases", "super-greens",       "Super Greens",        "1 portion",  35,  3,  6,  0.5, 4, 2,  35, "Salad base", "lettuce"),
    ("bases", "arugula",            "Arugula",             "1 portion",  20,  2,  3,  0.5, 1, 2,  25, "", "lettuce"),
    ("bases", "baby-spinach",       "Baby Spinach",        "1 portion",  20,  3,  3,  0,   2, 0,  70, "", "lettuce"),
    ("bases", "romaine",            "Romaine",             "1 portion",  20,  1,  4,  0,   3, 1,  10, "", "lettuce"),
    ("bases", "power-greens",       "Power Greens",        "1 portion",  30,  2,  4,  0,   2, 1,  35, "", "lettuce"),

    # Dips & spreads — scooped onto the base
    ("dips", "tzatziki",            "Tzatziki",            "1 portion",  30,  2,  1,  2.5, 0, 1,  60, "", "yogurt"),
    ("dips", "hummus",              "Hummus",              "1 portion",  50,  2,  4,  2.5, 2, 0,  90, "", "hummus"),
    ("dips", "roasted-eggplant",    "Roasted Eggplant",    "1 portion",  50,  0,  2,  5,   1, 0, 160, "", "eggplant"),
    ("dips", "crazy-feta",          "Crazy Feta",          "1 portion",  70,  4,  1,  6,   0, 0, 230, "", "cheeseSlice"),
    ("dips", "harissa",             "Harissa",             "1 portion",  70,  1,  5,  6,   1, 2, 250, "", "chiliPeppersRed"),
    ("dips", "red-pepper-hummus",   "Red Pepper Hummus",   "1 portion",  40,  2,  5,  1.5, 2, 1, 105, "", "hummus"),

    # Mains — proteins / hearty fillings
    ("mains", "braised-lamb",       "Braised Lamb",        "1 portion", 210, 24,  2, 12,   1, 0, 450, "", "meatballs"),
    ("mains", "grilled-chicken",    "Grilled Chicken",     "1 portion", 250, 28,  3, 13,   1, 0, 670, "", "chickenGrilled"),
    ("mains", "falafel",            "Falafel",             "1 portion", 350,  6, 24, 26,   5, 3, 810, "Vegan", "falafel"),
    ("mains", "grilled-steak",      "Grilled Steak",       "1 portion", 170, 23,  1,  9,   0, 0, 280, "", "steakBoneIn"),
    ("mains", "harissa-honey-chicken","Harissa Honey Chicken","1 portion", 260, 26,  7, 14, 2, 3, 670, "", "chicken"),
    ("mains", "roasted-vegetables", "Roasted Vegetables",  "1 portion", 100,  3, 14,  4.5, 5, 5, 600, "Vegan", "vegetables"),
    ("mains", "spicy-lamb-meatballs","Spicy Lamb Meatballs","1 portion", 300, 24,  3, 21,   1, 1, 680, "", "meatballs"),
    ("mains", "glazed-salmon",      "Glazed Salmon",       "1 portion", 320, 23,  5, 23,   0, 5, 630, "", "salmonFilet"),

    # Toppings — fresh add-ons
    ("toppings", "shredded-romaine","Shredded Romaine",    "1 portion",   5,  0,  1,  0,   0, 0,   0, "", "lettuce"),
    ("toppings", "pita-crisps",     "Pita Crisps",         "1 portion",  70,  1,  6, 11,   0, 0,  25, "", "breadPita"),
    ("toppings", "sumac-slaw",      "Sumac Slaw",          "1 portion",  30,  1,  3,  1.5, 1, 1, 170, "", "cabbage"),
    ("toppings", "tomato-onion",    "Tomato + Onion",      "1 portion",  20,  0,  2,  1.5, 0, 1, 125, "", "tomato"),
    ("toppings", "persian-cucumber","Persian Cucumber",    "1 portion",  15,  0,  1,  1,   0, 1, 110, "", "cucumber"),
    ("toppings", "tomato-cucumber", "Tomato + Cucumber",   "1 portion",   5,  0,  1,  0,   0, 1,   0, "", "tomato"),
    ("toppings", "kalamata-olives", "Kalamata Olives",     "1 portion",  35,  0,  2,  3,   2, 0, 360, "", "oliveBlack"),
    ("toppings", "fiery-broccoli",  "Fiery Broccoli",      "1 portion",  35,  1,  2,  2.5, 1, 1, 170, "", "broccoli"),
    ("toppings", "pickled-onions",  "Pickled Onions",      "1 portion",  20,  0,  5,  0,   0, 4,   0, "", "onion"),
    ("toppings", "salt-brined-pickles","Salt-Brined Pickles","1 portion",  5,  0,  0,  0,   0, 0, 180, "", "cucumber"),
    ("toppings", "crumbled-feta",   "Crumbled Feta",       "1 portion",  35,  3,  0,  2.5, 0, 1, 125, "", "cheeseSlice"),
    ("toppings", "fire-roasted-corn","Fire-Roasted Corn",  "1 portion",  45,  1,  5,  2.5, 1, 2, 105, "", "corn"),
    ("toppings", "avocado",         "Avocado",             "1 portion", 110,  1,  6, 10,   4, 0,   0, "", "avocado"),

    # Dressings — drizzle
    ("dressings", "balsamic-date",  "Balsamic Date Vinaigrette","1 portion", 60, 0, 7,  4,  1, 5, 250, "", "oil"),
    ("dressings", "yogurt-dill",    "Yogurt Dill",         "1 portion",  30,  2,  1,  2,   0, 0, 190, "", "yogurt"),
    ("dressings", "lemon-herb-tahini","Lemon Herb Tahini", "1 portion",  70,  2,  4,  6,   2, 0, 140, "", "oil"),
    ("dressings", "strawberry-sesame","Strawberry Sesame", "1 portion",  60,  1,  3,  5,   1, 2, 130, "", "strawberry"),
    ("dressings", "greek-vinaigrette","Greek Vinaigrette", "1 portion", 130,  0,  1, 14,   0, 0, 230, "", "oil"),
    ("dressings", "skhug",          "Skhug",               "1 portion",  80,  0,  1,  9,   0, 0, 150, "Spicy", "spicesGround"),
    ("dressings", "hot-harissa-vinaigrette","Hot Harissa Vinaigrette","1 portion", 70, 0, 1, 7, 0, 1, 270, "Spicy", "spicesGround"),
    ("dressings", "garlic-dressing","Garlic Dressing",     "1 portion", 180,  0,  0, 20,   0, 0,  90, "", "garlic"),

    # Sides — pita, chips, sweets
    ("sides", "whole-pita",         "Whole Pita",          "1 pita",    320, 13, 54,  6,   6, 3, 700, "", "breadPita"),
    ("sides", "side-pita",          "Side Pita",           "1 pita",     80,  3, 14,  1.5, 2, 1, 180, "", "breadPita"),
    ("sides", "pita-chips",         "Pita Chips",          "1 portion", 280, 10, 41,  8,   5, 2, 630, "", "chipsBaked"),
    ("sides", "sumac-pita-chips",   "Sumac Sour Cream + Onion Pita Chips","1 portion", 290, 10, 43, 9, 5, 3, 740, "", "chipsBakedSeasoned"),
    ("sides", "greyston-blondie",   "Greyston Chocolate Chip Blondie","1 piece", 140, 2, 22, 5, 0, 16, 10, "", "cakeSquareChocolate"),
    ("sides", "greyston-brownie",   "Greyston Brownie",    "1 piece",   150,  2, 17,  9,   1, 13, 10, "", "cakeSquareChocolate"),
    ("sides", "whisked-apricot-honey","Whisked! Apricot Honey","1 piece", 220, 3, 34, 9,   1, 19, 150, "DMV regional", "biscotti"),
    ("sides", "whisked-dark-chocolate","Whisked! Salted Dark Chocolate Oat Cookie","1 piece", 240, 4, 31, 13, 3, 17, 115, "", "biscotti"),
]

HEADERS = [
    "category", "id", "name", "servingDescription",
    "calories", "protein_g", "carbs_g", "fat_g",
    "fiber_g", "sugar_g", "sodium_mg", "notes", "icon",
]


def build_csv(output_path: Path) -> None:
    seen_ids: set[str] = set()
    rows: list[dict[str, object]] = []

    for category, slug, name, serving, cal, p, c, f, fiber, sugar, sodium, notes, icon in ITEMS:
        item_id = f"cava.{category}.{slug}"
        assert item_id not in seen_ids, f"Duplicate id: {item_id}"
        assert cal >= 0 and p >= 0 and c >= 0 and f >= 0, f"Negative macro on {item_id}"
        assert " " not in slug, f"Space in slug for {item_id}"
        seen_ids.add(item_id)

        rows.append({
            "category":           category,
            "id":                 item_id,
            "name":               name,
            "servingDescription": serving,
            "calories":           cal,
            "protein_g":          p,
            "carbs_g":            c,
            "fat_g":              f,
            "fiber_g":            fiber,
            "sugar_g":            sugar,
            "sodium_mg":          sodium,
            "notes":              notes,
            "icon":               icon,
        })

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    by_cat: dict[str, int] = {}
    for r in rows:
        by_cat[r["category"]] = by_cat.get(r["category"], 0) + 1
    print(f"Wrote {len(rows)} rows to {output_path}")
    for cat in sorted(by_cat):
        print(f"  {cat:12s} {by_cat[cat]:>3d}")


if __name__ == "__main__":
    out = Path(__file__).parent / "cava-source.csv"
    build_csv(out)
