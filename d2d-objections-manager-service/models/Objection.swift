//
//  Objection.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import Foundation
import SwiftData

@Model
final class Objection: Hashable {
    var text: String
    var response: String               // primary / currently displayed response
    var extraResponses: [String] = []  // all generated + practiced responses
    var timesHeard: Int
    var practiceResponseCount: Int = 0

    static let levelResponseThresholds = [0, 1, 3, 6, 11]
    static let maximumLevel = levelResponseThresholds.count

    init(
        text: String,
        response: String = "",
        timesHeard: Int = 0,
        practiceResponseCount: Int = 0
    ) {
        self.text = text
        self.response = response
        if !response.isEmpty {
            self.extraResponses = [response]
        }
        self.timesHeard = timesHeard
        self.practiceResponseCount = practiceResponseCount
    }

    var confidenceLevel: Int {
        let completedThresholds = Self.levelResponseThresholds.prefix {
            practiceResponseCount >= $0
        }

        return max(1, completedThresholds.count)
    }

    var responsesUntilNextLevel: Int? {
        guard confidenceLevel < Self.maximumLevel else { return nil }
        let nextThreshold = Self.levelResponseThresholds[confidenceLevel]
        return max(0, nextThreshold - practiceResponseCount)
    }

    var levelProgress: Double {
        guard confidenceLevel < Self.maximumLevel else { return 1 }

        let currentThreshold = Self.levelResponseThresholds[confidenceLevel - 1]
        let nextThreshold = Self.levelResponseThresholds[confidenceLevel]
        let responsesInLevel = practiceResponseCount - currentThreshold
        let responsesRequired = nextThreshold - currentThreshold

        return Double(responsesInLevel) / Double(responsesRequired)
    }
    
    // Add a response if it doesn't exist
    func addResponse(_ newResponse: String) {
        if !extraResponses.contains(newResponse) {
            extraResponses.append(newResponse)
        }
    }

    @discardableResult
    func recordPracticeResponse(_ newResponse: String) -> Bool {
        let trimmedResponse = newResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedResponse.isEmpty else { return false }

        addResponse(trimmedResponse)
        practiceResponseCount += 1
        rotateResponse()
        return true
    }
    
    // Pick a random response to display
    func rotateResponse() {
        guard !extraResponses.isEmpty else { return }
        response = extraResponses.randomElement()!
    }

    static func == (lhs: Objection, rhs: Objection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Objection: Identifiable {}
