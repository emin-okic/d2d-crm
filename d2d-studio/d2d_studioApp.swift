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
    @State private var showSplash = true
    @State private var deepLinkURL: URL?
    @State private var showTodaysAppointments = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                withAnimation { showSplash = false }
                            }
                        }
                        // Catch deep-link even while splash is up
                        .onOpenURL { url in handleDeepLink(url) }
                } else {
                    RootView()
                        .onOpenURL { url in handleDeepLink(url) }
                        // Sheet for today’s appointments
                        .sheet(isPresented: $showTodaysAppointments) {
                            NavigationStack {
                                TodaysAppointmentsView()
                                    .navigationTitle("Today's Appointments")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button("Done") {
                                                showTodaysAppointments = false
                                            }
                                        }
                                    }
                            }
                        }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Route incoming URLs into the correct state change
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "d2dcrm",
              url.host == "todaysappointments"
        else { return }

        // trigger the sheet
        showTodaysAppointments = true
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
        Appointment.self,
        Note.self
    ])

    let config = ModelConfiguration(schema: schema, url: url)

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to load ModelContainer: \(error)")
    }
}()
