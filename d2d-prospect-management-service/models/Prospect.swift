//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Prospect: ContactProtocol {
    var fullName: String
    var address: String
    var knockCount: Int
    var contactEmail: String
    var contactPhone: String
    var notes: [Note]
    var appointments: [Appointment]
    var knockHistory: [Knock]

    /// keep your list flag if you still use it elsewhere
    var list: String
    
    /// Stored coordinates for marker annotation generation
    var latitude: Double?
    var longitude: Double?
    
    var isUnqualified: Bool
    
    var orderIndex: Int
    
    @Relationship var demographics: Demographics?

    init(
        fullName: String,
         address: String,
         count: Int = 0,
         list: String = "Prospects",
         orderIndex: Int = 0
    ) {
        self.fullName = fullName
        self.address = address
        self.knockCount = count
        self.list = list
        self.orderIndex = orderIndex
        self.contactEmail = ""
        self.contactPhone = ""
        self.notes = []
        self.appointments = []
        self.knockHistory = []
        
        self.latitude = nil
        self.longitude = nil
        
        self.isUnqualified = false
        
        self.demographics = Demographics()
    }
}

extension Prospect {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
