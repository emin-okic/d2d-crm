//
//  CSVExportServiceTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import XCTest
@testable import d2d_studio

final class CSVExportServiceTests: XCTestCase {

    func testExportProspectsCreatesValidCSVFile() throws {
        // Given
        let prospect = Prospect(
            fullName: "John Doe",
            address: "123 Main St",
            count: 3
        )

        prospect.contactEmail = "john@example.com"
        prospect.contactPhone = "555-1234"
        prospect.latitude = 41.5868
        prospect.longitude = -93.6250

        // When
        let url = try CSVExportService.exportProspects([prospect])
        let contents = try String(contentsOf: url, encoding: .utf8)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(contents.contains("Full Name,Address,Email,Phone,Knock Count,Latitude,Longitude"))
        XCTAssertTrue(contents.contains("John Doe"))
        XCTAssertTrue(contents.contains("john@example.com"))
        XCTAssertTrue(contents.contains("555-1234"))
        XCTAssertTrue(contents.contains("3"))
    }
}
