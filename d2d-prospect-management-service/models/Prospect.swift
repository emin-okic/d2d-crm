//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import Foundation
import SwiftData

@Model
final class Prospect: ContactProtocol {
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

    // MARK: — List flag (Prospects | Customers)
    var list: String

    init(
        fullName: String,
        address: String,
        count: Int = 0,
        latitude: Double = 0,
        longitude: Double = 0,
        list: String = "Prospects"
    ) {
        self.fullName = fullName
        self.address = address
        self.count = count
        self.latitude = latitude
        self.longitude = longitude
        self.list = list
        self.contactEmail = ""
        self.contactPhone = ""
        self.notes = []
        self.appointments = []
        self.knockHistory = []
    }
}
