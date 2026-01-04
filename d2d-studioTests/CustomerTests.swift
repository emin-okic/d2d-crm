//
//  CustomerTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import XCTest
import SwiftData
@testable import d2d_studio

final class CustomerTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()

        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none // keeps it fully local
            )

            container = try ModelContainer(
                for: Customer.self,
                configurations: config
            )

            context = ModelContext(container)
        } catch {
            XCTFail("Failed to create SwiftData container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testCreateSingleCustomer() throws {
        // Arrange
        let customer = Customer(
            fullName: "Jane Smith",
            address: "456 Elm St",
            count: 2,
            orderIndex: 1
        )
        customer.contactEmail = "jane@example.com"
        customer.contactPhone = "555-123-4567"

        // Act
        context.insert(customer)
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Customer>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        let saved = results.first
        XCTAssertEqual(saved?.fullName, "Jane Smith")
        XCTAssertEqual(saved?.address, "456 Elm St")
        XCTAssertEqual(saved?.knockCount, 2)
        XCTAssertEqual(saved?.contactEmail, "jane@example.com")
        XCTAssertEqual(saved?.contactPhone, "555-123-4567")
        XCTAssertEqual(saved?.notes.count, 0)
        XCTAssertEqual(saved?.appointments.count, 0)
        XCTAssertEqual(saved?.knockHistory.count, 0)
        XCTAssertNil(saved?.latitude)
        XCTAssertNil(saved?.longitude)
    }
}
