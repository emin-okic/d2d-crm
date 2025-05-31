//
//  DatabaseController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SQLite

import Foundation

class DatabaseController {
    static let shared = DatabaseController()

    private var db: Connection?

    // Table and columns
    private let prospects = Table("prospects")
    private let id = Expression<Int64>("id")
    private let uuid = Expression<String>("uuid")
    private let fullName = Expression<String>("fullName")
    private let address = Expression<String>("address")

    private init() {
        connect()
        createTable()
    }

    private func connect() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            db = try Connection("\(path)/prospects.sqlite3")
        } catch {
            print("DB connection failed: \(error)")
        }
    }

    private func createTable() {
        do {
            try db?.run(prospects.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(uuid, unique: true)
                t.column(fullName)
                t.column(address)
            })
        } catch {
            print("Create table failed: \(error)")
        }
    }


    func addProspect(uuid: UUID, name: String, addr: String) {
        do {
            let insert = prospects.insert(self.uuid <- uuid.uuidString, fullName <- name, address <- addr)
            try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }

    func getAllProspects() -> [Prospect] {
        var result: [Prospect] = []
        do {
            for row in try db!.prepare(prospects) {
                let name = row[fullName]
                let addr = row[address]
                let uuidStr = row[uuid]
                let id = UUID(uuidString: uuidStr) ?? UUID()
                result.append(Prospect(id: id, fullName: name, address: addr))
            }
        } catch {
            print("Select failed: \(error)")
        }
        return result
    }
    
    func updateProspect(uuid: UUID, newName: String, newAddress: String) {
        let prospectToUpdate = prospects.filter(self.uuid == uuid.uuidString)

        do {
            try db?.run(prospectToUpdate.update(fullName <- newName, address <- newAddress))
        } catch {
            print("Update failed: \(error)")
        }
    }
    
    func getRecentSearches() -> [String] {
        var addresses: [String] = []
        do {
            let query = prospects.select(address).filter(address != "")
            for row in try db!.prepare(query) {
                addresses.append(row[address])
            }
        } catch {
            print("Failed to fetch recent searches: \(error)")
        }
        return addresses
    }



}
