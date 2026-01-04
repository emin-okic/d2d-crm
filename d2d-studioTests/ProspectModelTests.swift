//
//  ProspectTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//


import XCTest
import SwiftData
@testable import d2d_studio

final class ProspectModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()

        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none // 🔑 THIS FIXES EVERYTHING
            )

            container = try ModelContainer(
                for: Prospect.self,
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

    func testCreateSingleProspect() throws {
        // Arrange
        let prospect = Prospect(
            fullName: "John Doe",
            address: "123 Main St"
        )

        // Act
        context.insert(prospect)
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<Prospect>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.fullName, "John Doe")
        XCTAssertEqual(results.first?.address, "123 Main St")
        XCTAssertEqual(results.first?.knockCount, 0)
        XCTAssertFalse(results.first?.isUnqualified ?? true)
    }
}
