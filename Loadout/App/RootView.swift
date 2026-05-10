import SwiftUI

struct RootView: View {
    var body: some View {
        // Phase 2: shows the design system catalog so the build is reviewable
        // end-to-end. Phase 3 replaces this with the real Restaurants tab.
        DesignSystemCatalog()
    }
}

#Preview {
    RootView()
}
