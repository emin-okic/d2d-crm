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

    func addMeetingNote(_ content: String, to appointment: Appointment) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, appointment.isClosed == false else { return }

        appointment.meetingNotes.append(trimmed)
        try? modelContext.save()
    }

    func completeIfNeeded(_ appointment: Appointment, at completedAt: Date = Date()) {
        if appointment.isCompleted == false {
            appointment.isCompleted = true
            appointment.completedAt = completedAt
        }

        addSummaryToContactNotesIfNeeded(for: appointment, completedAt: completedAt)
        try? modelContext.save()
    }

    func closePastAppointmentIfNeeded(_ appointment: Appointment, now: Date = Date()) {
        guard appointment.date < now else { return }
        completeIfNeeded(appointment, at: appointment.completedAt ?? appointment.date)
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

    private func addSummaryToContactNotesIfNeeded(for appointment: Appointment, completedAt: Date) {
        guard appointment.summaryAddedAt == nil else { return }

        let summary = Self.summary(for: appointment, completedAt: completedAt)
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

    static func summary(for appointment: Appointment, completedAt: Date) -> String {
        let formattedDate = appointment.date.formatted(date: .abbreviated, time: .shortened)
        let completedDate = completedAt.formatted(date: .abbreviated, time: .shortened)
        let trimmedNotes = appointment.meetingNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard trimmedNotes.isEmpty == false else {
            return "Meeting completed for \(appointment.clientName) on \(completedDate). No meeting notes were recorded."
        }

        let condensed = trimmedNotes
            .prefix(4)
            .map { summarizeLine($0) }
            .joined(separator: " ")

        return "Meeting summary for \(appointment.clientName) from \(formattedDate): \(condensed)"
    }

    private static func summarizeLine(_ line: String) -> String {
        let normalized = line
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count > 180 else { return normalized }

        let endIndex = normalized.index(normalized.startIndex, offsetBy: 180)
        return String(normalized[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
