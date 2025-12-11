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
    var knockCount: Int
    var contactEmail: String
    var contactPhone: String
    var notes: [Note]
    var appointments: [Appointment]
    var knockHistory: [Knock]

    /// keep your list flag if you still use it elsewhere
    var list: String

    init(fullName: String,
         address: String,
         count: Int = 0,
         list: String = "Prospects") {
        self.fullName = fullName
        self.address = address
        self.knockCount = count
        self.list = list
        self.contactEmail = ""
        self.contactPhone = ""
        self.notes = []
        self.appointments = []
        self.knockHistory = []
    }
}
