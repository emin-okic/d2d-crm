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
                t.column(fullName)
                t.column(address)
            })
        } catch {
            print("Create table failed: \(error)")
        }
    }

    func addProspect(name: String, addr: String) {
        do {
            let insert = prospects.insert(fullName <- name, address <- addr)
            try db?.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }

    func getAllProspects() -> [(String, String)] {
        var result: [(String, String)] = []
        do {
            for row in try db!.prepare(prospects) {
                let name = row[fullName]
                let addr = row[address]
                result.append((name, addr))
            }
        } catch {
            print("Select failed: \(error)")
        }
        return result
    }
}
