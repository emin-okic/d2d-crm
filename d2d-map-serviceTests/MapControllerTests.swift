//
//  MapControllerTests.swift
//  d2d-map-serviceTests
//
//  Created by Emin Okic on 5/31/25.
//
import XCTest
import MapKit
@testable import d2d_map_service

final class MapControllerTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        // Force release your controller if needed
    }

    func makeProspect(id: UUID = UUID(), name: String, address: String, list: String, knockHistory: [Knock] = []) -> Prospect {
        Prospect(id: id, fullName: name, address: address, count: 0, list: list, knockHistory: knockHistory)
    }

}
