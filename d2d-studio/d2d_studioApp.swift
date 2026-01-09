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
struct d2d_studioApp: App {
    
    @State private var sessionId = UUID().uuidString
    
    @State private var deepLinkURL: URL?

    var body: some Scene {
        WindowGroup {
            
            RootView()
                .onOpenURL { url in handleDeepLink(url) }
                .preferredColorScheme(.light)
            
        }
        .modelContainer(sharedModelContainer)
    }

    /// Route incoming URLs into the correct state change
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "d2dcrm" else { return }

        if url.host == "followup" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let filter = components?.queryItems?
                .first(where: { $0.name == "filter" })?.value

            NotificationCenter.default.post(
                name: .openFollowUpAssistant,
                object: filter
            )
            return
        }
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
        Customer.self,
        Knock.self,
        Trip.self,
        Objection.self,
        Appointment.self,
        Note.self,
        Recording.self
    ])

    // ⬇️ Explicitly opt OUT of CloudKit mirroring
    let config = ModelConfiguration(
        schema: schema,
        url: url,
        cloudKitDatabase: .none   // keep local-only
    )

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to load ModelContainer: \(error)")
    }
}()
