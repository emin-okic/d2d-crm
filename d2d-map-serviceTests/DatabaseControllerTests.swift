//
//  DatabaseControllerTests.swift
//  d2d-map-serviceTests
//
//  Created by Emin Okic on 5/31/25.
//

import XCTest
import SQLite
@testable import d2d_map_service

final class DatabaseControllerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDatabaseControllerInitialization() {
        // This will trigger the singleton initializer
        let dbController = DatabaseController.shared

        // Just make sure it's not nil
        XCTAssertNotNil(dbController, "DatabaseController.shared should not be nil after initialization.")
    }
    
    func testDatabaseFileExistsAfterInit() {
        _ = DatabaseController.shared // Triggers init()

        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbPath = "\(docs)/prospects.sqlite3"

        XCTAssertTrue(FileManager.default.fileExists(atPath: dbPath), "Database file should exist after DatabaseController is initialized.")
    }
    
    func testProspectsTableExists() {
        let db = DatabaseController.shared

        do {
            let tables = try db.db?.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='prospects';")

            let tableExists = tables?.contains(where: { row in
                if let name = row[0] as? String {
                    return name == "prospects"
                }
                return false
            }) ?? false

            XCTAssertTrue(tableExists, "Table 'prospects' should exist in the database after initialization.")
        } catch {
            XCTFail("Failed to query sqlite_master: \(error)")
        }
    }
    
    func testAddProspectInsertsRecord() {
        // Use in-memory database to isolate the test
        let db = DatabaseController(inMemory: true)

        let testName = "Test User \(UUID().uuidString.prefix(5))"
        let testAddress = "123 Test Lane"

        db.addProspect(name: testName, addr: testAddress)
        let all = db.getAllProspects()

        let match = all.contains { $0.0 == testName && $0.1 == testAddress }
        XCTAssertTrue(match, "Expected prospect with name '\(testName)' and address '\(testAddress)' to be in the database.")
    }
    
    func testGetAllProspectsReturnsCorrectData() {
        let db = DatabaseController(inMemory: true)

        let testData = [
            ("Alice Johnson", "100 Elm Street"),
            ("Bob Smith", "200 Oak Avenue"),
            ("Charlie Day", "300 Pine Road")
        ]

        // Insert test data
        for (name, address) in testData {
            db.addProspect(name: name, addr: address)
        }

        // Fetch data
        let results = db.getAllProspects()

        // Check that all inserted data exists
        for (name, address) in testData {
            let match = results.contains(where: { $0.0 == name && $0.1 == address })
            XCTAssertTrue(match, "Expected (\(name), \(address)) in results.")
        }

        // Check total count matches
        XCTAssertEqual(results.count, testData.count, "Expected \(testData.count) results but got \(results.count)")
    }


}
