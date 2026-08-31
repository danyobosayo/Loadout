import Foundation
import Testing
@testable import Loadout

@MainActor
struct SizeGroupTests {
    private func item(
        _ id: String, _ name: String, kcal: Double,
        group: String? = nil, label: String? = nil, isDefault: Bool = false
    ) -> MenuItem {
        MenuItem(
            id: id, name: name, servingDescription: "1",
            macros: Macros(calories: kcal, proteinGrams: 0, carbGrams: 0, fatGrams: 0),
            sizeGroup: group, sizeLabel: label, isDefaultSize: isDefault
        )
    }

    private func category(_ items: [MenuItem]) -> MenuCategory {
        MenuCategory(id: "sides", name: "Sides", selectionRule: .selectMany, items: items)
    }

    @Test func ungroupedItemsStayOneRowEach() {
        let c = category([
            item("a", "Mac & Cheese", kcal: 450),
            item("b", "Kale Crunch", kcal: 170),
        ])
        let groups = c.sizeGroups()
        #expect(groups.count == 2)
        #expect(groups.allSatisfy { !$0.hasChoices })
        #expect(groups.map(\.displayName) == ["Mac & Cheese", "Kale Crunch"])
    }

    @Test func membersCollapseToOneRowWithTheDefaultSelected() {
        let c = category([
            item("s", "Waffle Potato Fries (small)", kcal: 320, group: "fries", label: "S"),
            item("m", "Waffle Potato Fries", kcal: 420, group: "fries", label: "M", isDefault: true),
            item("l", "Waffle Potato Fries (large)", kcal: 600, group: "fries", label: "L"),
        ])
        let groups = c.sizeGroups()
        #expect(groups.count == 1)
        let fries = try! #require(groups.first)
        #expect(fries.hasChoices)
        #expect(fries.members.count == 3)
        #expect(fries.defaultMember.id == "m")
        #expect(fries.member(labelled: "L")?.macros.calories == 600)
    }

    /// Each size keeps its own id, so a saved recipe still points at the exact
    /// size chosen — the collapse is display-only.
    @Test func eachSizeKeepsItsOwnIdentityAndMacros() {
        let c = category([
            item("t", "Caffè Latte (Tall)", kcal: 150, group: "latte", label: "Tall"),
            item("g", "Caffè Latte", kcal: 190, group: "latte", label: "Grande", isDefault: true),
            item("v", "Caffè Latte (Venti)", kcal: 250, group: "latte", label: "Venti"),
        ])
        let latte = try! #require(c.sizeGroups().first)
        #expect(Set(latte.members.map(\.id)) == ["t", "g", "v"])
        #expect(latte.member(labelled: "Tall")?.macros.calories == 150)
        #expect(latte.member(labelled: "Venti")?.macros.calories == 250)
    }

    @Test func displayNameStripsTheSizeSuffix() {
        let c = category([
            item("s", "Waffle Potato Fries (small)", kcal: 320, group: "f", label: "S"),
            item("l", "Waffle Potato Fries (large)", kcal: 600, group: "f", label: "L", isDefault: true),
        ])
        #expect(c.sizeGroups().first?.displayName == "Waffle Potato Fries")
    }

    /// Curation slip: no member marked default. Degrade to the first rather than
    /// rendering an empty row.
    @Test func aGroupWithNoDefaultFallsBackToTheFirstMember() {
        let c = category([
            item("a", "Fries (5 oz)", kcal: 269, group: "f", label: "5 oz"),
            item("b", "Fries (6 oz)", kcal: 323, group: "f", label: "6 oz"),
        ])
        #expect(c.sizeGroups().first?.defaultMember.id == "a")
    }

    @Test func chipsReadSmallestFirstWhateverOrderCurationWroteThem() {
        let c = category([
            item("m", "Fries (medium)", kcal: 420, group: "f", label: "M", isDefault: true),
            item("s", "Fries (small)", kcal: 320, group: "f", label: "S"),
            item("l", "Fries (large)", kcal: 600, group: "f", label: "L"),
        ])
        #expect(c.sizeGroups().first?.members.map(\.sizeLabel) == ["S", "M", "L"])
    }

    /// A string sort puts "10 ct" before "2 ct". Counts must sort numerically.
    @Test func countLabelsSortNumericallyNotAlphabetically() {
        let c = category([
            item("a", "Strips (3 ct)", kcal: 310, group: "s", label: "3 ct", isDefault: true),
            item("b", "Strips (10 ct)", kcal: 1030, group: "s", label: "10 ct"),
            item("c", "Strips (2 ct)", kcal: 200, group: "s", label: "2 ct"),
            item("d", "Strips (4 ct)", kcal: 410, group: "s", label: "4 ct"),
        ])
        #expect(c.sizeGroups().first?.members.map(\.sizeLabel) == ["2 ct", "3 ct", "4 ct", "10 ct"])
    }

    /// Starbucks was the whole reason size groups exist: 427 rows that are really
    /// ~100 drinks, two thirds of the scrolling being Tall/Venti duplicates.
    @Test func starbucksCollapsesToAboutAHundredDrinks() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "starbucks")
        let rows = restaurant.categories.flatMap { $0.sizeGroups() }
        let items = restaurant.categories.flatMap(\.items)
        #expect(items.count > 400, "the underlying sizes must all still be there")
        #expect(rows.count < 200, "\(rows.count) rows is still a wall of duplicates")

        // A roast level is not a size — "(Medium)" must survive the collapse.
        let pike = try #require(rows.first { $0.displayName.hasPrefix("Pike Place Roast") })
        #expect(pike.displayName == "Pike Place Roast (Medium)")
        #expect(pike.defaultMember.sizeLabel == "Grande")
        #expect(pike.members.map(\.sizeLabel) == ["Short", "Tall", "Grande", "Venti"])
    }

    @Test func smoothieKingUsesPublishedCupSizesAndTwentyOunceDefault() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "smoothie-king")
        let getFit = try #require(restaurant.category(id: "get-fit"))
        let group = try #require(
            getFit.sizeGroups().first { $0.displayName == "Original High Protein Banana" }
        )

        #expect(group.members.map(\.sizeLabel) == ["20 oz", "32 oz", "44 oz"])
        #expect(group.defaultMember.sizeLabel == "20 oz")
        #expect(group.defaultMember.macros == Macros(
            calories: 330, proteinGrams: 27, carbGrams: 33, fatGrams: 12
        ))
        #expect(group.member(labelled: "44 oz")?.macros == Macros(
            calories: 660, proteinGrams: 54, carbGrams: 65, fatGrams: 25
        ))
    }

    @Test func namedTiersSortByLadderNotAlphabet() {
        #expect(SizeGroup.rank("Tall") < SizeGroup.rank("Grande"))
        #expect(SizeGroup.rank("Grande") < SizeGroup.rank("Venti"))
        #expect(SizeGroup.rank("Cup") < SizeGroup.rank("Bowl"))
        #expect(SizeGroup.rank("Solo") < SizeGroup.rank("Doppio"))
        #expect(SizeGroup.rank("Doppio") < SizeGroup.rank("Quad"))
        #expect(SizeGroup.rank("S") < SizeGroup.rank("M"))
        #expect(SizeGroup.rank("M") < SizeGroup.rank("L"))
    }

    /// Curated restaurant groups must have one real default and named choices.
    @Test(arguments: ["chipotle", "chick-fil-a", "starbucks", "raising-canes",
                      "cava", "panda-express", "panera", "jersey-mikes", "qdoba",
                      "smoothie-king"])
    func curatedRestaurantsHaveExactlyOneDefaultPerGroup(_ id: String) async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: id)
        for category in restaurant.categories {
            for group in category.sizeGroups() where group.hasChoices {
                let defaults = group.members.filter(\.isDefaultSize)
                #expect(defaults.count == 1,
                        "\(id)/\(group.displayName) has \(defaults.count) defaults")
                #expect(group.members.allSatisfy { $0.sizeLabel?.isEmpty == false },
                        "\(id)/\(group.displayName) has a member with no size label")
            }
        }
    }

    /// Moe's is ungrouped on purpose, not by omission. Its four rice rows mean
    /// four different things — "(burrito portion)" is what goes inside a burrito
    /// while "(cup)" and "(bowl)" are sides you order — so folding them into one
    /// picker would let someone choose "bowl" as the rice in their burrito.
    /// Collapsing exists to remove duplicates, not to hide distinctions.
    @Test func moesPortionsAreDistinctThingsNotSizes() async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: "moes")
        let rice = try #require(restaurant.category(id: "rice"))
        let seasoned = rice.items.filter { $0.name.hasPrefix("Seasoned Rice") }
        #expect(seasoned.count > 1, "Moe's should still carry its distinct rice portions")
        #expect(seasoned.allSatisfy { $0.sizeGroup == nil },
                "portions that mean different things must not collapse into a size picker")
    }

    /// The collapse is worth ~a third of every row in the app; if that number
    /// quietly drops, a menu has lost its grouping.
    @Test func collapsingRemovesHundredsOfDuplicateRows() async throws {
        var items = 0, rows = 0
        for restaurant in try await BundledMenuRepository().availableRestaurants() {
            for category in restaurant.orderableCategories {
                items += category.items.count
                rows += category.sizeGroups().count
            }
        }
        #expect(items - rows > 400, "only \(items - rows) duplicate rows collapsed")
    }

    @Test func groupsPreserveMenuOrder() {
        let c = category([
            item("x", "Coleslaw", kcal: 200),
            item("s", "Fries (small)", kcal: 320, group: "f", label: "S", isDefault: true),
            item("y", "Texas Toast", kcal: 150),
            item("l", "Fries (large)", kcal: 600, group: "f", label: "L"),
        ])
        // The group takes the position of its first member.
        #expect(c.sizeGroups().map(\.id) == ["x", "f", "y"])
    }

    /// Members sharing no prefix means bad data — keep the first name rather
    /// than showing a truncated fragment.
    @Test func unrelatedNamesFallBackRatherThanTruncating() {
        let members = [
            MenuItem(id: "a", name: "Soup", servingDescription: "1", macros: .zero, sizeGroup: "g", sizeLabel: "Cup"),
            MenuItem(id: "b", name: "Bread Bowl", servingDescription: "1", macros: .zero, sizeGroup: "g", sizeLabel: "Bowl"),
        ]
        #expect(SizeGroup.baseName(of: members) == "Soup")
    }

    /// Restaurants curation hasn't reached yet carry no size fields, so they must
    /// still read as one row per item — grouping is opt-in, never inferred.
    /// Moe's is not in this list any more: its *drinks* group by cup size, which
    /// is real duplication. The thing that must stay ungrouped there is narrower
    /// than "the whole menu" — see `moesPortionsAreDistinctThingsNotSizes`.
    /// Subway left this list when its named subs arrived — those group by
    /// 6-inch/Footlong, which is real duplication.
    @Test(arguments: ["sweetgreen", "mod-pizza", "halal-guys"])
    func uncuratedMenusStayUngrouped(_ id: String) async throws {
        let restaurant = try await BundledMenuRepository().loadRestaurant(id: id)
        for category in restaurant.categories {
            #expect(category.sizeGroups().count == category.items.count,
                    "\(id)/\(category.id) grouped without curation")
        }
    }

    /// …and the curated ones actually collapse. Chick-fil-A's nine groups take
    /// 16 rows down to 9; Chipotle's three take 7 down to 3.
    @Test func curatedMenusActuallyCollapse() async throws {
        let repository = BundledMenuRepository()
        // A floor, not an exact count. What this test is for is "these menus
        // collapse"; an equality check also encodes how much data happens to be
        // in them, so it broke every time a station was curated — which trains
        // you to edit the number rather than read the failure.
        for (id, atLeast) in [("chick-fil-a", 12), ("chipotle", 3), ("starbucks", 99),
                              ("panera", 8), ("jersey-mikes", 6), ("qdoba", 5),
                              ("smoothie-king", 100)] {
            let restaurant = try await repository.loadRestaurant(id: id)
            let grouped = restaurant.categories
                .flatMap { $0.sizeGroups() }
                .filter(\.hasChoices)
            #expect(grouped.count >= atLeast,
                    "\(id) has \(grouped.count) size groups, expected at least \(atLeast)")
        }
    }
}
