import Foundation
import Testing
@testable import Loadout

/// Slice 5 helpers: the offered-items lookup, the short label for
/// summaries/nudges, and the unmet-required-prompt calculation the tray
/// nudge is built on.
struct OrderFormatHelperTests {
    private static let repository = BundledMenuRepository()

    private static func chipotle() async throws -> (Restaurant, [OrderFormat]) {
        async let r = repository.loadRestaurant(id: "chipotle")
        async let f = repository.loadFormats(restaurantId: "chipotle")
        return try await (r, f)
    }

    private static func format(_ formats: [OrderFormat], _ id: String) -> OrderFormat {
        formats.first { $0.id == id }!
    }

    // MARK: shortLabel

    @Test func shortLabelStripsCommonPrefixesAndSuffixes() {
        func label(_ copy: String) -> String {
            FormatPrompt(categoryId: "c", promptCopy: copy, choose: .selectOne).shortLabel
        }
        #expect(label("Choose your protein") == "Protein")
        #expect(label("Pick your grain half") == "Grain half")
        #expect(label("Add a warm grain (optional)") == "Warm grain")
        #expect(label("Add cheese") == "Cheese")
        #expect(label("Choose a dressing") == "Dressing")
    }

    // MARK: offeredItemIds

    @Test func offeredItemIdsUsesSubsetWhenPresent() async throws {
        let (restaurant, formats) = try await Self.chipotle()
        let tacos = Self.format(formats, "tacos")
        let shellPrompt = tacos.prompts.first { $0.categoryId == "tortilla" }!
        let offered = shellPrompt.offeredItemIds(in: restaurant)
        #expect(offered == ["chipotle.tortilla.flour-taco", "chipotle.tortilla.crispy-corn"])
    }

    @Test func offeredItemIdsFallsBackToWholeCategory() async throws {
        let (restaurant, formats) = try await Self.chipotle()
        let burrito = Self.format(formats, "burrito")
        let ricePrompt = burrito.prompts.first { $0.categoryId == "rice" }!
        let offered = ricePrompt.offeredItemIds(in: restaurant)
        let allRice = Set(restaurant.category(id: "rice")!.items.map(\.id))
        #expect(offered == allRice)
    }

    // MARK: unmetRequiredPrompts

    @Test func unmetRequiredFlagsMissingProteinOnly() async throws {
        let (restaurant, formats) = try await Self.chipotle()
        let burrito = Self.format(formats, "burrito")
        // Nothing chosen: protein is the only required prompt in a burrito
        // (rice and beans are optional).
        let unmet = burrito.unmetRequiredPrompts(selecting: [], in: restaurant)
        #expect(unmet.map(\.categoryId) == ["protein"])
    }

    @Test func unmetRequiredClearsOnceProteinChosen() async throws {
        let (restaurant, formats) = try await Self.chipotle()
        let burrito = Self.format(formats, "burrito")
        let unmet = burrito.unmetRequiredPrompts(
            selecting: ["chipotle.protein.chicken"], in: restaurant)
        #expect(unmet.isEmpty)
    }

    @Test func unmetRequiredIgnoresOptionalPrompts() async throws {
        let (restaurant, formats) = try await Self.chipotle()
        let burrito = Self.format(formats, "burrito")
        // Choosing only rice (optional) still leaves the required protein.
        let unmet = burrito.unmetRequiredPrompts(
            selecting: ["chipotle.rice.cilantro-lime-white"], in: restaurant)
        #expect(unmet.map(\.categoryId) == ["protein"])
    }
}
