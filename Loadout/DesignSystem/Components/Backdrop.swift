import SwiftUI

/// The canvas — flat void with a whisper of contextual hue: a single
/// static radial wash from the top edge (volt on home, restaurant hue
/// inside a menu). No motion, no mesh, no gloss — STYLE_GUIDE.md §5.
/// At 5% opacity it registers as atmosphere, not decoration.
struct Backdrop: View {
    var tint: Color = .volt

    var body: some View {
        ZStack {
            Color.void
            RadialGradient(
                colors: [tint.opacity(0.05), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 440
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Backdrop(tint: .volt)
}
