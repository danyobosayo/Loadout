import SwiftUI

/// The surface recipe — STYLE_GUIDE.md §3. The only place surfaces
/// are hand-assembled; every card in the app is this view. A flat
/// fill separated from the canvas by a 1 pt hairline. No gradients,
/// no shadows — depth comes from fill contrast alone.
struct Card<Content: View>: View {
    var elevated = false
    var padding: CGFloat = Spacing.md
    private let content: Content

    init(elevated: Bool = false, padding: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background {
                let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                shape
                    .fill(elevated ? Color.surfaceElevated : Color.surface)
                    .overlay(shape.strokeBorder(Color.hairline, lineWidth: 1))
            }
    }
}
