import Foundation
import Testing
@testable import Loadout

struct MenuItemIconResolverTests {
    private static let neverHasAsset: @Sendable (String) -> Bool = { _ in false }
    private static func assetExists(_ names: Set<String>) -> @Sendable (String) -> Bool {
        { names.contains($0) }
    }

    @Test func nilNamesReturnUniversalFallback() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: nil,
            categoryIcon: nil,
            assetExists: Self.neverHasAsset
        )
        #expect(resolved == .systemSymbol(name: MenuItemIconResolver.universalFallbackSymbol))
    }

    @Test func unknownTokenWithoutAssetFallsBackToUniversal() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: "definitely-not-a-token",
            categoryIcon: nil,
            assetExists: Self.neverHasAsset
        )
        #expect(resolved == .systemSymbol(name: MenuItemIconResolver.universalFallbackSymbol))
    }

    @Test func knownTokenResolvesToMappedSFSymbol() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: "chicken",
            categoryIcon: nil,
            assetExists: Self.neverHasAsset
        )
        let expected = MenuItemIconResolver.sfSymbolByMacroFactorIcon["chicken"]!
        #expect(resolved == .systemSymbol(name: expected))
    }

    @Test func assetCatalogPreemptsSymbolFallback() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: "chicken",
            categoryIcon: nil,
            assetExists: Self.assetExists(["chicken"])
        )
        // If a custom symbol-set named "chicken" exists, we use it instead
        // of the SF Symbol mapping — that's how the second-pass custom art
        // upgrades the v1 SF-Symbol placeholders without data changes.
        #expect(resolved == .asset(name: "chicken"))
    }

    @Test func categoryFallbackUsedWhenItemTokenIsMissing() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: nil,
            categoryIcon: "salsa",
            assetExists: Self.neverHasAsset
        )
        let expected = MenuItemIconResolver.sfSymbolByMacroFactorIcon["salsa"]!
        #expect(resolved == .systemSymbol(name: expected))
    }

    @Test func itemTokenWinsOverCategoryFallback() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: "chicken",
            categoryIcon: "vegetables",
            assetExists: Self.neverHasAsset
        )
        let expected = MenuItemIconResolver.sfSymbolByMacroFactorIcon["chicken"]!
        #expect(resolved == .systemSymbol(name: expected))
    }

    @Test func unknownItemTokenFallsThroughToCategoryFallback() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: "no-such-token",
            categoryIcon: "salsa",
            assetExists: Self.neverHasAsset
        )
        let expected = MenuItemIconResolver.sfSymbolByMacroFactorIcon["salsa"]!
        #expect(resolved == .systemSymbol(name: expected))
    }

    @Test func categoryAssetUsedWhenItemHasNoTokenAndCategoryAssetExists() {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: nil,
            categoryIcon: "guacamole",
            assetExists: Self.assetExists(["guacamole"])
        )
        #expect(resolved == .asset(name: "guacamole"))
    }
}
