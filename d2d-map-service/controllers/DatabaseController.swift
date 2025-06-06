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
    
    private let knocks = Table("knocks")
    private let knockId = Expression<Int64>("id")
    private let prospectId = Expression<Int64>("prospect_id")
    private let knockDate = Expression<Date>("date")
    private let knockStatus = Expression<String>("status")
    
    private let userEmail = Expression<String>("user_email")



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

    /**
     This function adds prospects to the sqlite database
     */
    func addProspect(name: String, addr: String) -> Int64? {
        do {
            let insert = prospects.insert(fullName <- name, address <- addr, list <- "Prospects")
            let rowId = try db?.run(insert)
            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }
    
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
