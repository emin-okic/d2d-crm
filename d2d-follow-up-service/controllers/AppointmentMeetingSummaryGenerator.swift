//
//  AppointmentMeetingSummaryGenerator.swift
//  d2d-studio
//
//  Created by Codex on 8/7/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppointmentMeetingSummaryInput: Sendable {
    let clientName: String
    let appointmentType: String
    let appointmentDate: Date
    let meetingNotes: [String]
}

struct AppointmentMeetingSummaryGenerator {
    func summary(for input: AppointmentMeetingSummaryInput, completedAt: Date) async -> String {
        let fallback = Self.fallbackSummary(for: input, completedAt: completedAt)

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await foundationModelSummary(for: input, completedAt: completedAt) ?? fallback
        }
        #endif

        return fallback
    }

    static func fallbackSummary(for input: AppointmentMeetingSummaryInput, completedAt: Date) -> String {
        let formattedDate = input.appointmentDate.formatted(date: .abbreviated, time: .shortened)
        let completedDate = completedAt.formatted(date: .abbreviated, time: .shortened)
        let trimmedNotes = input.meetingNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard trimmedNotes.isEmpty == false else {
            return "No notes were taken for \(input.clientName)'s meeting on \(completedDate)."
        }

        let interpreted = interpretedFallback(from: trimmedNotes, clientName: input.clientName)
        return "Meeting summary for \(input.clientName) from \(formattedDate): \(interpreted)"
    }

    private static func interpretedFallback(from notes: [String], clientName: String) -> String {
        let combined = notes.joined(separator: " ")
        let lower = combined.lowercased()
        var insights: [String] = []
        var nextStep = "Follow up after the next planned touchpoint."

        if containsAny(lower, ["no money", "can't afford", "cannot afford", "too expensive", "tight", "budget", "broke"]) {
            insights.append("\(clientName) was not ready to buy because money is tight right now.")
            nextStep = "Follow up in a month or two when the budget situation may be clearer."
        }

        if containsAny(lower, ["wife", "husband", "ex", "divorce", "relationship", "family"]) {
            insights.append("There are personal or relationship issues affecting the buying decision.")
        }

        if containsAny(lower, ["interested", "wants", "liked", "needs", "good fit"]) {
            insights.append("There was some buying interest or a potential fit discussed.")
        }

        if containsAny(lower, ["not interested", "no interest", "declined", "said no"]) {
            insights.append("The contact was not interested at this time.")
        }

        if containsAny(lower, ["call", "text", "email"]) {
            nextStep = "Follow up using the requested communication channel."
        }

        if containsAny(lower, ["month", "two months", "next month", "later"]) {
            nextStep = "Follow up on the timeline mentioned during the meeting."
        }

        if insights.isEmpty {
            let cleaned = combined
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            insights.append("Meeting notes were captured and should be reviewed before the next contact: \(cleaned)")
        }

        return (insights + [nextStep]).joined(separator: " ")
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func foundationModelSummary(for input: AppointmentMeetingSummaryInput, completedAt: Date) async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return nil }

        let notes = input.meetingNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .enumerated()
            .map { index, note in "\(index + 1). \(note)" }
            .joined(separator: "\n")

        guard notes.isEmpty == false else {
            return "No notes were taken for \(input.clientName)'s meeting on \(completedAt.formatted(date: .abbreviated, time: .shortened))."
        }

        let instructions = """
        You turn rough door-to-door sales meeting notes into one professional CRM note. Write only the final note. Do not quote profanity, sexual details, insults, gossip, or irrelevant personal details. Convert messy language into useful sales context: the decision blocker, buying signal, objection, next step, and suggested follow-up timing. Preserve meaning, but generalize sensitive personal information. Do not invent facts.
        """

        let prompt = """
        Client: \(input.clientName)
        Appointment type: \(input.appointmentType)
        Scheduled time: \(input.appointmentDate.formatted(date: .abbreviated, time: .shortened))
        Completed time: \(completedAt.formatted(date: .abbreviated, time: .shortened))

        Meeting notes:
        \(notes)

        Create a polished CRM note in 2 to 4 sentences. Start with "Meeting summary:". Example style: if the raw notes say the buyer has no money because of relationship problems, write that the buyer was not able to buy because money is tight due to personal relationship issues, then suggest following up in a month or two.
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return cleaned(response.content)
        } catch {
            return nil
        }
    }
    #endif

    private func cleaned(_ summary: String) -> String? {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return trimmed
    }
}
