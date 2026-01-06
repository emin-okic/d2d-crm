//
//  TripTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import XCTest
@testable import d2d_studio

final class TripTests: XCTestCase {
    
    func testTripInitialization() {
        let start = "123 Main St"
        let end = "456 Elm St"
        let miles = 12.5
        let trip = Trip(startAddress: start, endAddress: end, miles: miles)
        
        XCTAssertEqual(trip.startAddress, start)
        XCTAssertEqual(trip.endAddress, end)
        XCTAssertEqual(trip.miles, miles)
        XCTAssertNotNil(trip.id)
        XCTAssertNotNil(trip.date)
    }
    
    func testTripCustomDate() {
        let customDate = Date(timeIntervalSince1970: 1_700_000_000)
        let trip = Trip(startAddress: "A", endAddress: "B", miles: 5.0, date: customDate)
        
        XCTAssertEqual(trip.date, customDate)
    }
    
    func testTripDistancePositive() {
        let trip = Trip(startAddress: "A", endAddress: "B", miles: 10.0)
        XCTAssertGreaterThanOrEqual(trip.miles, 0)
    }
    
    func testTripUniqueIDs() {
        let trip1 = Trip(startAddress: "A", endAddress: "B", miles: 1.0)
        let trip2 = Trip(startAddress: "C", endAddress: "D", miles: 2.0)
        XCTAssertNotEqual(trip1.id, trip2.id)
    }
}
