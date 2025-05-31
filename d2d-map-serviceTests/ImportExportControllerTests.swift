//
//  ImportExportControllerTests.swift
//  d2d-map-serviceTests
//
//  Created by Emin Okic on 5/31/25.
//

import XCTest
@testable import d2d_map_service

final class ImportExportControllerTests: XCTestCase {

    func testBuildCSV() {
        let testPlaces = [
            IdentifiablePlace(address: "123 Main St", location: .init(latitude: 37.0, longitude: -122.0), count: 1),
            IdentifiablePlace(address: "456 Elm St", location: .init(latitude: 38.0, longitude: -121.0), count: 2)
        ]
        
        let csv = ImportExportController.buildCSV(from: testPlaces)
        
        let expectedCSV = """
        Address,Latitude,Longitude,Count
        "123 Main St",37.0,-122.0,1
        "456 Elm St",38.0,-121.0,2
        """

        XCTAssertEqual(csv.trimmingCharacters(in: .whitespacesAndNewlines),
                       expectedCSV.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testSaveCSVFile() {
        let testCSV = "Address,Latitude,Longitude,Count\n\"Test Address\",37.0,-122.0,1\n"
        let fileName = "TestCSV.csv"
        
        guard let url = ImportExportController.saveCSVFile(content: testCSV, fileName: fileName) else {
            XCTFail("Failed to save CSV file.")
            return
        }
        
        do {
            let savedContent = try String(contentsOf: url)
            XCTAssertEqual(savedContent, testCSV)
        } catch {
            XCTFail("Failed to read saved file: \(error)")
        }
    }
}

