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
    
    @State private var emailInput: String = ""

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                RootView(isLoggedIn: $isLoggedIn, userEmail: emailInput)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, emailInput: $emailInput)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// Use a shared container pointed to the custom folder
let sharedModelContainer: ModelContainer = {
    let url = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("d2d-map-service/database/prospects.sqlite")

    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

    let config = ModelConfiguration(
        url: url  // ← no model name string
    )

    do {
        return try ModelContainer(for: Prospect.self, Knock.self, User.self, configurations: config)
    } catch {
        fatalError("Failed to load ModelContainer: \(error)")
    }
}()
