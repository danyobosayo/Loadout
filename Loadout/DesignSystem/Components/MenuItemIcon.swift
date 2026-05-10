import SwiftUI

/// Renders the icon for a `MenuItem` row. Looks up the name (a token from
/// MacroFactor's `Icon` vocabulary) in this order:
///
/// 1. Asset catalog — so a custom monochrome SVG/symbol set named e.g.
///    `chicken` overrides the SF Symbol fallback with zero data changes.
/// 2. SF Symbol fallback table — best-fit Apple-supplied symbol for the
///    food category. Sparse, but ships v1 without custom asset work.
/// 3. `fork.knife` as the universal last resort.
///
/// Pass `nil` to render the universal fallback. Pass the category-level
/// `iconName` as `categoryFallback` so item-less categories still render
/// something category-appropriate.
struct MenuItemIcon: View {
    let name: String?
    var categoryFallback: String? = nil
    var size: CGFloat = 22

    var body: some View {
        let resolved = MenuItemIconResolver.resolve(
            itemIcon: name,
            categoryIcon: categoryFallback
        )
        switch resolved {
        case .asset(let assetName):
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.appPrimaryText)
        case .systemSymbol(let symbolName):
            Image(systemName: symbolName)
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(.appPrimaryText)
                .frame(width: size, height: size)
        }
    }
}

nonisolated enum ResolvedMenuItemIcon: Equatable, Sendable {
    case asset(name: String)
    case systemSymbol(name: String)
}

// Resolver is `nonisolated` so tests can pass plain `(String) -> Bool`
// closures for `assetExists`. UIImage(named:) is nonisolated under
// Apple's iOS 18 sendability audit.
nonisolated enum MenuItemIconResolver {
    static let universalFallbackSymbol = "fork.knife"

    /// Order: item asset → item symbol fallback → category asset →
    /// category symbol fallback → universal fallback.
    /// `assetExists` is parameterized for tests; production calls use the
    /// real asset-catalog probe via `UIImage(named:)`.
    static func resolve(
        itemIcon: String?,
        categoryIcon: String?,
        assetExists: (String) -> Bool = defaultAssetExists
    ) -> ResolvedMenuItemIcon {
        for candidate in [itemIcon, categoryIcon].compactMap({ $0 }) {
            if assetExists(candidate) {
                return .asset(name: candidate)
            }
            if let symbol = sfSymbolByMacroFactorIcon[candidate] {
                return .systemSymbol(name: symbol)
            }
        }
        return .systemSymbol(name: universalFallbackSymbol)
    }

    private static func defaultAssetExists(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }

    /// Best-fit SF Symbols for the MacroFactor `Icon` tokens we currently
    /// use across bundled menus. SF Symbols' food coverage is sparse — most
    /// entries hit one of `fork.knife`, `leaf.fill`, `flame.fill`, or
    /// `drop.fill`. Custom symbol-set assets dropped into `Assets.xcassets`
    /// override these without touching this table.
    static let sfSymbolByMacroFactorIcon: [String: String] = [
        // Tortilla / wraps
        "wheatFlat": "circle",
        "breadPita": "circle",
        // Rice / grains
        "riceWhiteBowl": "leaf.fill",
        "riceBrownBowl": "leaf.fill",
        // Beans
        "beansPan": "leaf.fill",
        // Proteins
        "chicken": "fork.knife",
        "chickenGrilled": "fork.knife",
        "steakBoneIn": "fork.knife",
        "porkLoin": "fork.knife",
        "fish": "fish.fill",
        // Veggies
        "vegetables": "carrot.fill",
        "bellPepperGreen": "carrot.fill",
        "lettuce": "leaf.fill",
        // Salsa / peppers
        "salsa": "flame.fill",
        "tomato": "flame.fill",
        "corn": "leaf.fill",
        "chiliPeppersRed": "flame.fill",
        // Toppings
        "cheeseSlice": "square.fill",
        "sourCream": "drop.fill",
        "guacamole": "leaf.fill",
        // Dressing / oil / sauce
        "sauceBBQWorcestershire": "drop.fill",
        "oil": "drop.fill",
        // Chips / snacks
        "chipsBaked": "popcorn.fill"
    ]
}
