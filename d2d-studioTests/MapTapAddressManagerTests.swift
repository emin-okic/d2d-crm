//
//  MapTapAddressManagerTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import XCTest
import CoreLocation
@testable import d2d_studio

final class MapTapAddressManagerTests: XCTestCase {

    func testHandleTapStoresCoordinate() {
        let manager = MapTapAddressManager()
        let coordinate = CLLocationCoordinate2D(latitude: 41.5868, longitude: -93.6250)

        manager.handleTap(at: coordinate)

        XCTAssertEqual(manager.tappedCoordinate?.latitude, coordinate.latitude)
        XCTAssertEqual(manager.tappedCoordinate?.longitude, coordinate.longitude)
    }

    func testHandleTapEventuallySetsAddressAndShowsPrompt() {
        let manager = MapTapAddressManager()
        let expectation = XCTestExpectation(description: "Reverse geocoding completes")

        // Downtown Des Moines (stable geocoding result)
        let coordinate = CLLocationCoordinate2D(latitude: 41.5868, longitude: -93.6250)

        manager.handleTap(at: coordinate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(manager.tappedAddress.isEmpty)
            XCTAssertTrue(manager.showAddPrompt)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }
}
