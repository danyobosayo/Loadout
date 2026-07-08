import Foundation

/// How tapping items in a station behaves. The tap model replaces the old
/// ½ · 1 · 2 chips: a station's policy governs what one tap does. Three
/// behaviors cover every station today (universal-first); restaurants get
/// tuned individually later by reassigning ids below.
nonisolated enum PortionPolicy: Equatable, Sendable {
    /// Base / protein / rice / beans / grain. Tap one item full → ×2 → off;
    /// tap a *second* item and both become ½ + ½ (one "base" worth). Tapping
    /// a half removes it and restores the other to full.
    case splitBase

    /// Dips / dressings / salsa. Tap to add scoops; the total is capped. At
    /// the cap a new item does nothing, and re-tapping a chosen one zeroes it
    /// to free room.
    case cappedScoops(max: Int)

    /// Toppings / veggies / everything else (default). Each item independently
    /// +1, uncapped, with a − to reduce.
    case freeAddOns

    /// A counting station (tap to add, − to reduce, count shown) as opposed to
    /// the base cycle. splitBase is the odd one out.
    var isCounter: Bool {
        if case .splitBase = self { return false }
        return true
    }
}

nonisolated extension MenuCategory {
    /// Universal-first policy assignment, keyed by station id (like
    /// `CategoryStyle`). Data-light on purpose — reassign here to tune a
    /// restaurant, or lift into the menu JSON when per-restaurant divergence
    /// grows.
    var portionPolicy: PortionPolicy {
        switch id {
        case "rice", "beans", "bases", "mains", "protein", "proteins":
            return .splitBase
        case "dips":
            return .cappedScoops(max: 3)
        case "dressings":
            return .cappedScoops(max: 2)
        case "dressing":
            return .cappedScoops(max: 1)
        default:
            return .freeAddOns
        }
    }
}
