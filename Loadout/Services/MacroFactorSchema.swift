import Foundation

/// Hand-rolled Codable mirrors of MacroFactor's `Log by JSON` schema
/// (workspace reference: ../Nutrition/MacroFactorFood.swift). Per
/// PROJECT.md §8 we don't import their Swift package — we mirror only the
/// fields we send and leave the icon/nutrient vocabularies as raw
/// strings, which MacroFactor's decoder handles forgivingly (unknown
/// icons fall back to `foodDefault`; unknown nutrient keys are dropped).
nonisolated enum MFExport {
    /// `Log by JSON` parent + recipe entries share this shape.
    struct Food: Codable, Equatable, Sendable {
        let source: String
        let icon: String
        let name: String
        let nutrients: [String: Decimal]
        let serving: Serving
        let llmPrompt: String?
        let barcode: String?
        let brand: String?
        let beverage: String?
        let notes: String?
        let recipe: [Food]?
    }

    /// Polymorphic single-value-container encoding matching MacroFactor's
    /// `Serving`. Decode order mirrors theirs: string literal → custom →
    /// measured (custom is tried first because its `weight`/`label` keys
    /// disambiguate from measured's `unit`).
    enum Serving: Equatable, Sendable {
        case one
        case per100Grams
        case per100ML
        case measured(amount: Decimal, unit: Unit)
        case custom(amount: Decimal, label: String, weight: Decimal)
    }

    enum Unit: String, Codable, Sendable, Equatable {
        case grams
        case pounds
        case ounces
        case fluidOuncesUS
        case milliliters
        case cupsUS
        case tablespoonsUS
        case teaspoonsUS
    }

    /// Nutrient keys we emit. MacroFactor's full vocabulary is wider, but
    /// our domain is locked to these four (commit 66ac6a0). Strings on the
    /// wire match MacroFactor's `Nutrient` raw values exactly, so its
    /// `[Nutrient: Decimal]` decoder receives them without loss.
    enum NutrientKey {
        static let energy = "energy"
        static let protein = "protein"
        static let carbs = "carbs"
        static let fat = "fat"
    }

    /// Source identifier per MacroFactor's spec (each export must include
    /// a stable `source`). Hard-coded so renames of the Xcode bundle id
    /// don't quietly fork our log entries in MacroFactor's history.
    static let sourceIdentifier = "loadout.app"

    /// Default icon for the parent meal — children carry their own
    /// `iconName`. MacroFactor's decoder maps unknown strings to
    /// `foodDefault`, so this is also a safe fallback for child icons.
    static let defaultIcon = "foodDefault"
}

nonisolated extension MFExport.Serving: Codable {
    private struct MeasuredPayload: Codable {
        let amount: Decimal
        let unit: String
    }
    private struct CustomPayload: Codable {
        let amount: Decimal
        let label: String
        let weight: Decimal
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .one: try container.encode("one")
        case .per100Grams: try container.encode("per100Grams")
        case .per100ML: try container.encode("per100ML")
        case .measured(let amount, let unit):
            try container.encode(MeasuredPayload(amount: amount, unit: unit.rawValue))
        case .custom(let amount, let label, let weight):
            try container.encode(CustomPayload(amount: amount, label: label, weight: weight))
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            switch s {
            case "one": self = .one
            case "per100Grams": self = .per100Grams
            case "per100ML": self = .per100ML
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown serving literal: \(s)"
                )
            }
        } else if let custom = try? container.decode(CustomPayload.self) {
            self = .custom(amount: custom.amount, label: custom.label, weight: custom.weight)
        } else {
            let m = try container.decode(MeasuredPayload.self)
            // Unknown unit strings fall back to grams — defensive symmetry
            // with MacroFactor's tolerant icon decoding.
            self = .measured(amount: m.amount, unit: MFExport.Unit(rawValue: m.unit) ?? .grams)
        }
    }
}
