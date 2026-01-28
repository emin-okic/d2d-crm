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
    
    var uuid: UUID
    
    var fullName: String
    var address: String
    var knockCount: Int
    var contactEmail: String
    var contactPhone: String
    
    var notes: [Note]
    
    var appointments: [Appointment]
    
    var knockHistory: [Knock]
    
    var emailsSent: [Email]
    
    var phoneCalls: [PhoneCall]

    /// keep your list flag if you still use it elsewhere
    var list: String
    
    /// Stored coordinates for marker annotation generation
    var latitude: Double?
    var longitude: Double?
    
    var isUnqualified: Bool
    
    var orderIndex: Int

    init(
        fullName: String,
         address: String,
         count: Int = 0,
         list: String = "Prospects",
         orderIndex: Int = 0
    ) {
        self.uuid = UUID()
        
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
        
        self.emailsSent = []
        
        self.phoneCalls = []
        
        self.latitude = nil
        self.longitude = nil
        
        self.isUnqualified = false
    }
}

extension Prospect {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
