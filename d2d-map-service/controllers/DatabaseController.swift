//
//  DatabaseController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SQLite

import Foundation


class DatabaseController {
    
    // These two variables set the sqlite database
    static let shared = DatabaseController()

    public var db: Connection?

    // Table and columns
    private let prospects = Table("prospects")
    private let id = Expression<Int64>("id")
    private let fullName = Expression<String>("fullName")
    private let address = Expression<String>("address")
    
    private let list = Expression<String>("list")

    // Production Initializer
    private init() {
        connect()
        createTable()
    }
    
    // Testing initializer (in-memory DB)
    init(inMemory: Bool) {
        if inMemory {
            db = try? Connection(.inMemory)
        } else {
            connect()
        }
        createTable()
    }

    /**
     This function connects to the sqlite database
     */
    private func connect() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            db = try Connection("\(path)/prospects.sqlite3")
        } catch {
            print("DB connection failed: \(error)")
        }
    }

    /**
     This function creates a table in the sqlite database to hold prospects
     */
    private func createTable() {
        do {
            try db?.run(prospects.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(fullName)
                t.column(address)
                t.column(list)
            })
        } catch {
            print("Create table failed: \(error)")
        }
    }

    /**
     This function adds prospects to the sqlite database
     */
    func addProspect(name: String, addr: String) {
        do {
            let insert = prospects.insert(fullName <- name, address <- addr, list <- "Prospects")
            try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }

    /**
     This function gets all prospects from the sqlite database and returns a 2D string array
     */
    func getAllProspects() -> [(String, String, String)] {
        var result: [(String, String, String)] = []
        do {
            for row in try db!.prepare(prospects) {
                let name = row[fullName]
                let addr = row[address]
                let list = row[list]
                result.append((name, addr, list))
            }
        } catch {
            print("Select failed: \(error)")
        }
        return result
    }
    

    func updateProspect(_ prospect: Prospect) {
        guard let db = db else { return }

        // Filter the row by integer id (assuming your Prospect.id is Int64)
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


}
