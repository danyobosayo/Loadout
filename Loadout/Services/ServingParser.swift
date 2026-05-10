import Foundation

/// Maps a `MenuItem.servingDescription` (e.g., "4 oz", "2 fl oz", "1
/// tortilla", "4 oz (regular)") into MacroFactor's `Serving` shape,
/// scaling by `quantity` so a line item with quantity 2 of a 4 oz serving
/// reports as `.measured(8, .ounces)`.
nonisolated enum ServingParser {
    static func parse(_ description: String, quantity: Double = 1) -> MFExport.Serving {
        let trimmed = stripParenthetical(description).trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 2, let amount = Double(parts[0]) else {
            // No leading number we recognise — treat the whole string as a
            // custom label with quantity as the amount. "weight" is unknown
            // for opaque labels, so we send 0.
            return .custom(
                amount: decimal(quantity),
                label: trimmed.isEmpty ? "serving" : trimmed,
                weight: 0
            )
        }

        let scaled = decimal(amount * quantity)
        let unitText = parts[1...].joined(separator: " ").lowercased()

        if let unit = unit(forUnitText: unitText) {
            return .measured(amount: scaled, unit: unit)
        }
        // "1 tortilla", "1 scoop" → custom label, weight unknown.
        return .custom(amount: scaled, label: unitText, weight: 0)
    }

    private static func stripParenthetical(_ s: String) -> String {
        guard let openParen = s.firstIndex(of: "(") else { return s }
        return String(s[..<openParen])
    }

    private static func unit(forUnitText text: String) -> MFExport.Unit? {
        switch text {
        case "oz", "ozs", "ounce", "ounces":
            return .ounces
        case "fl oz", "fl ozs", "fluid ounce", "fluid ounces":
            return .fluidOuncesUS
        case "g", "gram", "grams":
            return .grams
        case "ml", "milliliter", "milliliters":
            return .milliliters
        case "lb", "lbs", "pound", "pounds":
            return .pounds
        case "cup", "cups":
            return .cupsUS
        case "tbsp", "tablespoon", "tablespoons":
            return .tablespoonsUS
        case "tsp", "teaspoon", "teaspoons":
            return .teaspoonsUS
        default:
            return nil
        }
    }

    /// Foundation's `Decimal(_ Double:)` is bit-exact, so 0.1 yields a
    /// long binary tail. Macro values originate from CSV strings with at
    /// most one decimal place; we round to a tenth to keep the JSON
    /// output (and `Decimal == Decimal` in tests) representation-clean.
    static func decimal(_ value: Double) -> Decimal {
        let rounded = (value * 10).rounded() / 10
        return Decimal(rounded)
    }
}
