import SwiftUI

/// The surface recipe — STYLE_GUIDE.md §3. The only place surfaces
/// are hand-assembled; every card in the app is this view. A flat
/// fill separated from the canvas by a 1 pt hairline. No gradients,
/// no shadows — depth comes from fill contrast alone.
struct Card<Content: View>: View {
    var elevated = false
    var padding: CGFloat = Spacing.md
    /// A selected/active state: swaps the hairline for an accent border and
    /// tints the fill, so "this is in your meal" reads at the container level
    /// (not just a brighter dot). Nil keeps the resting hairline card.
    var highlight: Color? = nil
    private let content: Content

    init(elevated: Bool = false, padding: CGFloat = Spacing.md, highlight: Color? = nil, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.padding = padding
        self.highlight = highlight
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                ZStack {
                    shape.fill(elevated ? Color.surfaceElevated : Color.surface)
                    if let highlight {
                        shape.fill(highlight.opacity(0.1))
                    }
                    shape.strokeBorder(highlight ?? Color.hairline, lineWidth: highlight == nil ? 1 : 1.5)
                }
            }
    }
}
