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
        let completedDate = completedAt.formatted(date: .long, time: .shortened)
        let trimmedNotes = input.meetingNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard trimmedNotes.isEmpty == false else {
            return "No notes were taken for \(input.clientName)'s meeting on \(completedDate)."
        }

        return interpretedFallback(
            from: trimmedNotes,
            clientName: input.clientName,
            completedAt: completedAt
        )
    }

    private static func interpretedFallback(from notes: [String], clientName: String, completedAt: Date) -> String {
        let combined = notes.joined(separator: " ")
        let lower = combined.lowercased()
        let explicitTimeline = followUpTimeline(from: lower, completedAt: completedAt)
        let moveAddress = movingAddress(from: combined)
        let moveMonth = moveMonthText(from: lower, completedAt: completedAt)
        let isRelocation = containsAny(lower, ["moving", "moves", "move", "college", "new address", "go to"])
        let displayName = firstName(from: clientName)
        var sentences = ["You met with \(displayName) on \(completedAt.formatted(date: .long, time: .shortened))."]

        if isRelocation {
            sentences.append(relocationSentence(displayName: displayName, lower: lower, moveAddress: moveAddress, moveMonth: moveMonth))
            sentences.append(relocationFollowUpSentence(moveAddress: moveAddress, moveMonth: moveMonth, explicitTimeline: explicitTimeline))
            return sentences.joined(separator: " ")
        }

        if containsAny(lower, ["17", "minor", "too young", "underage"]) {
            sentences.append("\(displayName) was not able to buy because he is not the decision maker.")
        } else if containsAny(lower, ["no money", "can't afford", "cannot afford", "too expensive", "tight", "budget", "broke"]) {
            sentences.append("\(displayName) was not ready to buy because money is tight right now.")
        }

        if lower.contains("mom") || lower.contains("mother") {
            if containsAny(lower, ["cancer", "chemo", "chemotherapy", "treatment"]) {
                sentences.append("His mom is the decision maker and is focused on cancer treatment, so she will not be ready to consider buying yet.")
            } else {
                sentences.append("His mom is the decision maker and needs to be involved before anything can move forward.")
            }
        } else if containsAny(lower, ["wife", "husband", "spouse", "partner"]) {
            sentences.append("A household decision maker needs to be involved before anything can move forward.")
        }

        if containsAny(lower, ["interested", "wants", "liked", "needs", "good fit"]) {
            sentences.append("There may still be a fit if the decision maker is ready later.")
        }

        if containsAny(lower, ["not interested", "no interest", "declined", "said no"]), sentences.count == 1 {
            sentences.append("\(displayName) was not interested at this time.")
        }

        if containsAny(lower, ["moving", "moves", "move"]) {
            if let moveAddress, let moveMonth {
                sentences.append("\(displayName) is moving to \(moveAddress) around \(moveMonth).")
            } else if let moveAddress {
                sentences.append("\(displayName) is moving to \(moveAddress).")
            } else if let moveMonth {
                sentences.append("\(displayName) is moving around \(moveMonth).")
            }
        }

        if sentences.count == 1 {
            sentences.append("Review the meeting notes before the next contact: \(cleanRawNote(combined))")
        }

        if let explicitTimeline {
            sentences.append(explicitTimeline)
        } else if moveMonth != nil {
            sentences.append("Follow up then.")
        } else {
            sentences.append("Follow up after the next planned touchpoint.")
        }
        return sentences.joined(separator: " ")
    }

    private static func relocationSentence(displayName: String, lower: String, moveAddress: String?, moveMonth: String?) -> String {
        if lower.contains("college") {
            if let moveAddress, let moveMonth {
                return "Not a fit right now because \(displayName) is leaving for college and will need internet at \(moveAddress) around \(moveMonth)."
            }

            return "Not a fit right now because \(displayName) is leaving for college."
        }

        if let moveAddress, let moveMonth {
            return "\(displayName) is moving to \(moveAddress) around \(moveMonth)."
        }

        if let moveAddress {
            return "\(displayName) is moving to \(moveAddress)."
        }

        if let moveMonth {
            return "\(displayName) is moving around \(moveMonth)."
        }

        return "Not a fit right now because \(displayName) is relocating."
    }

    private static func relocationFollowUpSentence(moveAddress: String?, moveMonth: String?, explicitTimeline: String?) -> String {
        if let moveAddress, let moveMonth {
            return "Follow up at \(moveAddress) at the start of \(moveMonth)."
        }

        if let moveAddress {
            return "Follow up at \(moveAddress)."
        }

        if let explicitTimeline {
            return explicitTimeline
        }

        return "Follow up after the move."
    }

    private static func followUpTimeline(from text: String, completedAt: Date) -> String? {
        if let range = firstMatch(in: text, pattern: #"follow\s*up\s*in\s*(\d+)\s*[-–]\s*(\d+)\s*(month|months|week|weeks)"#),
           let low = Int(range[1]),
           let high = Int(range[2]) {
            let unit = range[3].hasPrefix("week") ? Calendar.Component.weekOfYear : .month
            let calendarWindow = calendarWindowText(from: completedAt, low: low, high: high, unit: unit)
            return "Follow up in \(low)-\(high) \(range[3])\(calendarWindow)."
        }

        if let single = firstMatch(in: text, pattern: #"follow\s*up\s*in\s*(\d+)\s*(month|months|week|weeks)"#),
           let amount = Int(single[1]) {
            let unit = single[2].hasPrefix("week") ? Calendar.Component.weekOfYear : .month
            return followUpSentence(amount: amount, unitText: single[2], completedAt: completedAt, unit: unit)
        }

        if text.contains("next month") {
            return "Follow up next month\(calendarWindowText(from: completedAt, low: 1, high: 1, unit: .month))."
        }

        if let implied = firstMatch(in: text, pattern: #"\bin\s*(\d+)\s*(month|months|week|weeks)\b"#),
           let amount = Int(implied[1]) {
            let unit = implied[2].hasPrefix("week") ? Calendar.Component.weekOfYear : .month
            return followUpSentence(amount: amount, unitText: implied[2], completedAt: completedAt, unit: unit)
        }

        return nil
    }

    private static func movingAddress(from text: String) -> String? {
        let patterns = [
            #"\bto\s+([0-9][A-Za-z0-9 .,#-]+?\s+[A-Z]{2}\s+\d{5})"#,
            #"\bat\s+([0-9][A-Za-z0-9 .,#-]+?\s+[A-Z]{2}\s+\d{5})"#
        ]

        for pattern in patterns {
            if let match = firstMatch(in: text, pattern: pattern), match.count > 1 {
                return cleanAddress(match[1])
            }
        }

        return nil
    }

    private static func moveMonthText(from text: String, completedAt: Date) -> String? {
        if let implied = firstMatch(in: text, pattern: #"\bin\s*(\d+)\s*(month|months|week|weeks)\b"#),
           let amount = Int(implied[1]) {
            let unit = implied[2].hasPrefix("week") ? Calendar.Component.weekOfYear : .month
            return targetMonthText(amount: amount, completedAt: completedAt, unit: unit)
        }

        return nil
    }

    private static func cleanAddress(_ address: String) -> String {
        address
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func followUpSentence(amount: Int, unitText: String, completedAt: Date, unit: Calendar.Component) -> String {
        guard let targetMonth = targetMonthText(amount: amount, completedAt: completedAt, unit: unit) else {
            return "Follow up in \(amount) \(unitText)."
        }

        return "Follow up in \(targetMonth)."
    }

    private static func targetMonthText(amount: Int, completedAt: Date, unit: Calendar.Component) -> String? {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: unit, value: amount, to: completedAt) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: targetDate)
    }

    private static func calendarWindowText(from date: Date, low: Int, high: Int, unit: Calendar.Component) -> String {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: unit, value: low, to: date) else { return "" }
        let endDate = calendar.date(byAdding: unit, value: high, to: date) ?? startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        if start == end {
            return ", around \(start)"
        }

        return ", around \(start)-\(end)"
    }

    private static func firstMatch(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }

        return (0..<match.numberOfRanges).compactMap { index in
            guard let swiftRange = Range(match.range(at: index), in: text) else { return nil }
            return String(text[swiftRange])
        }
    }

    private static func monthYear(from text: String) -> String? {
        firstMatch(in: text, pattern: #"[A-Z][a-z]+\s+\d{4}"#)?.first
    }

    private static func firstName(from fullName: String) -> String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    private static func cleanRawNote(_ note: String) -> String {
        note
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func foundationModelSummary(for input: AppointmentMeetingSummaryInput, completedAt: Date) async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return nil }

        let trimmedNotes = input.meetingNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        let notes = trimmedNotes
            .enumerated()
            .map { index, note in "\(index + 1). \(note)" }
            .joined(separator: "\n")
        let combinedNotes = trimmedNotes.joined(separator: " ")
        let requiredTimeline = Self.followUpTimeline(
            from: combinedNotes.lowercased(),
            completedAt: completedAt
        )
        let moveAddress = Self.movingAddress(from: combinedNotes)
        let moveMonth = Self.moveMonthText(from: combinedNotes.lowercased(), completedAt: completedAt)
        let isRelocation = Self.containsAny(combinedNotes.lowercased(), ["moving", "moves", "move", "college", "new address", "go to"])

        guard notes.isEmpty == false else {
            return "No notes were taken for \(input.clientName)'s meeting on \(completedAt.formatted(date: .abbreviated, time: .shortened))."
        }

        let instructions = """
        You turn rough door-to-door sales meeting notes into one professional CRM note. Write only the final note. Use this structure: first sentence says who the rep met with and when; next sentence explains the real buying blocker or decision maker issue; final sentence gives the exact follow-up date or window. Do not add a "Meeting summary:" prefix. Do not quote profanity, sexual details, insults, gossip, manipulative sales comments, or irrelevant personal details. Convert messy language into useful sales context. Preserve every explicit follow-up interval or date. Never replace a concrete timeline with vague wording like "the timeline mentioned". Do not invent facts.
        """

        let prompt = """
        Client full name: \(input.clientName)
        Client first name: \(Self.firstName(from: input.clientName))
        Appointment type: \(input.appointmentType)
        Scheduled time: \(input.appointmentDate.formatted(date: .abbreviated, time: .shortened))
        Completed time: \(completedAt.formatted(date: .long, time: .shortened))

        Meeting notes:
        \(notes)

        Required follow-up timing, if any:
        \(requiredTimeline ?? "None")

        Move address, if any:
        \(moveAddress ?? "None")

        Move timing, if any:
        \(moveMonth ?? "None")

        Relocation or college situation:
        \(isRelocation ? "Yes" : "No")

        Create a polished CRM note in 2 to 3 sentences. Sentence 1 must start with "You met with" and include the completed time. If this is a relocation or college situation, do not write generic buying-interest language. Say it is not a fit right now because the client is moving or leaving for college. If move address and move timing are present, include that exact address and month. If required follow-up timing is not None, the final sentence must use that exact timing or a more specific calendar date from it. For notes about a minor, parent, cancer treatment, or chemo, summarize professionally as a decision maker and timing blocker. Example college style: "You met with David on August 7, 2026 at 7:11 PM. Not a fit right now because David is leaving for college and will need internet at 1244 Ames St Ames IA 50014 around September 2026. Follow up at 1244 Ames St Ames IA 50014 at the start of September 2026." Example moving style: "You met with Kate on August 7, 2026 at 7:05 PM. Kate is moving to 10320 Norfolk Dr Los Angeles CA 90066 around October 2026. Follow up then."
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return cleaned(
                response.content,
                requiredTimeline: requiredTimeline,
                moveAddress: moveAddress,
                moveMonth: moveMonth
            )
        } catch {
            return nil
        }
    }
    #endif

    private func cleaned(
        _ summary: String,
        requiredTimeline: String?,
        moveAddress: String?,
        moveMonth: String?
    ) -> String? {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let lower = trimmed.lowercased()
        guard lower.contains("timeline mentioned") == false else { return nil }

        if let requiredTimeline {
            let requiredMonth = Self.monthYear(from: requiredTimeline)
            if lower.contains(requiredTimeline.lowercased()) == false,
               requiredMonth.map({ lower.contains($0.lowercased()) }) != true {
                return nil
            }
        }

        if let moveAddress, lower.contains(moveAddress.lowercased()) == false {
            return nil
        }

        if let moveMonth, lower.contains(moveMonth.lowercased()) == false {
            return nil
        }

        return trimmed
    }
}
