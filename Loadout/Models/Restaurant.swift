import Foundation

nonisolated struct Restaurant: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let categories: [MenuCategory]
    let dataSource: DataSource
    let schemaVersion: Int
    /// How this place is ordered. Defaults to `.assembly` — the station-by-station
    /// builder Loadout started as — so an uncurated menu behaves exactly as before.
    let orderingModel: OrderingModel
    /// Shared recipe definitions keep Starbucks' many cup-size rows compact:
    /// each item references one product recipe, whose defaults vary by size.
    let drinkRecipes: [DrinkRecipe]

    init(
        id: String, name: String, categories: [MenuCategory],
        dataSource: DataSource, schemaVersion: Int,
        orderingModel: OrderingModel = .assembly,
        drinkRecipes: [DrinkRecipe] = []
    ) {
        self.id = id
        self.name = name
        self.categories = categories
        self.dataSource = dataSource
        self.schemaVersion = schemaVersion
        self.orderingModel = orderingModel
        self.drinkRecipes = drinkRecipes
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, categories, dataSource, schemaVersion, orderingModel, drinkRecipes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            categories: try c.decode([MenuCategory].self, forKey: .categories),
            dataSource: try c.decode(DataSource.self, forKey: .dataSource),
            schemaVersion: try c.decode(Int.self, forKey: .schemaVersion),
            orderingModel: try c.decodeIfPresent(OrderingModel.self, forKey: .orderingModel) ?? .assembly,
            drinkRecipes: try c.decodeIfPresent([DrinkRecipe].self, forKey: .drinkRecipes) ?? []
        )
    }

    func drinkRecipe(for item: MenuItem) -> DrinkRecipe? {
        guard let recipeId = item.recipeId else { return nil }
        return drinkRecipes.first { $0.id == recipeId }
    }
}

nonisolated struct DataSource: Codable, Hashable, Sendable {
    let url: URL
    // ISO 8601 calendar date (YYYY-MM-DD). String, not Date, so JSON files
    // stay readable and the source-of-truth doesn't shift with timezones.
    let fetchedAt: String
    let fetchedBy: String
    let notes: String?
}
