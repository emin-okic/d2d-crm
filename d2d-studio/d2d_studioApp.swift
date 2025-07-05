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
struct d2d_studioApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                RootView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

/// A shared SwiftData `ModelContainer` configured to store app data in a custom folder.
///
/// This container supports models for `Prospect`, and`Knock`
/// It persists data in a file located at: `ApplicationSupport/d2d-map-service/database/prospects.sqlite`
let sharedModelContainer: ModelContainer = {
    let url = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("d2d-studio/database/prospects.sqlite")

    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    let schema = Schema([
        Prospect.self,
        Knock.self,
        Trip.self,
        Objection.self,
        Recording.self
    ])

    let config = ModelConfiguration(schema: schema, url: url)

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to load ModelContainer: \(error)")
    }
}()
