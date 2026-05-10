import SwiftUI

struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "Loadout",
            systemImage: "fork.knife",
            description: Text("Phase 1: scaffold + core models. UI lands in later phases.")
        )
    }
}

#Preview {
    RootView()
}
