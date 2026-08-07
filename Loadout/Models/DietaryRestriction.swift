import Foundation

/// What an item contains beyond the big-nine allergens.
///
/// Deliberately separate from `Allergen`: these aren't allergens, they're the
/// facts a *dietary* restriction is derived from. Modelling what an item
/// contains — rather than tagging each item "vegan", "vegetarian", "keto" —
/// means a new restriction is a new derivation, not another 887 items to flag.
nonisolated enum DietaryMarker: String, Codable, Hashable, Sendable, CaseIterable {
    /// Any beef, pork, poultry or lamb. Fish and shellfish are *not* meat —
    /// they're carried as allergens, and pescatarians are the reason.
    case meat
    /// Always accompanied by `meat`. Called out separately because "no pork"
    /// is one of the most common restrictions and doesn't follow from `meat`.
    case pork
    case honey
    case alcohol
}

/// A restriction the user can switch on. Each is a *derivation* over an item's
/// allergens and markers, never a stored per-item tag.
nonisolated enum DietaryRestriction: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case vegetarian
    case vegan
    case porkFree
    case glutenFree
    case dairyFree
    case eggFree
    case nutFree
    case soyFree
    case sesameFree
    case shellfishFree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vegetarian:    "Vegetarian"
        case .vegan:         "Vegan"
        case .porkFree:      "No pork"
        case .glutenFree:    "No gluten"
        case .dairyFree:     "No dairy"
        case .eggFree:       "No egg"
        case .nutFree:       "No nuts"
        case .soyFree:       "No soy"
        case .sesameFree:    "No sesame"
        case .shellfishFree: "No shellfish"
        }
    }

    /// Allergen-derived restrictions are grouped apart from the diet-style ones
    /// in the UI, because they carry different stakes.
    var isAllergen: Bool {
        switch self {
        case .vegetarian, .vegan, .porkFree: false
        default: true
        }
    }
}

/// Whether an item clears a restriction. Three states on purpose: an item we
/// haven't flagged is **unknown**, never "safe". Collapsing that into a boolean
/// is how a macro app quietly tells someone their meal is dairy-free because
/// nobody got round to checking it.
nonisolated enum DietaryVerdict: Hashable, Sendable {
    case allowed
    case excluded
    case unknown
}

nonisolated extension MenuItem {
    /// True once someone has actually determined this item's contents. `nil`
    /// allergens means unflagged; an empty array means checked and clean.
    var hasDietaryData: Bool { allergens != nil && dietaryMarkers != nil }

    func verdict(for restriction: DietaryRestriction) -> DietaryVerdict {
        guard let allergens, let markers = dietaryMarkers else { return .unknown }
        let a = Set(allergens)
        let m = Set(markers)

        let clears: Bool
        switch restriction {
        case .vegetarian:
            clears = !m.contains(.meat) && !a.contains(.fish) && !a.contains(.shellfish)
        case .vegan:
            clears = !m.contains(.meat) && !a.contains(.fish) && !a.contains(.shellfish)
                && !a.contains(.milk) && !a.contains(.egg) && !m.contains(.honey)
        case .porkFree:      clears = !m.contains(.pork)
        case .glutenFree:    clears = !a.contains(.wheat)
        case .dairyFree:     clears = !a.contains(.milk)
        case .eggFree:       clears = !a.contains(.egg)
        case .nutFree:       clears = !a.contains(.peanut) && !a.contains(.treenut)
        case .soyFree:       clears = !a.contains(.soy)
        case .sesameFree:    clears = !a.contains(.sesame)
        case .shellfishFree: clears = !a.contains(.shellfish)
        }
        return clears ? .allowed : .excluded
    }

    /// The verdict across several restrictions at once: excluded if any single
    /// one rejects it, unknown if we can't tell, allowed only when all clear.
    func verdict(for restrictions: Set<DietaryRestriction>) -> DietaryVerdict {
        guard !restrictions.isEmpty else { return .allowed }
        guard hasDietaryData else { return .unknown }
        return restrictions.contains { verdict(for: $0) == .excluded } ? .excluded : .allowed
    }
}
