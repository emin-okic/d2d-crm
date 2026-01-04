//
//  CustomerController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import Foundation
import SwiftData
import CoreLocation

@MainActor
final class CustomerController {

    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Conversion

    func fromProspect(_ prospect: Prospect) -> Customer {
        let customer = Customer(
            fullName: prospect.fullName,
            address: prospect.address,
            count: prospect.knockCount
        )
        customer.contactPhone = prospect.contactPhone
        customer.contactEmail = prospect.contactEmail
        customer.notes = prospect.notes
        customer.appointments = prospect.appointments
        customer.knockHistory = prospect.knockHistory

        // Preserve spatial identity
        customer.latitude = prospect.latitude
        customer.longitude = prospect.longitude

        // Insert into SwiftData context if needed
        modelContext.insert(customer)

        return customer
    }
}
