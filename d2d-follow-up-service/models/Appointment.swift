//
//  Appointment.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import Foundation
import SwiftData

@Model
class Appointment: Identifiable {
    var id: UUID
    var title: String
    var location: String
    var clientName: String
    var date: Date
    var type: String
    var notes: [String] = []
    var createdAt: Date

    @Relationship(inverse: \Prospect.appointments)
    var prospect: Prospect?

    init(
        title: String,
        location: String,
        clientName: String,
        date: Date,
        type: String,
        notes: [String] = [],
        prospect: Prospect? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.location = location
        self.clientName = clientName
        self.date = date
        self.type = type
        self.notes = notes
        self.createdAt = .now
        self.prospect = prospect
    }
}
