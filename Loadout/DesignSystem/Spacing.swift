import CoreFoundation

// 4pt grid — STYLE_GUIDE.md §3.
nonisolated enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

nonisolated enum Radius {
    static let chip: CGFloat = 10
    static let card: CGFloat = 20
    static let sheet: CGFloat = 28
}

/// Clearance for chrome that floats over scrolling content. Screens
/// apply these explicitly (via `.contentMargins`) instead of relying
/// on safe-area propagation, which doesn't reliably cross
/// NavigationStack boundaries.
nonisolated enum Metrics {
    /// Floating tab bar footprint: capsule (~52) + bottom inset + gap.
    static let tabBarClearance: CGFloat = 76
    /// Tray bar footprint, stacked above the tab bar on menu screens.
    static let trayBarClearance: CGFloat = 72
}
