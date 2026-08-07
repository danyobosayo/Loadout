import Foundation

/// How "Fit my macros" should build a meal.
///
/// Two kinds of setting, deliberately modelled differently because they behave
/// differently: exactly **one focus** (they pull the objective in competing
/// directions, so they can't combine), plus **any number of exclusions** (each
/// just removes items from consideration, so they stack freely). Dietary
/// restrictions will land as more exclusions — same mechanism, no rework.
nonisolated struct AutoBuildPreferences: Codable, Hashable, Sendable {
    var focus: AutoBuildFocus
    var exclusions: Set<AutoBuildExclusion>

    static let `default` = AutoBuildPreferences(focus: .balanced, exclusions: [])

    init(focus: AutoBuildFocus = .balanced, exclusions: Set<AutoBuildExclusion> = []) {
        self.focus = focus
        self.exclusions = exclusions
    }

    // Decoded leniently so a preference written by a newer build (an unknown
    // focus, an exclusion we don't have yet) degrades to the default instead of
    // wiping the whole object.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        focus = (try? c.decode(AutoBuildFocus.self, forKey: .focus)) ?? .balanced
        let raw = (try? c.decode([String].self, forKey: .exclusions)) ?? []
        exclusions = Set(raw.compactMap(AutoBuildExclusion.init(rawValue:)))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(focus, forKey: .focus)
        try c.encode(exclusions.map(\.rawValue).sorted(), forKey: .exclusions)
    }

    private enum CodingKeys: String, CodingKey { case focus, exclusions }
}

/// The one dial that shapes the objective. Pick-one by nature: "as much protein
/// as possible" and "as many carbs as possible" are the same knob turned
/// opposite ways.
nonisolated enum AutoBuildFocus: String, Codable, CaseIterable, Sendable, Identifiable {
    case balanced
    case protein
    case carbs
    case fat
    case vegetables
    case volume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:   "Balanced"
        case .protein:    "High protein"
        case .carbs:      "Carb forward"
        case .fat:        "Fat forward"
        case .vegetables: "Veg forward"
        case .volume:     "High volume"
        }
    }

    var detail: String {
        switch self {
        case .balanced:   "Hit your macros evenly."
        case .protein:    "Lean, protein-dense picks first."
        case .carbs:      "Lean on grains and starches."
        case .fat:        "Room for avocado, cheese and oils."
        case .vegetables: "Load the plate with vegetables."
        case .volume:     "The most food for the calories."
        }
    }

    var symbol: String {
        switch self {
        case .balanced:   "circle.grid.cross"
        case .protein:    "bolt.fill"
        case .carbs:      "laurel.leading"
        case .fat:        "drop.fill"
        case .vegetables: "leaf.fill"
        case .volume:     "square.stack.3d.up.fill"
        }
    }
}

/// Something the builder should never put in a suggestion. Stackable, and the
/// natural home for dietary restrictions once every item carries flags.
nonisolated enum AutoBuildExclusion: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Sauces, dressings and dips — the poured-on condiments that carry most of
    /// a meal's hidden fat. Deliberately *not* salsa: it's near-zero calorie and
    /// vegetable-forward, and "no sauce" at a burrito counter doesn't mean
    /// "no pico".
    case sauces

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sauces: "No sauces or dressings"
        }
    }

    var detail: String {
        switch self {
        case .sauces: "Skips sauces, dressings and dips. Salsa still counts as a vegetable."
        }
    }

    /// The station ids this exclusion removes from consideration.
    var excludedCategoryIds: Set<String> {
        switch self {
        case .sauces: ["sauces", "dressings", "dressing", "dips"]
        }
    }
}
