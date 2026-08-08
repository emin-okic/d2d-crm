//
//  AppointmentNotesController.swift
//  d2d-studio
//
//  Created by Codex on 8/7/26.
//

import Foundation
import SwiftData

@MainActor
struct AppointmentNotesController {
    let modelContext: ModelContext
    private let summaryGenerator = AppointmentMeetingSummaryGenerator()

    func addMeetingNote(_ content: String, to appointment: Appointment) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, appointment.isClosed == false else { return }

        appointment.meetingNotes.append(trimmed)
        try? modelContext.save()
    }

    func completeIfNeeded(_ appointment: Appointment, at completedAt: Date = Date()) async {
        if appointment.isCompleted == false {
            appointment.isCompleted = true
            appointment.completedAt = completedAt
        }

        await addSummaryToContactNotesIfNeeded(for: appointment, completedAt: completedAt)
        try? modelContext.save()
    }

    func closePastAppointmentIfNeeded(_ appointment: Appointment, now: Date = Date()) async {
        guard appointment.date < now else { return }
        await completeIfNeeded(appointment, at: appointment.completedAt ?? appointment.date)
    }

    func reopenIfAllowed(_ appointment: Appointment, now: Date = Date()) {
        guard appointment.canReopen(now: now) else { return }

        removeSummaryFromContactNotesIfNeeded(for: appointment)
        appointment.isCompleted = false
        appointment.completedAt = nil
        appointment.meetingSummary = nil
        appointment.summaryAddedAt = nil
        try? modelContext.save()
    }

    private func addSummaryToContactNotesIfNeeded(for appointment: Appointment, completedAt: Date) async {
        guard appointment.summaryAddedAt == nil else { return }

        let summaryInput = AppointmentMeetingSummaryInput(
            clientName: appointment.clientName,
            appointmentType: appointment.type,
            appointmentDate: appointment.date,
            meetingNotes: appointment.meetingNotes
        )
        let summary = await summaryGenerator.summary(for: summaryInput, completedAt: completedAt)
        appointment.meetingSummary = summary
        appointment.summaryAddedAt = Date()

        let contactNote = Note(content: summary, date: completedAt, prospect: appointment.prospect)

        if let prospect = appointment.prospect {
            prospect.notes.append(contactNote)
        } else if let customer = appointment.customer {
            customer.notes.append(contactNote)
        }
    }

    private func removeSummaryFromContactNotesIfNeeded(for appointment: Appointment) {
        guard let summary = appointment.meetingSummary else { return }

        if let prospect = appointment.prospect {
            removeSummary(summary, from: &prospect.notes)
        } else if let customer = appointment.customer {
            removeSummary(summary, from: &customer.notes)
        }
    }

    private func removeSummary(_ summary: String, from notes: inout [Note]) {
        let matchingNotes = notes.filter { $0.content == summary }
        notes.removeAll { $0.content == summary }
        matchingNotes.forEach { modelContext.delete($0) }
    }
}
