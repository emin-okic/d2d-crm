//
//  TripDistanceHelperTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import XCTest
import CoreLocation
@testable import d2d_studio

final class TripDistanceHelperTests: XCTestCase {
    
    func testCalculateMilesRealAddresses() async {
        let start = "1600 Amphitheatre Parkway, Mountain View, CA"
        let end = "1 Infinite Loop, Cupertino, CA"
        
        let miles = await TripDistanceHelper.calculateMiles(from: start, to: end)
        
        print("Calculated miles: \(miles)")
        // Assert that we get a reasonable distance (roughly 8–12 miles for these addresses)
        XCTAssertGreaterThan(miles, 5)
        XCTAssertLessThan(miles, 15)
    }
    
    func testCalculateMilesInvalidAddress() async {
        let start = "Some Unknown Place 12345"
        let end = "Another Unknown Place 67890"
        
        let miles = await TripDistanceHelper.calculateMiles(from: start, to: end)
        
        XCTAssertEqual(miles, 0.0, "Distance should be 0 for invalid addresses")
    }
}
