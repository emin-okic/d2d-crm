//
//  SuggestedFollowUpNoteGenerator.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/26/25.
//
import Foundation

struct SuggestedFollowUpNoteGenerator {

    // MARK: - Public API

    static func generate(
        prospect: Prospect,
        objection: Objection?,
        followUpDate: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a 'on' EEEE MMMM d, yyyy"
        let dateString = formatter.string(from: followUpDate)

        let name = prospect.fullName.isEmpty
            ? "New Prospect"
            : prospect.fullName

        guard let objectionText = objection?.text,
              !objectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return "\(name) asked to follow up later. There's a follow up set at \(dateString)."
        }

        let category = classify(objectionText)
        let sentence = buildSentence(
            category: category,
            prospectName: name,
            objectionText: objectionText
        )

        return "\(sentence) There's a follow up set at \(dateString)."
    }

    // MARK: - Classification

    private static func classify(_ text: String) -> ObjectionCategory {
        let lower = text.lowercased()

        // Price / value
        if lower.contains("expensive") ||
           lower.contains("afford") ||
           lower.contains("money") ||
           lower.contains("price") {
            return .price
        }

        // Competitor
        if lower.contains("competitor") ||
           lower.contains("cheaper") ||
           lower.contains("another provider") ||
           lower.contains("other company") {
            return .competitor
        }

        // Timing
        if lower.contains("busy") ||
           lower.contains("not a good time") ||
           lower.contains("later") ||
           lower.contains("next quarter") {
            return .timing
        }

        // Authority / decision maker
        if lower.contains("spouse") ||
           lower.contains("partner") ||
           lower.contains("decision") ||
           lower.contains("talk to") {
            return .authority
        }

        // Trust
        if lower.contains("never heard") ||
           lower.contains("don’t trust") ||
           lower.contains("don't trust") ||
           lower.contains("not comfortable") {
            return .trust
        }

        // Need / fit
        if lower.contains("don't need") ||
           lower.contains("do not need") ||
           lower.contains("happy with") ||
           lower.contains("already have") {
            return .need
        }

        // Logistics
        if lower.contains("not the decision maker") ||
           lower.contains("where did you get") {
            return .logistics
        }

        return .generic
    }

    // MARK: - Sentence Construction

    private static func buildSentence(
        category: ObjectionCategory,
        prospectName: String,
        objectionText: String
    ) -> String {

        switch category {

        case .price:
            return "\(prospectName) doesn’t feel the pricing works for them right now."

        case .competitor:
            return "\(prospectName) prefers another provider because they feel the competitor is cheaper."

        case .timing:
            return "\(prospectName) wasn’t available to move forward at the time."

        case .authority:
            return "\(prospectName) needs to speak with another decision-maker before moving forward."

        case .trust:
            return "\(prospectName) wasn’t comfortable moving forward during the initial visit."

        case .need:
            return "\(prospectName) doesn’t feel this is a good fit for their needs right now."

        case .logistics:
            return "\(prospectName) wasn’t the appropriate contact to move forward at this time."

        case .generic:
            return "\(prospectName) had concerns and asked to follow up later."
        }
    }
}
