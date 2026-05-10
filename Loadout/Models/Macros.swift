import Foundation

nonisolated struct Macros: Codable, Hashable, Sendable {
    var calories: Double
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double

    static let zero = Macros(calories: 0, proteinGrams: 0, carbGrams: 0, fatGrams: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            calories: lhs.calories + rhs.calories,
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbGrams: lhs.carbGrams + rhs.carbGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams
        )
    }

    static func * (lhs: Macros, quantity: Double) -> Macros {
        Macros(
            calories: lhs.calories * quantity,
            proteinGrams: lhs.proteinGrams * quantity,
            carbGrams: lhs.carbGrams * quantity,
            fatGrams: lhs.fatGrams * quantity
        )
    }
}
