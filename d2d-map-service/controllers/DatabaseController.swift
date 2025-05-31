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
    private let listName = Expression<String?>("listName")  // Optional string

    private func createTable() {
        do {
            try db?.run(prospects.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(fullName)
                t.column(address)
                t.column(listName)  // Add listName column
                // You can add 'count' column too if you want to store it in DB
            })
        } catch {
            print("Create table failed: \(error)")
        }
    }



    /**
     This function adds prospects to the sqlite database
     */
    func addProspect(prospect: Prospect) {
        do {
            let insert = prospects.insert(
                fullName <- prospect.fullName,
                address <- prospect.address,
                listName <- prospect.listName
            )
            try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }



    /**
     This function gets all prospects from the sqlite database and returns a 2D string array
     */
    func getAllProspects(for listFilter: String) -> [Prospect] {
        var result: [Prospect] = []
        do {
            let query = (listFilter == "All") ?
                prospects : prospects.filter(listName == listFilter)

            for row in try db!.prepare(query) {
                let fullNameValue = try row.get(fullName)
                let addressValue = try row.get(address)
                let listValue = try? row.get(listName)

                // Use default count, or add count to your DB & fetch it similarly
                let p = Prospect(id: UUID(),
                                 fullName: fullNameValue,
                                 address: addressValue,
                                 count: 0,
                                 listName: listValue)
                result.append(p)
            }
        } catch {
            print("Select failed: \(error)")
        }
        return result
    }


}
