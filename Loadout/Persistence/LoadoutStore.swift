import Foundation
import SwiftData
import SwiftUI

/// The one SwiftData container, reachable statically.
///
/// App Intents run outside the SwiftUI environment — Siri and the Shortcuts app
/// can invoke them while Loadout isn't even foregrounded — so they can't reach a
/// container injected with `.modelContainer(for:)`. Both the app and the intents
/// take it from here, which also guarantees they're looking at the *same* store
/// rather than two stacks over one file.
nonisolated enum LoadoutStore {
    static let schema = Schema([FavoriteMeal.self, LoggedMeal.self])

    /// Nil only if the on-disk store is unreadable. Callers decide what that
    /// means: an intent reports it to the user, the app falls back to letting
    /// SwiftUI build one (matching the previous behaviour exactly).
    static let shared: ModelContainer? = try? ModelContainer(for: schema)
}

extension View {
    /// Attach the shared container, or let SwiftUI build one if the shared
    /// store couldn't be opened.
    @ViewBuilder
    func modelContainerIfAvailable(_ container: ModelContainer?) -> some View {
        if let container {
            self.modelContainer(container)
        } else {
            self.modelContainer(for: [FavoriteMeal.self, LoggedMeal.self])
        }
    }
}
