"""
Tools/menu-import/build_chipotle_csv.py

Source: Chipotle Nutrition PDF, codes OCT-2024-US-CK and OCT-2024-US-PPS
        (page 2 = Coca-Cola supplier, page 3 = Pepsi supplier;
         food items are identical between the two)

Outputs: chipotle-source.csv with one row per nutritionally-distinct item.

Schema (extends PROJECT.md §5 with fiber/sugar/sodium per stretch-goal note):
    category, id, name, servingDescription, calories,
    protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg, notes

Conventions:
    - id format:  chipotle.{category}.{slug}
    - "<1" values are encoded as 0.5
    - One row per nutritionally-distinct portion
    - Soft drinks tagged in notes with supplier (Coca-Cola or Pepsi)

Excluded from this CSV (decisions, see commit message):
    - Kids menu items (smaller portions; adult-market focus for v1)
    - "Veggie" combo (not a single line item in the table)
    - Beer + bottled drinks (no per-item macros published in this PDF)
    - Combo items (Chips & Queso, Chips & Guac) - composable from individual items
"""

import csv
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────
# Data — transcribed verbatim from PDF nutrition table
# Order: name, serving, cal, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg
# ─────────────────────────────────────────────────────────────────────

ITEMS = [
    # category, slug, name, serving, cal, p, c, f, fiber, sugar, sodium, notes

    # Tortillas (for burritos / tacos)
    ("tortilla", "flour-burrito",   "Flour Tortilla (burrito)", "1 tortilla", 320,  8, 50,  9,    3, 0,   600, ""),
    ("tortilla", "flour-taco",      "Flour Tortilla (taco)",    "1 tortilla",  80,  2, 13,  2.5,  0.5, 0, 160, ""),
    ("tortilla", "crispy-corn",     "Crispy Corn Tortilla",     "1 tortilla",  70,  1, 10,  3,    1, 0,   0,   ""),

    # Rice
    ("rice", "cilantro-lime-white", "Cilantro-Lime White Rice", "4 oz",       210,  4, 40,  4,    1, 0,   350, ""),
    ("rice", "cilantro-lime-brown", "Cilantro-Lime Brown Rice", "4 oz",       210,  4, 36,  6,    2, 0,   190, ""),

    # Beans
    ("beans", "black",              "Black Beans",              "4 oz",       130,  8, 22,  1.5,  7, 2,   210, ""),
    ("beans", "pinto",              "Pinto Beans",              "4 oz",       130,  8, 21,  1.5,  8, 1,   210, ""),

    # Proteins
    ("protein", "chicken",          "Chicken",                  "4 oz",       180, 32,  0,  7,    0, 0,   310, ""),
    ("protein", "steak",            "Steak",                    "4 oz",       150, 21,  1,  6,    1, 0,   330, ""),
    ("protein", "barbacoa",         "Barbacoa",                 "4 oz",       170, 24,  2,  7,    1, 0,   530, ""),
    ("protein", "carnitas",         "Carnitas",                 "4 oz",       210, 23,  0, 12,    0, 0,   450, ""),
    ("protein", "sofritas",         "Sofritas",                 "4 oz",       150,  8,  9, 10,    3, 5,   560, "Plant-based"),

    # Veggies / greens
    ("veggies", "fajita-vegetables","Fajita Vegetables",        "2 oz",        20,  1,  5,  0,    1, 2,   150, ""),
    ("veggies", "supergreens-mix",  "Supergreens Salad Mix",    "3 oz",        15,  1,  3,  0,    2, 1,   15,  "Salad base"),
    ("veggies", "romaine",          "Romaine Lettuce",          "1 oz",         5,  0,  1,  0,    1, 0,   0,   ""),

    # Salsas
    ("salsa", "fresh-tomato",       "Fresh Tomato Salsa",       "4 oz",        25,  0,  4,  0,    1, 1,   550, "Mild"),
    ("salsa", "roasted-corn",       "Roasted Chili-Corn Salsa", "4 oz",        80,  3, 16,  1.5,  3, 4,   330, "Medium"),
    ("salsa", "tomatillo-green",    "Tomatillo-Green Chili Salsa", "2 fl oz", 15,  0,  4,  0,    0, 2,   260, "Medium-hot"),
    ("salsa", "tomatillo-red",      "Tomatillo-Red Chili Salsa","2 fl oz",     30,  0,  4,  0,    1, 0,   500, "Hot"),

    # Toppings
    ("toppings", "cheese",          "Cheese",                   "1 oz",       110,  6,  1,  8,    0, 0,   190, ""),
    ("toppings", "sour-cream",      "Sour Cream",               "2 oz",       110,  2,  2,  9,    0, 2,   30,  ""),
    ("toppings", "guacamole",       "Guacamole",                "4 oz",       230,  2,  8, 22,    6, 1,   370, ""),
    ("toppings", "guacamole-large", "Guacamole (large side)",   "8 oz",       460,  4, 16, 44,   12, 2,   740, "Side portion"),
    ("toppings", "queso-entree",    "Queso Blanco (entrée)",    "2 oz",       120,  5,  4,  9,    0, 1,   250, "Bowl/burrito add-in"),
    ("toppings", "queso-side",      "Queso Blanco (side)",      "4 oz",       240, 10,  7, 18,    0, 2,   490, "Side portion"),
    ("toppings", "queso-large",     "Queso Blanco (large side)","8 oz",       480, 20, 14, 37,    0.5, 5, 980, "Large side"),

    # Dressing
    ("dressing", "chipotle-honey-vinaigrette", "Chipotle-Honey Vinaigrette", "2 fl oz", 220, 1, 18, 16, 1, 12, 850, "Salad dressing"),

    # Chips
    ("chips", "regular",            "Chips",                    "4 oz (regular)", 540, 7, 73, 25, 7, 1, 390, ""),
    ("chips", "large",              "Chips (large)",            "6 oz (large)",   810, 11, 110, 38, 11, 2, 590, ""),

    # Drinks — Coca-Cola supplier (CK)
    ("drinks", "barqs-root-beer-22",     "Barq's Root Beer (22 oz)",       "22 fl oz", 280, 0, 85, 0, 0, 85, 130, "Coca-Cola supplier"),
    ("drinks", "barqs-root-beer-32",     "Barq's Root Beer (32 oz)",       "32 fl oz", 430, 0, 120, 0, 0, 120, 180, "Coca-Cola supplier"),
    ("drinks", "coca-cola-22",           "Coca-Cola Classic (22 oz)",      "22 fl oz", 260, 0, 70, 0, 0, 70, 85,  "Coca-Cola supplier"),
    ("drinks", "coca-cola-32",           "Coca-Cola Classic (32 oz)",      "32 fl oz", 380, 0, 105, 0, 0, 105, 120, "Coca-Cola supplier"),
    ("drinks", "coca-cola-life-22",      "Coca-Cola Life (22 oz)",         "22 fl oz", 170, 0, 44, 0, 0, 44, 70,  "Coca-Cola supplier"),
    ("drinks", "coca-cola-life-32",      "Coca-Cola Life (32 oz)",         "32 fl oz", 250, 0, 64, 0, 0, 64, 105, "Coca-Cola supplier"),
    ("drinks", "coca-cola-zero-22",      "Coca-Cola Zero (22 oz)",         "22 fl oz", 0, 0, 0, 0, 0, 0, 75,    "Coca-Cola supplier; zero-cal"),
    ("drinks", "coca-cola-zero-32",      "Coca-Cola Zero (32 oz)",         "32 fl oz", 0, 0, 0, 0, 0, 0, 115,   "Coca-Cola supplier; zero-cal"),
    ("drinks", "diet-coke-22",           "Diet Coke (22 oz)",              "22 fl oz", 0, 0, 0, 0, 0, 0, 75,    "Coca-Cola supplier; zero-cal"),
    ("drinks", "diet-coke-32",           "Diet Coke (32 oz)",              "32 fl oz", 0, 0, 0, 0, 0, 0, 115,   "Coca-Cola supplier; zero-cal"),
    ("drinks", "diet-coke-cf-22",        "Diet Coke, Caffeine Free (22 oz)","22 fl oz",0, 0, 0, 0, 0, 0, 90,    "Coca-Cola supplier; zero-cal"),
    ("drinks", "diet-coke-cf-32",        "Diet Coke, Caffeine Free (32 oz)","32 fl oz",0, 0, 0.5, 0, 0, 0, 130, "Coca-Cola supplier; zero-cal"),
    ("drinks", "pibb-xtra-22",           "Pibb Xtra (22 oz)",              "22 fl oz", 260, 0, 70, 0, 0, 70, 75,  "Coca-Cola supplier"),
    ("drinks", "pibb-xtra-32",           "Pibb Xtra (32 oz)",              "32 fl oz", 380, 0, 105, 0, 0, 105, 115, "Coca-Cola supplier"),
    ("drinks", "sprite-22",              "Sprite (22 oz)",                 "22 fl oz", 260, 0, 70, 0, 0, 70, 120, "Coca-Cola supplier"),
    ("drinks", "sprite-32",              "Sprite (32 oz)",                 "32 fl oz", 380, 0, 105, 0, 0, 105, 180, "Coca-Cola supplier"),
    ("drinks", "fanta-orange-22",        "Fanta Orange (22 oz)",           "22 fl oz", 290, 0, 80, 0, 0, 80, 80,  "Coca-Cola supplier"),
    ("drinks", "fanta-orange-32",        "Fanta Orange (32 oz)",           "32 fl oz", 430, 0, 120, 0, 0, 120, 140, "Coca-Cola supplier"),
    ("drinks", "minute-maid-lemonade-22","Minute Maid Lemonade (22 oz)",   "22 fl oz", 280, 0, 75, 0, 0, 75, 95,  "Coca-Cola supplier"),
    ("drinks", "minute-maid-lemonade-32","Minute Maid Lemonade (32 oz)",   "32 fl oz", 400, 0, 110, 0, 0, 110, 140, "Coca-Cola supplier"),
    ("drinks", "powerade-mb-22",         "Powerade Mountain Berry Blast (22 oz)", "22 fl oz", 280, 0, 75, 0, 0, 75, 95, "Coca-Cola supplier"),
    ("drinks", "powerade-mb-32",         "Powerade Mountain Berry Blast (32 oz)", "32 fl oz", 400, 0, 110, 0, 0, 110, 140, "Coca-Cola supplier"),
    ("drinks", "mello-yello-22",         "Mello Yello (22 oz)",            "22 fl oz", 290, 0, 80, 0, 0, 100, 100, "Coca-Cola supplier"),
    ("drinks", "mello-yello-32",         "Mello Yello (32 oz)",            "32 fl oz", 420, 0, 116, 0, 0, 140, 140, "Coca-Cola supplier"),
    ("drinks", "blue-sky-lemonade-22",   "Blue Sky Lemonade (22 oz)",      "22 fl oz", 300, 0, 78, 0, 0, 74, 95,  "Coca-Cola supplier"),
    ("drinks", "blue-sky-lemonade-32",   "Blue Sky Lemonade (32 oz)",      "32 fl oz", 440, 0, 113, 0, 0, 108, 135, "Coca-Cola supplier"),
    ("drinks", "blue-sky-mango-22",      "Blue Sky Mango Orange (22 oz)",  "22 fl oz", 300, 0, 75, 0, 0, 74, 80,  "Coca-Cola supplier"),
    ("drinks", "blue-sky-mango-32",      "Blue Sky Mango Orange (32 oz)",  "32 fl oz", 430, 0, 109, 0, 0, 108, 120, "Coca-Cola supplier"),

    # Drinks — Pepsi supplier (PPS)
    ("drinks", "pepsi-22",               "Pepsi (22 oz)",                  "22 fl oz", 280, 0, 77, 0, 0, 77, 55,  "Pepsi supplier"),
    ("drinks", "pepsi-32",               "Pepsi (32 oz)",                  "32 fl oz", 400, 0, 112, 0, 0, 112, 80, "Pepsi supplier"),
    ("drinks", "diet-pepsi-22",          "Diet Pepsi (22 oz)",             "22 fl oz", 0, 0, 0, 0, 0, 0, 70,    "Pepsi supplier; zero-cal"),
    ("drinks", "diet-pepsi-32",          "Diet Pepsi (32 oz)",             "32 fl oz", 0, 0, 0, 0, 0, 0, 100,   "Pepsi supplier; zero-cal"),
    ("drinks", "mountain-dew-22",        "Mountain Dew (22 oz)",           "22 fl oz", 300, 0, 80, 0, 0, 80, 95,  "Pepsi supplier"),
    ("drinks", "mountain-dew-32",        "Mountain Dew (32 oz)",           "32 fl oz", 440, 0, 116, 0, 0, 116, 140, "Pepsi supplier"),
    ("drinks", "diet-mountain-dew-22",   "Diet Mountain Dew (22 oz)",      "22 fl oz", 0, 0, 0, 0, 0, 0, 110,   "Pepsi supplier; zero-cal"),
    ("drinks", "diet-mountain-dew-32",   "Diet Mountain Dew (32 oz)",      "32 fl oz", 0, 0, 0, 0, 0, 0, 160,   "Pepsi supplier; zero-cal"),
    ("drinks", "tropicana-lemonade-22",  "Tropicana Lemonade (22 oz)",     "22 fl oz", 280, 0, 74, 0, 0, 74, 290, "Pepsi supplier"),
    ("drinks", "tropicana-lemonade-32",  "Tropicana Lemonade (32 oz)",     "32 fl oz", 400, 0, 108, 0, 0, 108, 420, "Pepsi supplier"),
    ("drinks", "sierra-mist-22",         "Sierra Mist (22 oz)",            "22 fl oz", 280, 0, 74, 0, 0, 74, 55,  "Pepsi supplier"),
    ("drinks", "sierra-mist-32",         "Sierra Mist (32 oz)",            "32 fl oz", 400, 0, 108, 0, 0, 108, 80, "Pepsi supplier"),
    ("drinks", "mug-root-beer-22",       "Mug Root Beer (22 oz)",          "22 fl oz", 280, 0, 72, 0, 0, 72, 40,  "Pepsi supplier"),
    ("drinks", "mug-root-beer-32",       "Mug Root Beer (32 oz)",          "32 fl oz", 400, 0, 104, 0, 0, 104, 60, "Pepsi supplier"),
    ("drinks", "lipton-brisk-22",        "Lipton Raspberry Brisk Iced Tea (22 oz)", "22 fl oz", 220, 0, 58, 0, 0, 58, 70, "Pepsi supplier"),
    ("drinks", "lipton-brisk-32",        "Lipton Raspberry Brisk Iced Tea (32 oz)", "32 fl oz", 320, 0, 84, 0, 0, 84, 100, "Pepsi supplier"),
    ("drinks", "dr-pepper-22",           "Dr. Pepper (22 oz)",             "22 fl oz", 280, 0, 73, 0, 0, 70, 110, "Pepsi supplier"),
    ("drinks", "dr-pepper-32",           "Dr. Pepper (32 oz)",             "32 fl oz", 400, 0, 106, 0, 0, 102, 160, "Pepsi supplier"),
    ("drinks", "diet-dr-pepper-22",      "Diet Dr. Pepper (22 oz)",        "22 fl oz", 0, 0, 0, 0, 0, 0, 110,   "Pepsi supplier; zero-cal"),
    ("drinks", "diet-dr-pepper-32",      "Diet Dr. Pepper (32 oz)",        "32 fl oz", 0, 0, 0, 0, 0, 0, 160,   "Pepsi supplier; zero-cal"),
    ("drinks", "crush-orange-22",        "Crush Orange (22 oz)",           "22 fl oz", 300, 0, 79, 0, 0, 78, 130, "Pepsi supplier"),
    ("drinks", "crush-orange-32",        "Crush Orange (32 oz)",           "32 fl oz", 430, 0, 115, 0, 0, 114, 190, "Pepsi supplier"),
    ("drinks", "sobe-yumberry-22",       "SoBe Yumberry Pomegranate (22 oz)", "22 fl oz", 0, 0, 0, 0, 0, 0, 85,    "Pepsi supplier; zero-cal"),
    ("drinks", "sobe-yumberry-32",       "SoBe Yumberry Pomegranate (32 oz)", "32 fl oz", 0, 0, 0, 0, 0, 0, 120,   "Pepsi supplier; zero-cal"),

    # Drinks — common to both suppliers
    ("drinks", "maine-root-22",          "Maine Root Root Beer (22 oz)",   "22 fl oz", 170, 0, 62, 0, 0, 62, 45,  ""),
    ("drinks", "maine-root-32",          "Maine Root Root Beer (32 oz)",   "32 fl oz", 240, 0, 90, 0, 0, 90, 65,  ""),
    ("drinks", "chipotle-iced-tea-22",   "Chipotle Iced Tea (22 oz)",      "22 fl oz", 10, 0, 3, 0, 0, 0, 0,    "Unsweetened"),
    ("drinks", "chipotle-iced-tea-32",   "Chipotle Iced Tea (32 oz)",      "32 fl oz", 15, 0, 4, 0, 0, 0, 0,    "Unsweetened"),
    ("drinks", "chipotle-sweet-tea-22",  "Chipotle Sweet Iced Tea (22 oz)","22 fl oz", 150, 0, 45, 0, 0, 45, 0,  ""),
    ("drinks", "chipotle-sweet-tea-32",  "Chipotle Sweet Iced Tea (32 oz)","32 fl oz", 220, 0, 65, 0, 0, 65, 0,  ""),
    ("drinks", "tractor-berry-22",       "Tractor Berry Agua Fresca (22 oz)",  "22 fl oz", 200, 0, 50, 0, 0, 49, 10,  ""),
    ("drinks", "tractor-berry-32",       "Tractor Berry Agua Fresca (32 oz)",  "32 fl oz", 290, 0, 72, 0, 0, 72, 15,  ""),
    ("drinks", "tractor-watermelon-22",  "Tractor Watermelon Limeade (22 oz)", "22 fl oz", 230, 0, 56, 0, 0, 50, 5,   ""),
    ("drinks", "tractor-watermelon-32",  "Tractor Watermelon Limeade (32 oz)", "32 fl oz", 330, 0, 82, 0, 0, 72, 10,  ""),
    ("drinks", "tractor-lemonade-22",    "Tractor Lemonade (22 oz)",       "22 fl oz", 170, 0, 43, 0, 0, 37, 10,  ""),
    ("drinks", "tractor-lemonade-32",    "Tractor Lemonade (32 oz)",       "32 fl oz", 250, 0, 62, 0, 0, 53, 15,  ""),
    ("drinks", "tractor-mandarin-22",    "Tractor Mandarin Agua Fresca (22 oz)", "22 fl oz", 190, 0, 47, 0, 0, 47, 0,   ""),
    ("drinks", "tractor-mandarin-32",    "Tractor Mandarin Agua Fresca (32 oz)", "32 fl oz", 280, 0, 69, 0, 0, 69, 5,   ""),
]

HEADERS = [
    "category", "id", "name", "servingDescription",
    "calories", "protein_g", "carbs_g", "fat_g",
    "fiber_g", "sugar_g", "sodium_mg", "notes",
]


def build_csv(output_path: Path) -> None:
    """Generate the CSV from the in-source data table.

    Validates basic invariants before writing so we fail loud, not silent.
    """
    seen_ids: set[str] = set()
    rows: list[dict[str, object]] = []

    for category, slug, name, serving, cal, p, c, f, fiber, sugar, sodium, notes in ITEMS:
        item_id = f"chipotle.{category}.{slug}"

        # Invariants — would rather crash than emit bad data.
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
        })

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    # Summary
    by_cat: dict[str, int] = {}
    for r in rows:
        by_cat[r["category"]] = by_cat.get(r["category"], 0) + 1
    print(f"Wrote {len(rows)} rows to {output_path}")
    for cat in sorted(by_cat):
        print(f"  {cat:12s} {by_cat[cat]:>3d}")


if __name__ == "__main__":
    out = Path(__file__).parent / "chipotle-source.csv"
    build_csv(out)
