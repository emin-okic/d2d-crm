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
    var meetingNotes: [String] = []
    var isCompleted: Bool = false
    var completedAt: Date?
    var meetingSummary: String?
    var summaryAddedAt: Date?
    var createdAt: Date

    @Relationship(inverse: \Prospect.appointments)
    var prospect: Prospect?

    @Relationship(inverse: \Customer.appointments)
    var customer: Customer?

    init(
        title: String,
        location: String,
        clientName: String,
        date: Date,
        type: String,
        notes: [String] = [],
        meetingNotes: [String] = [],
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        meetingSummary: String? = nil,
        summaryAddedAt: Date? = nil,
        prospect: Prospect? = nil,
        customer: Customer? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.location = location
        self.clientName = clientName
        self.date = date
        self.type = type
        self.notes = notes
        self.meetingNotes = meetingNotes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.meetingSummary = meetingSummary
        self.summaryAddedAt = summaryAddedAt
        self.createdAt = .now
        self.prospect = prospect
        self.customer = customer
    }
}

enum AppointmentStatus: Equatable {
    case upcoming
    case missed
    case completed
}

extension Appointment {
    var isClosed: Bool {
        isCompleted
    }

    var wasAutomaticallyCompletedWhenPast: Bool {
        isCompleted && completedAt == date
    }

    func status(at now: Date = Date()) -> AppointmentStatus {
        if isCompleted {
            return .completed
        }

        return date < now ? .missed : .upcoming
    }

    func isUpcomingBucket(now: Date = Date()) -> Bool {
        status(at: now) == .upcoming
    }

    func isPastBucket(now: Date = Date()) -> Bool {
        status(at: now) != .upcoming
    }

    func canReopen(now: Date = Date()) -> Bool {
        isCompleted && date >= now
    }
}
