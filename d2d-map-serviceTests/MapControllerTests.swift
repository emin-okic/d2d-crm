//
//  MapControllerTests.swift
//  d2d-map-serviceTests
//
//  Created by Emin Okic on 5/31/25.
//
import XCTest
import MapKit
@testable import d2d_map_service

class MapControllerTests: XCTestCase {
    func testUpdateRecentSearchesAddsNewQuery() {
        let controller = MapController(region: MKCoordinateRegion())
        controller.updateRecentSearches(with: "123 Main St")
        XCTAssertEqual(controller.recentSearches, ["123 Main St"])
    }

    func testUpdateRecentSearchesDeDupesNormalized() {
        let controller = MapController(region: MKCoordinateRegion())
        controller.recentSearches = ["123 main st"]
        controller.updateRecentSearches(with: " 123 MAIN ST ")
        XCTAssertEqual(controller.recentSearches, [" 123 MAIN ST "])
        XCTAssertEqual(controller.recentSearches.count, 1)
    }

    func testUpdateRecentSearchesKeepsOnlyThree() {
        let controller = MapController(region: MKCoordinateRegion())
        controller.recentSearches = ["One", "Two", "Three"]
        controller.updateRecentSearches(with: "Four")
        XCTAssertEqual(controller.recentSearches, ["Four", "One", "Two"])
    }

    func testUpdateRecentSearchesMovesExistingToFront() {
        let controller = MapController(region: MKCoordinateRegion())
        controller.recentSearches = ["One", "Two", "Three"]
        controller.updateRecentSearches(with: "Two")
        XCTAssertEqual(controller.recentSearches, ["Two", "One", "Three"])
    }
}

