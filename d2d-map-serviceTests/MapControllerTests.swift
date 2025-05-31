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

    func makeProspect(id: UUID = UUID(), name: String, address: String) -> Prospect {
        Prospect(id: id, fullName: name, address: address, count: 0)
    }

    func testUpdateRecentSearchesAddsNewProspect() {
        let controller = MapController(region: MKCoordinateRegion())
        let prospect = makeProspect(name: "John", address: "123 Main St")

        controller.updateRecentSearches(with: prospect)

        XCTAssertEqual(controller.recentSearchIDs.count, 1)
        XCTAssertEqual(controller.recentSearchIDs.first, prospect.id)
    }

    func testUpdateRecentSearchesDeDupes() {
        let controller = MapController(region: MKCoordinateRegion())
        let id = UUID()
        let original = makeProspect(id: id, name: "John", address: "123 Main St")
        let updated = makeProspect(id: id, name: "John", address: "123 Main St")

        controller.updateRecentSearches(with: original)
        controller.updateRecentSearches(with: updated)

        XCTAssertEqual(controller.recentSearchIDs.count, 1)
        XCTAssertEqual(controller.recentSearchIDs.first, id)
    }

    func testUpdateRecentSearchesKeepsOnlyThree() {
        let controller = MapController(region: MKCoordinateRegion())
        let p1 = makeProspect(name: "A", address: "One")
        let p2 = makeProspect(name: "B", address: "Two")
        let p3 = makeProspect(name: "C", address: "Three")
        let p4 = makeProspect(name: "D", address: "Four")

        controller.updateRecentSearches(with: p1)
        controller.updateRecentSearches(with: p2)
        controller.updateRecentSearches(with: p3)
        controller.updateRecentSearches(with: p4)

        XCTAssertEqual(controller.recentSearchIDs.count, 3)
        XCTAssertEqual(controller.recentSearchIDs, [p4.id, p3.id, p2.id])
    }

    func testUpdateRecentSearchesMovesExistingToFront() {
        let controller = MapController(region: MKCoordinateRegion())
        let p1 = makeProspect(name: "A", address: "One")
        let p2 = makeProspect(name: "B", address: "Two")
        let p3 = makeProspect(name: "C", address: "Three")

        controller.updateRecentSearches(with: p1)
        controller.updateRecentSearches(with: p2)
        controller.updateRecentSearches(with: p3)

        controller.updateRecentSearches(with: p2) // move to front

        XCTAssertEqual(controller.recentSearchIDs, [p2.id, p3.id, p1.id])
    }
}
