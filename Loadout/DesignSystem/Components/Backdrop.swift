import SwiftUI

/// The canvas — flat void with a whisper of contextual hue: a single
/// static radial wash from the top edge (volt on home, restaurant hue
/// inside a menu). No motion, no mesh, no gloss — STYLE_GUIDE.md §5.
/// Home/volt stays a 5% whisper; a restaurant context passes a stronger
/// `intensity` so each place reads distinct while you build.
struct Backdrop: View {
    var tint: Color = .volt
    var intensity: Double = 0.05

    var body: some View {
        ZStack {
            Color.void
            RadialGradient(
                colors: [tint.opacity(intensity), .clear],
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
