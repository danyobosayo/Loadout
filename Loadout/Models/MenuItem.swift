import Foundation

nonisolated struct MenuItem: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let servingDescription: String
    let macros: Macros
    let allergens: [Allergen]?
    let notes: String?
}

nonisolated enum Allergen: String, Codable, Hashable, Sendable, CaseIterable {
    case milk
    case egg
    case wheat
    case soy
    case peanut
    case treenut
    case fish
    case shellfish
    case sesame
}
