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

@MainActor
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
            })

        } catch {
            print("Create table failed: \(error)")
        }
    }

    // MARK: - Prospect Operations

    func addProspect(name: String, addr: String) -> Int64? {
        do {
            let insert = prospects.insert(fullName <- name, address <- addr, list <- "Prospects")
            return try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }

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

    func addKnock(for prospectIdValue: Int64, date: Date, status: String, latitude: Double, longitude: Double) {
        let lat = Expression<Double>("latitude")
        let lon = Expression<Double>("longitude")

        do {
            let insert = knocks.insert(
                prospectId <- prospectIdValue,
                knockDate <- date,
                knockStatus <- status,
                lat <- latitude,
                lon <- longitude
            )
            try db?.run(insert)
        } catch {
            print("Insert knock failed: \(error)")
        }
    }

    func getProspectsWithKnocks() -> [Prospect] {
        var results: [Prospect] = []

        do {
            for row in try db!.prepare(prospects) {
                let pId = row[id]
                let name = row[fullName]
                let addr = row[address]
                let listName = row[list]

                var knocksArray: [Knock] = []
                let knockQuery = knocks.filter(prospectId == pId)

                for knockRow in try db!.prepare(knockQuery) {
                    let dateVal = knockRow[knockDate]
                    let statusVal = knockRow[knockStatus]
                    let lat = knockRow[Expression<Double>("latitude")]
                    let lon = knockRow[Expression<Double>("longitude")]
                    let knock = Knock(date: dateVal, status: statusVal, latitude: lat, longitude: lon)
                    knocksArray.append(knock)
                }

                let count = knocksArray.count
                let prospect = Prospect(fullName: name, address: addr, count: count, list: listName)
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
    func suggestNeighborProspect(from customerAddress: String) {
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(customerAddress) { placemarks, error in
            guard let location = placemarks?.first?.location?.coordinate else {
                print("❌ Could not geocode customer address: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let neighborCoord = CLLocationCoordinate2D(
                latitude: location.latitude + 0.0001,
                longitude: location.longitude + 0.0001
            )

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

                do {
                    if let db = self.db {
                        let prospectQuery = self.prospects.filter(self.address == neighborAddress)
                        let count = try db.scalar(prospectQuery.count)

                        guard count == 0 else {
                            print("ℹ️ Neighbor already exists in database: \(neighborAddress)")
                            return
                        }

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

    func geocodeAndSuggestNeighbor(from customerAddress: String, completion: @escaping (String?) -> Void) {
        let components = customerAddress.components(separatedBy: " ")
        guard let first = components.first,
              let baseNumber = Int(first) else {
            completion(nil)
            return
        }

        let streetRemainder = components.dropFirst().joined(separator: " ")

        let maxAttempts = 10
        let existingAddresses = getAllProspects().map { $0.1.lowercased() }

        let geocoder = CLGeocoder()
        func tryOffset(_ offset: Int) {
            let newAddress = "\(baseNumber + offset) \(streetRemainder)"
            if existingAddresses.contains(newAddress.lowercased()) {
                if offset < maxAttempts {
                    tryOffset(offset + 1)
                } else {
                    completion(nil)
                }
                return
            }

            geocoder.geocodeAddressString(newAddress) { placemarks, error in
                if placemarks?.first?.location != nil {
                    print("✅ Valid neighbor: \(newAddress)")
                    completion(newAddress)
                } else if offset < maxAttempts {
                    tryOffset(offset + 1)
                } else {
                    completion(nil)
                }
            }
        }

        tryOffset(1)
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
