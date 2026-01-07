//
//  IdentifiablePlaceTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import XCTest
import SwiftUI
import CoreLocation
@testable import d2d_studio

final class IdentifiablePlaceTests: XCTestCase {

    func testInitializationSetsPropertiesCorrectly() {
        let coordinate = CLLocationCoordinate2D(latitude: 41.5868, longitude: -93.6250)

        let place = IdentifiablePlace(
            address: "123 Main St",
            location: coordinate,
            count: 2,
            unitCount: 3,
            list: "Customers",
            isUnqualified: false,
            isMultiUnit: true
        )

        XCTAssertEqual(place.address, "123 Main St")
        XCTAssertEqual(place.location.latitude, coordinate.latitude)
        XCTAssertEqual(place.location.longitude, coordinate.longitude)
        XCTAssertEqual(place.count, 2)
        XCTAssertEqual(place.unitCount, 3)
        XCTAssertEqual(place.list, "Customers")
        XCTAssertTrue(place.isMultiUnit)
        XCTAssertFalse(place.isUnqualified)
        XCTAssertNotNil(place.id)
    }

    func testMarkerColorLogic() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        XCTAssertEqual(
            IdentifiablePlace(address: "A", location: coordinate, count: 0).markerColor,
            .gray
        )

        XCTAssertEqual(
            IdentifiablePlace(address: "B", location: coordinate, count: 1).markerColor,
            .green
        )

        XCTAssertEqual(
            IdentifiablePlace(address: "C", location: coordinate, count: 3).markerColor,
            .yellow
        )

        XCTAssertEqual(
            IdentifiablePlace(address: "D", location: coordinate, count: 6).markerColor,
            .red
        )
    }

    func testUnqualifiedOverridesMarkerColor() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let place = IdentifiablePlace(
            address: "Blocked",
            location: coordinate,
            count: 0,
            isUnqualified: true
        )

        XCTAssertEqual(place.markerColor, .red)
    }
}
