//
//  d2d_map_serviceApp.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct d2d_map_serviceApp: App {
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                RootView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// Use a shared container pointed to the custom folder
let sharedModelContainer: ModelContainer = {
    // Get the app's Application Support directory
    let appSupportURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("d2d-map-service/database", isDirectory: true)
    
    let url = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("d2d-map-service/database/prospects.sqlite")

    print("SwiftData SQLite location: \(url.path)")

    // Create the directory if it doesn't exist
    try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

    // Point SwiftData to that file
    let config = ModelConfiguration(
        "ProspectModel",
        url: appSupportURL.appendingPathComponent("prospects.sqlite")
    )

    return try! ModelContainer(for: Prospect.self, Knock.self, configurations: config)
}()
