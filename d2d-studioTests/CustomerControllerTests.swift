//
//  CustomerControllerTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import XCTest
import SwiftData
@testable import d2d_studio

@MainActor
final class CustomerControllerTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var controller: CustomerController!

    override func setUp() {
        super.setUp()

        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )

            container = try ModelContainer(
                for: Prospect.self,
                     Customer.self,
                     Note.self,
                     Appointment.self,
                     Knock.self,
                configurations: config
            )

            context = ModelContext(container)
            controller = CustomerController(modelContext: context)
        } catch {
            XCTFail("Failed to create SwiftData container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        context = nil
        controller = nil
        super.tearDown()
    }

    func testConvertProspectToCustomer() async throws {
        // Arrange: create a sample Prospect
        let prospect = Prospect(
            fullName: "Alice Johnson",
            address: "789 Oak St",
            count: 3
        )
        prospect.contactEmail = "alice@example.com"
        prospect.contactPhone = "555-987-6543"

        // Add sample note, knock, appointment
        let note = Note(content: "Initial prospect note", prospect: prospect)
        prospect.notes.append(note)

        let knock = Knock(date: .now, status: "Answered", latitude: 40.0, longitude: -90.0)
        prospect.knockHistory.append(knock)

        let appt = Appointment(title: "Meeting", location: "Office", clientName: "Alice Johnson", date: .now, type: "Intro", prospect: prospect)
        prospect.appointments.append(appt)

        context.insert(prospect)
        try context.save()

        // Act: convert Prospect to Customer
        let customer = controller.fromProspect(prospect)

        try context.save()

        // Assert: customer data matches prospect
        let fetchDescriptor = FetchDescriptor<Customer>()
        let customers = try context.fetch(fetchDescriptor)

        XCTAssertEqual(customers.count, 1)
        let savedCustomer = customers.first

        XCTAssertEqual(savedCustomer?.fullName, prospect.fullName)
        XCTAssertEqual(savedCustomer?.address, prospect.address)
        XCTAssertEqual(savedCustomer?.knockCount, prospect.knockCount)
        XCTAssertEqual(savedCustomer?.contactEmail, prospect.contactEmail)
        XCTAssertEqual(savedCustomer?.contactPhone, prospect.contactPhone)

        XCTAssertEqual(savedCustomer?.notes.count, 1)
        XCTAssertEqual(savedCustomer?.notes.first?.content, "Initial prospect note")

        XCTAssertEqual(savedCustomer?.knockHistory.count, 1)
        XCTAssertEqual(savedCustomer?.knockHistory.first?.status, "Answered")
        XCTAssertEqual(savedCustomer?.knockHistory.first?.latitude, 40.0)
        XCTAssertEqual(savedCustomer?.knockHistory.first?.longitude, -90.0)

        XCTAssertEqual(savedCustomer?.appointments.count, 1)
        XCTAssertEqual(savedCustomer?.appointments.first?.title, "Meeting")
    }
}
