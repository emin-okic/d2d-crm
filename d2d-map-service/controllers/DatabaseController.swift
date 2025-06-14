//
//  DatabaseController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SQLite
import Foundation
import CoreLocation

/// A singleton class that manages all SQLite operations for the D2D CRM app.
///
/// This controller handles the creation, insertion, and retrieval of `Prospect` and `Knock` data
/// using SQLite. It supports both production and in-memory configurations (for testing).
class DatabaseController {

    /// Shared singleton instance used across the app.
    static let shared = DatabaseController()

    /// The SQLite database connection object.
    public var db: Connection?

    // MARK: - Table and Column Definitions

    private let prospects = Table("prospects")
    private let id = Expression<Int64>("id")
    private let fullName = Expression<String>("fullName")
    private let address = Expression<String>("address")
    private let list = Expression<String>("list")

    private let knocks = Table("knocks")
    private let knockId = Expression<Int64>("id")
    private let prospectId = Expression<Int64>("prospect_id")
    private let knockDate = Expression<Date>("date")
    private let knockStatus = Expression<String>("status")
    private let userEmail = Expression<String>("user_email")

    // MARK: - Initializers

    /// Default initializer for production use. Connects to a file-based SQLite DB and creates tables.
    private init() {
        connect()
        createTable()
    }

    /// Alternative initializer for unit testing using an in-memory database.
    init(inMemory: Bool) {
        if inMemory {
            db = try? Connection(.inMemory)
        } else {
            connect()
        }
        createTable()
    }

    // MARK: - Database Setup

    /// Establishes a connection to the local SQLite database file.
    private func connect() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            db = try Connection("\(path)/prospects.sqlite3")
        } catch {
            print("DB connection failed: \(error)")
        }
    }

    /// Creates `prospects` and `knocks` tables if they do not already exist.
    private func createTable() {
        do {
            try db?.run(prospects.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(fullName)
                t.column(address)
                t.column(list)
            })

            try db?.run(knocks.create(ifNotExists: true) { t in
                t.column(knockId, primaryKey: .autoincrement)
                t.column(prospectId)
                t.column(knockDate)
                t.column(knockStatus)
                t.column(Expression<Double>("latitude"))
                t.column(Expression<Double>("longitude"))
                t.column(userEmail)
            })

        } catch {
            print("Create table failed: \(error)")
        }
    }

    // MARK: - Prospect Operations

    /// Inserts a new prospect into the `prospects` table.
    /// - Parameters:
    ///   - name: Full name of the prospect.
    ///   - addr: Address of the prospect.
    /// - Returns: The SQLite row ID of the inserted prospect.
    func addProspect(name: String, addr: String) -> Int64? {
        do {
            let insert = prospects.insert(fullName <- name, address <- addr, list <- "Prospects")
            return try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }

    /// Updates a prospect's full name, address, and list value.
    /// - Parameter prospect: The `Prospect` object with updated values.
    func updateProspect(_ prospect: Prospect) {
        guard let db = db else { return }

        let prospectToUpdate = prospects.filter(list == "Prospects")

        do {
            let update = prospectToUpdate.update(
                fullName <- prospect.fullName,
                address <- prospect.address,
                list <- prospect.list
            )
            if try db.run(update) > 0 {
                print("Successfully updated prospect")
            } else {
                print("No prospect found to update")
            }
        } catch {
            print("Update failed: \(error)")
        }
    }

    /// Retrieves all prospects from the database.
    /// - Returns: A list of tuples with each prospect's name, address, and list.
    func getAllProspects() -> [(String, String, String)] {
        var result: [(String, String, String)] = []
        do {
            for row in try db!.prepare(prospects) {
                result.append((row[fullName], row[address], row[list]))
            }
        } catch {
            print("Select failed: \(error)")
        }
        return result
    }

    // MARK: - Knock Operations

    /// Inserts a knock associated with a prospect.
    /// - Parameters:
    ///   - prospectIdValue: ID of the associated prospect.
    ///   - date: Date the knock occurred.
    ///   - status: Status of the knock ("Answered", "Not Answered").
    ///   - latitude: Latitude of the knock location.
    ///   - longitude: Longitude of the knock location.
    ///   - userEmailValue: The user who recorded the knock.
    func addKnock(for prospectIdValue: Int64, date: Date, status: String, latitude: Double, longitude: Double, userEmailValue: String) {
        let lat = Expression<Double>("latitude")
        let lon = Expression<Double>("longitude")

        do {
            let insert = knocks.insert(
                prospectId <- prospectIdValue,
                knockDate <- date,
                knockStatus <- status,
                lat <- latitude,
                lon <- longitude,
                userEmail <- userEmailValue
            )
            try db?.run(insert)
        } catch {
            print("Insert knock failed: \(error)")
        }
    }

    /// Retrieves all prospects and their associated knocks from the database.
    /// - Parameter userEmailValue: If provided, only knocks recorded by this user will be returned.
    /// - Returns: An array of `Prospect` objects with their knock history included.
    func getProspectsWithKnocks(for userEmailValue: String? = nil) -> [Prospect] {
        var results: [Prospect] = []

        do {
            for row in try db!.prepare(prospects) {
                let pId = row[id]
                let name = row[fullName]
                let addr = row[address]
                let listName = row[list]

                var knocksArray: [Knock] = []
                let knockQuery = userEmailValue == nil
                    ? knocks.filter(prospectId == pId)
                    : knocks.filter(prospectId == pId && userEmail == userEmailValue!)

                for knockRow in try db!.prepare(knockQuery) {
                    let dateVal = knockRow[knockDate]
                    let statusVal = knockRow[knockStatus]
                    let lat = knockRow[Expression<Double>("latitude")]
                    let lon = knockRow[Expression<Double>("longitude")]
                    let user = knockRow[userEmail]
                    let knock = Knock(date: dateVal, status: statusVal, latitude: lat, longitude: lon, userEmail: user)
                    knocksArray.append(knock)
                }

                let count = knocksArray.count
                let prospect = Prospect(fullName: name, address: addr, count: count, list: listName, userEmail: userEmailValue ?? "")
                prospect.knockHistory = knocksArray
                results.append(prospect)
            }
        } catch {
            print("Fetching prospects with knocks failed: \(error)")
        }

        return results
    }
}

extension DatabaseController {
    /// Suggests a neighboring prospect based on a newly converted customer.
    /// - Parameters:
    ///   - customerAddress: The address of the new customer.
    ///   - userEmail: The email of the user to associate with the suggested prospect.
    func suggestNeighborProspect(from customerAddress: String, for userEmail: String) {
        let geocoder = CLGeocoder()

        // Step 1: Geocode customer address
        geocoder.geocodeAddressString(customerAddress) { placemarks, error in
            guard let location = placemarks?.first?.location?.coordinate else {
                print("❌ Could not geocode customer address: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Step 2: Slightly offset coordinates to simulate neighbor
            let neighborCoord = CLLocationCoordinate2D(
                latitude: location.latitude + 0.0001,
                longitude: location.longitude + 0.0001
            )

            // Step 3: Reverse geocode neighbor address
            let neighborLocation = CLLocation(latitude: neighborCoord.latitude, longitude: neighborCoord.longitude)

            geocoder.reverseGeocodeLocation(neighborLocation) { neighborPlacemarks, error in
                guard let placemark = neighborPlacemarks?.first else {
                    print("❌ Could not reverse geocode neighbor location")
                    return
                }

                let components = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality
                ].compactMap { $0 }

                let joinedAddress = components.joined(separator: " ")

                guard let neighborAddress = joinedAddress.nilIfEmpty else {
                    print("❌ Neighbor address could not be constructed")
                    return
                }

                // Step 4: Check if prospect already exists at that address
                do {
                    if let db = self.db {
                        let prospectQuery = self.prospects.filter(self.address == neighborAddress)
                        let count = try db.scalar(prospectQuery.count)

                        guard count == 0 else {
                            print("ℹ️ Neighbor already exists in database: \(neighborAddress)")
                            return
                        }

                        // Step 5: Insert new suggested prospect
                        let insert = self.prospects.insert(
                            self.fullName <- "Suggested Neighbor",
                            self.address <- neighborAddress,
                            self.list <- "Prospects"
                        )
                        try db.run(insert)
                        print("✅ Suggested neighbor added: \(neighborAddress)")
                    }
                } catch {
                    print("❌ Failed to check or insert neighbor: \(error)")
                }
            }
        }
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
