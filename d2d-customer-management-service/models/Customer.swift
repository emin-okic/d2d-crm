//
//  Customer.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/12/25.
//

import Foundation
import SwiftData
import CoreLocation

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
    
    /// Stored coordinates for marker annotation generation
    var latitude: Double?
    var longitude: Double?

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
        
        self.latitude = nil
        self.longitude = nil
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
        
        // 🔑 Preserve spatial identity
        customer.latitude = prospect.latitude
        customer.longitude = prospect.longitude
        
        // Return the customer object that was convertred from the prospect object
        return customer
    }
}

extension Customer {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
