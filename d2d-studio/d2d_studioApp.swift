//
//  d2d_map_serviceApp.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

import SwiftUI
import SwiftData
import Foundation
import SQLite

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

    let schema = appSchema
    let config = appModelConfiguration(schema: schema, url: url)

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        let originalError = error
        do {
            try repairMissingDemographicColumnsIfNeeded(at: url)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to load ModelContainer after compatibility repair. Original: \(originalError). Repair: \(error)")
        }
    }
}()

private var appSchema: Schema {
    Schema([
        Prospect.self,
        Customer.self,
        Knock.self,
        Trip.self,
        Objection.self,
        Appointment.self,
        Note.self,
        Recording.self,
        EmailTemplate.self,
        Email.self,
        PhoneCall.self
    ])
}

private func appModelConfiguration(schema: Schema, url: URL) -> ModelConfiguration {
    ModelConfiguration(
        schema: schema,
        url: url,
        cloudKitDatabase: .none
    )
}

private func repairMissingDemographicColumnsIfNeeded(at storeURL: URL) throws {
    guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

    try backupStoreFilesIfNeeded(at: storeURL)

    let db = try Connection(storeURL.path)
    let modelTables = ["ZPROSPECT", "ZCUSTOMER"]
    let demographicColumns = [
        "ZDEMOGRAPHICAGERANGE",
        "ZDEMOGRAPHICGENDER",
        "ZDEMOGRAPHICRACEETHNICITY",
        "ZDEMOGRAPHICPRIMARYLANGUAGE",
        "ZDEMOGRAPHICHOUSEHOLDTYPE",
        "ZDEMOGRAPHICHOMEOWNERSHIP",
        "ZDEMOGRAPHICNOTES"
    ]

    for table in modelTables {
        guard try tableExists(table, in: db) else { continue }

        for column in demographicColumns where try !columnExists(column, in: table, db: db) {
            try db.run("ALTER TABLE \(table) ADD COLUMN \(column) TEXT")
        }
    }
}

private func tableExists(_ tableName: String, in db: Connection) throws -> Bool {
    let statement = try db.prepare("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1", tableName)
    return statement.makeIterator().next() != nil
}

private func columnExists(_ columnName: String, in tableName: String, db: Connection) throws -> Bool {
    let statement = try db.prepare("PRAGMA table_info(\(tableName))")
    for row in statement {
        if let name = row[1] as? String, name == columnName {
            return true
        }
    }

    return false
}

private func backupStoreFilesIfNeeded(at storeURL: URL) throws {
    let backupDirectory = storeURL.deletingLastPathComponent()
        .appendingPathComponent("migration-backups", isDirectory: true)

    try FileManager.default.createDirectory(
        at: backupDirectory,
        withIntermediateDirectories: true
    )

    let timestamp = ISO8601DateFormatter()
        .string(from: Date())
        .replacingOccurrences(of: ":", with: "-")

    let fileNames = [
        storeURL.lastPathComponent,
        storeURL.lastPathComponent + "-wal",
        storeURL.lastPathComponent + "-shm"
    ]

    for fileName in fileNames {
        let source = storeURL.deletingLastPathComponent().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: source.path) else { continue }

        let destination = backupDirectory.appendingPathComponent("\(timestamp)-\(fileName)")
        if !FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.copyItem(at: source, to: destination)
        }
    }
}
