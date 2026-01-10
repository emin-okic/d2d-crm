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
    
    var orderIndex: Int

    init(
        fullName: String,
         address: String,
         count: Int = 0,
        orderIndex: Int = 0
    ) {
        self.fullName = fullName
        self.address = address
        self.knockCount = count
        self.orderIndex = orderIndex
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
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension Customer {
    func asProspectCopy() -> Prospect {
        let p = Prospect(
            fullName: self.fullName,
            address: self.address,
            count: self.knockCount,
            list: "Customers"
        )
        p.contactPhone = self.contactPhone
        p.contactEmail = self.contactEmail
        p.notes = self.notes
        p.appointments = self.appointments
        p.knockHistory = self.knockHistory
        p.latitude = self.latitude
        p.longitude = self.longitude
        return p
    }
}
