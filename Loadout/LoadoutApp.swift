//
//  LoadoutApp.swift
//  Loadout
//
//  Created by Daniel Sungsu Kim on 2026/5/9.
//

import SwiftUI
import SwiftData

@main
struct LoadoutApp: App {
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Item.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
