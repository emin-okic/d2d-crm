//
//  Customer.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/12/25.
//

import Foundation
import SwiftData

@Model
final class Customer: ContactProtocol {
    var fullName: String
    var address: String
    var knockCount: Int
    var contactEmail: String
    var contactPhone: String
    var notes: [Note]
    var appointments: [Appointment]
    var knockHistory: [Knock]

    init(fullName: String,
         address: String,
         count: Int = 0) {
        self.fullName = fullName
        self.address = address
        self.knockCount = count
        self.contactEmail = ""
        self.contactPhone = ""
        self.notes = []
        self.appointments = []
        self.knockHistory = []
    }
}

extension Customer {
    static func fromProspect(_ prospect: Prospect) -> Customer {
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
        return customer
    }
}
