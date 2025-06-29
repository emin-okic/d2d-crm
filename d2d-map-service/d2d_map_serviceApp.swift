//
//  d2d_map_serviceApp.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

import SwiftUI
import SwiftData
import Foundation

/// The main entry point of the D2D Map Service app.
///
/// This struct defines the app's lifecycle using SwiftUI's `App` protocol.
/// It determines whether to show the `LoginView` or the main `RootView` depending on login state.
@main
struct d2d_map_serviceApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // Inject a shared model container for SwiftData persistence
        .modelContainer(sharedModelContainer)
    }
}

/// A shared SwiftData `ModelContainer` configured to store app data in a custom folder.
///
/// This container supports models for `Prospect`, and`Knock`
/// It persists data in a file located at: `ApplicationSupport/d2d-map-service/database/prospects.sqlite`
let sharedModelContainer: ModelContainer = {
    // Determine the path to the database file
    let url = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("d2d-map-service/database/prospects.sqlite")

    // Ensure the directory exists
    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    // Configure the model container with a custom URL
    let config = ModelConfiguration(url: url)

    do {
        // Load the model container for the specified model types
        return try ModelContainer(
                    for: Prospect.self, Knock.self, Trip.self,
                    configurations: config
                )
    } catch {
        fatalError("Failed to load ModelContainer: \(error)")
    }
}()
