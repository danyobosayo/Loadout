import Foundation

nonisolated struct Restaurant: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let categories: [MenuCategory]
    let dataSource: DataSource
    let schemaVersion: Int
}

nonisolated struct DataSource: Codable, Hashable, Sendable {
    let url: URL
    // ISO 8601 calendar date (YYYY-MM-DD). String, not Date, so JSON files
    // stay readable and the source-of-truth doesn't shift with timezones.
    let fetchedAt: String
    let fetchedBy: String
    let notes: String?
}
