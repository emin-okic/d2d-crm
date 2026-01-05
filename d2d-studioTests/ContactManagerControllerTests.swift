//
//  ContactManagerControllerTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//


import XCTest
import CoreLocation
@testable import d2d_studio

@MainActor
final class ContactManagerControllerTests: XCTestCase {

    func testFetchNextSuggestedNeighbor() async {
        let controller = ContactManagerController()

        // Inject mock closure
        controller.geocodeNeighborClosure = { address, _, completion in
            completion("123 Test Street", CLLocationCoordinate2D(latitude: 10, longitude: 20))
        }

        // Customer list
        let customer = Customer(fullName: "John Doe", address: "123 Main St")
        let customers = [customer]

        // No existing prospects
        let existingProspects: [Prospect] = []

        // Act
        await controller.fetchNextSuggestedNeighbor(from: customers, existingProspects: existingProspects)

        // Assert
        let suggested = controller.suggestedProspect
        XCTAssertNotNil(suggested)
        XCTAssertEqual(suggested?.address, "123 Test Street")
        XCTAssertEqual(suggested?.latitude, 10)
        XCTAssertEqual(suggested?.longitude, 20)
        XCTAssertEqual(suggested?.fullName, "Suggested Neighbor")
    }

    func testFetchNextSuggestedNeighborWithIncrement() async {
        let controller = ContactManagerController()

        // Inject mock closure that simulates the real offset logic
        controller.geocodeNeighborClosure = { address, existingProspects, completion in
            // Extract base number from address
            let components = address.components(separatedBy: " ")
            guard let first = components.first, let baseNumber = Int(first) else {
                completion(nil, nil)
                return
            }
            
            let streetRemainder = components.dropFirst().joined(separator: " ")
            
            // Find the first available offset that doesn't exist yet
            var offset = 1
            var newAddress = "\(baseNumber + offset) \(streetRemainder)"
            let lowercasedExisting = existingProspects.map { $0.address.lowercased() }
            while lowercasedExisting.contains(newAddress.lowercased()) && offset < 10 {
                offset += 1
                newAddress = "\(baseNumber + offset) \(streetRemainder)"
            }
            
            completion(newAddress, CLLocationCoordinate2D(latitude: 10, longitude: 20))
        }

        // Customer list
        let customer = Customer(fullName: "John Doe", address: "12331 Southport Pkwy La Vista")
        let customers = [customer]

        // Existing prospect at 12331 (so next should be 12332)
        let existing = Prospect(fullName: "Someone", address: "12331 Southport Pkwy La Vista")
        let existingProspects = [existing]

        // Act
        await controller.fetchNextSuggestedNeighbor(from: customers, existingProspects: existingProspects)

        // Assert
        let suggested = controller.suggestedProspect
        XCTAssertNotNil(suggested)
        XCTAssertEqual(suggested?.address, "12332 Southport Pkwy La Vista")
        XCTAssertEqual(suggested?.latitude, 10)
        XCTAssertEqual(suggested?.longitude, 20)
        XCTAssertEqual(suggested?.fullName, "Suggested Neighbor")
    }
}
