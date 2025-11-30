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
    var count: Int
    
    // MARK: — Contact
    var contactEmail: String
    var contactPhone: String

    // MARK: — Notes & appointments
    var notes: [Note]
    var appointments: [Appointment]

    // MARK: — Knock history
    var knockHistory: [Knock]

    // MARK: — Critical for mapping (NEW)
    var latitude: Double
    var longitude: Double

    init(
        fullName: String,
        address: String,
        count: Int = 0,
        latitude: Double = 0,
        longitude: Double = 0
    ) {
        self.fullName = fullName
        self.address = address
        self.count = count
        self.latitude = latitude
        self.longitude = longitude
        self.contactEmail = ""
        self.contactPhone = ""
        self.notes = []
        self.appointments = []
        self.knockHistory = []
    }
}

extension Customer {
    static func fromProspect(_ prospect: Prospect) -> Customer {
        let c = Customer(
            fullName: prospect.fullName,
            address: prospect.address,
            count: prospect.count,
            latitude: prospect.latitude,
            longitude: prospect.longitude
        )
        c.contactPhone = prospect.contactPhone
        c.contactEmail = prospect.contactEmail
        c.notes = prospect.notes
        c.appointments = prospect.appointments
        c.knockHistory = prospect.knockHistory
        return c
    }
}
