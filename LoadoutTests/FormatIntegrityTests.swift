import Foundation
import Testing
@testable import Loadout

/// Every format references the live menu by id. These tests are the guard
/// rail that keeps `*.formats.json` honest — a typo'd or stale id fails
/// here instead of silently dropping a seed/prompt at runtime.
struct FormatIntegrityTests {
    private static let repository = BundledMenuRepository()
    private static let restaurantIds = [
        "chipotle", "cava", "panda-express", "sweetgreen", "subway",
        "chick-fil-a", "starbucks", "panera", "qdoba", "moes",
        "jersey-mikes", "halal-guys", "mod-pizza", "raising-canes",
    ]

    private static func load(_ id: String) async throws -> (restaurant: Restaurant, formats: [OrderFormat]) {
        async let restaurant = repository.loadRestaurant(id: id)
        async let formats = repository.loadFormats(restaurantId: id)
        return try await (restaurant, formats)
    }

    /// Assembly restaurants need an entry point — "Burrito or bowl?" — because
    /// starting from an empty station list is a hard place to begin. Top-down
    /// restaurants don't: their combos ARE the entry point, and interposing a
    /// format picker in front of the Box Combo just adds a screen. So the rule
    /// is per ordering model, not universal.
    @Test func everyAssemblyRestaurantHasAtLeastOneFormat() async throws {
        for id in Self.restaurantIds {
            let restaurant = try await Self.repository.loadRestaurant(id: id)
            let formats = try await Self.repository.loadFormats(restaurantId: id)
            switch restaurant.orderingModel {
            case .assembly, .hybrid, .recipe:
                #expect(!formats.isEmpty, "\(id) assembles, so it needs a format to start from")
            case .configuration:
                #expect(formats.isEmpty,
                        "\(id) is ordered top-down; its combos are the entry point, not a format picker")
                #expect(
                    restaurant.orderableCategories.first?.items.contains { $0.isConfigurable } == true,
                    "\(id) should open on a station of configurable items"
                )
            }
        }
    }

    @Test func formatIdsAreUniqueWithinRestaurant() async throws {
        for id in Self.restaurantIds {
            let ids = try await Self.repository.loadFormats(restaurantId: id).map(\.id)
            #expect(Set(ids).count == ids.count, "duplicate format ids in \(id)")
        }
    }

    @Test func everyAutoAddResolves() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for seed in format.autoAdd {
                    #expect(restaurant.resolve(menuItemId: seed.menuItemId) != nil,
                            "\(id)/\(format.id): autoAdd \(seed.menuItemId) does not resolve")
                    #expect(seed.quantity > 0,
                            "\(id)/\(format.id): autoAdd \(seed.menuItemId) has non-positive quantity")
                }
            }
        }
    }

    @Test func everyPromptCategoryExists() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for prompt in format.prompts {
                    #expect(restaurant.category(id: prompt.categoryId) != nil,
                            "\(id)/\(format.id): prompt category '\(prompt.categoryId)' missing")
                }
            }
        }
    }

    @Test func everyOptionalCategoryExists() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for categoryId in format.optionalCategoryIds {
                    #expect(restaurant.category(id: categoryId) != nil,
                            "\(id)/\(format.id): optional category '\(categoryId)' missing")
                }
            }
        }
    }

    @Test func everySubsetItemExistsInItsCategory() async throws {
        for id in Self.restaurantIds {
            let (restaurant, formats) = try await Self.load(id)
            for format in formats {
                for prompt in format.prompts {
                    guard let subset = prompt.subsetItemIds else { continue }
                    #expect(!subset.isEmpty, "\(id)/\(format.id): empty subset on '\(prompt.categoryId)'")
                    let itemIds = Set(restaurant.category(id: prompt.categoryId)?.items.map(\.id) ?? [])
                    for itemId in subset {
                        #expect(itemIds.contains(itemId),
                                "\(id)/\(format.id): subset id '\(itemId)' not in category '\(prompt.categoryId)'")
                    }
                }
            }
        }
    }

    @Test func quantitiesArePositive() async throws {
        for id in Self.restaurantIds {
            let formats = try await Self.repository.loadFormats(restaurantId: id)
            for format in formats {
                #expect(format.portionMultiplier > 0,
                        "\(id)/\(format.id): portionMultiplier must be positive")
                for prompt in format.prompts {
                    #expect(prompt.quantityPerPick > 0,
                            "\(id)/\(format.id): quantityPerPick must be positive on '\(prompt.categoryId)'")
                }
            }
        }
    }

    @Test func missingFormatsFileReturnsEmpty() async throws {
        let formats = try await Self.repository.loadFormats(restaurantId: "no-such-place")
        #expect(formats.isEmpty)
    }

    /// CAVA's public builder is stricter than a generic assembly menu, and the
    /// downloadable guide changes independently. Pin the live rules and the
    /// current guide's non-seasonal deltas so a later refresh cannot silently
    /// restore retired drinks or the former two-dip/one-dressing limits.
    @Test func cavaMatchesCurrentOfficialGuideAndBuilder() async throws {
        let (restaurant, formats) = try await Self.load("cava")

        let dips = try #require(restaurant.category(id: "dips"))
        let dressings = try #require(restaurant.category(id: "dressings"))
        let drinks = try #require(restaurant.category(id: "drinks"))
        #expect(dips.selectionRule == .selectUpTo(3))
        #expect(dressings.selectionRule == .selectUpTo(2))
        #expect(drinks.items.count == 38)
        #expect(drinks.items.allSatisfy { !$0.id.contains("strawberry-citrus") })
        #expect(drinks.items.allSatisfy { !$0.id.contains("pineapple-apple-mint") })
        #expect(drinks.items.allSatisfy { !$0.id.contains("tangerine-aleppo") })

        let strawberrySmall = try #require(
            drinks.items.first { $0.id == "cava.drinks.strawberry-ginger.small" }
        )
        #expect(strawberrySmall.macros == Macros(
            calories: 150, proteinGrams: 0, carbGrams: 38, fatGrams: 0
        ))

        let sides = try #require(restaurant.category(id: "sides"))
        let harissaChips = try #require(
            sides.items.first { $0.id == "cava.sides.harissa-bbq-pita-chips" }
        )
        #expect(harissaChips.macros == Macros(
            calories: 280, proteinGrams: 10, carbGrams: 43, fatGrams: 10
        ))

        #expect(formats.allSatisfy { $0.optionalCategoryIds.contains("drinks") })
        let pita = try #require(formats.first { $0.id == "pita" })
        #expect(!pita.optionalCategoryIds.contains("bases"))
        #expect(pita.prompts.first { $0.categoryId == "dips" }?.choose == .selectUpTo(3))
    }

    /// Chipotle's public calculator and live order builder divide tacos by
    /// quantity, give a quesadilla three cheese portions and up to three
    /// included sides, and expose only its Tractor drinks as distinctive
    /// house beverages. Pin those rules so historical CSV rows cannot leak
    /// back into the app during a later data refresh.
    @Test func chipotleMatchesCurrentOfficialCalculatorAndBuilder() async throws {
        let (restaurant, formats) = try await Self.load("chipotle")

        #expect(Set(formats.map(\.id)) == [
            "bowl", "burrito", "tacos", "single-taco", "salad", "quesadilla",
            "cheese-quesadilla",
        ])
        #expect(formats.allSatisfy { $0.optionalCategoryIds.contains("drinks") })

        let drinks = try #require(restaurant.category(id: "drinks"))
        #expect(drinks.items.count == 8)
        #expect(Set(drinks.items.compactMap(\.sizeGroup)) == [
            "chipotle.size.drinks.tractor-organic-berry-agua-fresca",
            "chipotle.size.drinks.tractor-organic-mandarin-agua-fresca",
            "chipotle.size.drinks.tractor-organic-lemonade",
            "chipotle.size.drinks.tractor-organic-watermelon-limeade",
        ])
        #expect(drinks.items.allSatisfy { $0.name.contains("Tractor") })

        let prohibitedIds = [
            "chipotle.protein.carne-asada",
            "chipotle.protein.pollo-asado",
            "chipotle.salsa.cilantro-lime-sauce",
            "chipotle.chips.chili-lime",
        ]
        for itemId in prohibitedIds {
            #expect(restaurant.resolve(menuItemId: itemId) == nil)
        }

        let threeTacos = try #require(formats.first { $0.id == "tacos" })
        let threeShells = try #require(threeTacos.prompts.first { $0.categoryId == "tortilla" })
        #expect(threeShells.quantityPerPick == 3)
        #expect(threeTacos.prompts.first { $0.categoryId == "taco-toppings" }?.choose == .selectUpTo(5))

        let flour = try #require(
            restaurant.resolve(menuItemId: "chipotle.tortilla.flour-taco")?.item
        )
        let crispy = try #require(
            restaurant.resolve(menuItemId: "chipotle.tortilla.crispy-corn")?.item
        )
        #expect(abs(flour.macros.calories * threeShells.quantityPerPick - 250) < 0.001)
        #expect(abs(crispy.macros.calories * threeShells.quantityPerPick - 200) < 0.001)

        let singleTaco = try #require(formats.first { $0.id == "single-taco" })
        #expect(abs(singleTaco.portionMultiplier - (1.0 / 3.0)) < 0.000_001)
        #expect(singleTaco.prompts.first { $0.categoryId == "tortilla" }?.quantityPerPick == 3)

        let burrito = try #require(formats.first { $0.id == "burrito" })
        #expect(burrito.optionalCategoryIds.contains("burrito-options"))
        let doubleWrap = try #require(restaurant.category(id: "burrito-options"))
        #expect(doubleWrap.isHidden)
        #expect(doubleWrap.selectionRule == .selectUpTo(1))
        #expect(doubleWrap.items.first?.id == "chipotle.burrito-options.double-wrap")
        #expect(doubleWrap.items.first?.macros.calories == 320)

        let salad = try #require(formats.first { $0.id == "salad" })
        #expect(salad.autoAdd.contains {
            $0.menuItemId == "chipotle.dressing.chipotle-honey-vinaigrette" && $0.quantity == 1
        })

        let quesadilla = try #require(formats.first { $0.id == "quesadilla" })
        #expect(quesadilla.autoAdd.contains {
            $0.menuItemId == "chipotle.toppings.cheese" && $0.quantity == 3
        })
        #expect(quesadilla.prompts.first { $0.categoryId == "quesadilla-sides" }?.choose == .selectUpTo(3))

        let cheeseQuesadilla = try #require(formats.first { $0.id == "cheese-quesadilla" })
        #expect(!cheeseQuesadilla.prompts.contains { $0.categoryId == "protein" })
        #expect(cheeseQuesadilla.autoAdd.contains {
            $0.menuItemId == "chipotle.toppings.guacamole" && $0.quantity == 1
        })
        var cheeseBaseCalories = 0.0
        for seed in cheeseQuesadilla.autoAdd {
            let item = try #require(restaurant.resolve(menuItemId: seed.menuItemId)?.item)
            cheeseBaseCalories += item.macros.calories * seed.quantity
        }
        #expect(cheeseBaseCalories == 880)
    }

    /// Panda publishes standard serving macros separately from its live combo
    /// builder. Pin the verified combo counts, half-side math, current crafted
    /// drinks, and documented exclusions so a later refresh cannot restore the
    /// former wall of generic fountain drinks or a promotional entrée.
    @Test func pandaMatchesCurrentOfficialTableAndBuilder() async throws {
        let (restaurant, formats) = try await Self.load("panda-express")

        #expect(Set(formats.map(\.id)) == [
            "bowl", "plate", "bigger-plate", "a-la-carte",
        ])
        #expect(formats.allSatisfy { $0.optionalCategoryIds.contains("drinks") })

        let expectedEntreeCaps = [
            "bowl": SelectionRule.selectUpTo(1),
            "plate": SelectionRule.selectUpTo(2),
            "bigger-plate": SelectionRule.selectUpTo(3),
        ]
        for (formatId, cap) in expectedEntreeCaps {
            let format = try #require(formats.first { $0.id == formatId })
            #expect(format.prompts.first { $0.categoryId == "sides" }?.choose == .selectOne)
            #expect(format.prompts.first { $0.categoryId == "entrees" }?.choose == cap)
        }

        let aLaCarte = try #require(formats.first { $0.id == "a-la-carte" })
        #expect(aLaCarte.prompts.isEmpty)
        #expect(aLaCarte.optionalCategoryIds.prefix(2) == ["sides", "entrees"])

        let whiteRice = try #require(
            restaurant.resolve(menuItemId: "panda-express.sides.white-steamed-rice")?.item
        )
        let chowMein = try #require(
            restaurant.resolve(menuItemId: "panda-express.sides.chow-mein")?.item
        )
        #expect(whiteRice.macros.calories / 2 + chowMein.macros.calories / 2 == 560)

        let drinks = try #require(restaurant.category(id: "drinks"))
        #expect(Set(drinks.items.map(\.id)) == [
            "panda-express.drinks.peach-lychee-refresher",
            "panda-express.drinks.pomegranate-pineapple-lemonade",
            "panda-express.drinks.watermelon-mango-refresher",
        ])
        #expect(drinks.items.allSatisfy { $0.servingDescription == "24 fl oz" })
        #expect(drinks.items.allSatisfy { $0.sizeGroup == nil })

        for itemId in [
            "panda-express.entrees.hot-orange-chicken",
            "panda-express.drinks.mango-guava-tea",
            "panda-express.drinks.strawberry-dragonfruit-refresher",
            "panda-express.drinks.coca-cola.small",
        ] {
            #expect(restaurant.resolve(menuItemId: itemId) == nil)
        }

        let entreeGreens = try #require(
            restaurant.resolve(menuItemId: "panda-express.entrees.super-greens-entree")?.item
        )
        let sideGreens = try #require(
            restaurant.resolve(menuItemId: "panda-express.sides.super-greens")?.item
        )
        #expect(entreeGreens.macros == sideGreens.macros)
        #expect(entreeGreens.macros.calories == 130)
    }
}
