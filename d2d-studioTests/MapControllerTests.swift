//
//  MapControllerTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import XCTest
import MapKit
@testable import d2d_studio

final class MapControllerTests: XCTestCase {

    func testClearMarkersRemovesAllMarkers() {
        let controller = MapController(
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )

        controller.markers = [
            IdentifiablePlace(
                address: "123 Test St",
                location: CLLocationCoordinate2D(latitude: 41, longitude: -93),
                count: 2
            )
        ]

        controller.clearMarkers()

        XCTAssertTrue(controller.markers.isEmpty)
    }
    
    func testSetMarkersGroupsUnitsAndPrioritizesCustomers1() {
        let controller = MapController(
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )

        let prospect = Prospect(
            fullName: "Test Prospect",
            address: "456 Main St Apt 1",
            count: 2
        )
        prospect.latitude = 41.1
        prospect.longitude = -93.1

        let customer = Customer(
            fullName: "Test Customer",
            address: "456 Main St Apt 2",
            count: 1
        )
        customer.latitude = 41.1
        customer.longitude = -93.1

        controller.setMarkers(
            prospects: [prospect],
            customers: [customer]
        )

        // Expect TWO markers (distinct units)
        XCTAssertEqual(controller.markers.count, 2)

        // Customer marker should exist and be prioritized
        let customerMarker = controller.markers.first { $0.list == "Customers" }
        XCTAssertNotNil(customerMarker)

        XCTAssertEqual(customerMarker?.count, 0)
        XCTAssertEqual(customerMarker?.unitCount, 0)
        XCTAssertFalse(customerMarker?.isMultiUnit ?? true)
    }

    func testSetMarkersCreatesProspectMarkerWhenNoCustomersExist() {
        let controller = MapController(
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        )

        let prospect = Prospect(
            fullName: "Unqualified Prospect",
            address: "789 Oak St",
            count: 1
        )
        prospect.latitude = 42.0
        prospect.longitude = -94.0
        prospect.isUnqualified = true

        controller.setMarkers(
            prospects: [prospect],
            customers: []
        )

        XCTAssertEqual(controller.markers.count, 1)

        let marker = controller.markers.first!

        XCTAssertEqual(marker.list, "Prospects")
        XCTAssertTrue(marker.isUnqualified)
        XCTAssertFalse(marker.isMultiUnit)
    }
    
}
