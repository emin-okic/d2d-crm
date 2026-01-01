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

    init(
        text: String,
        response: String = "",
        timesHeard: Int = 0
    ) {
        self.text = response
        self.response = response
        if !response.isEmpty {
            self.extraResponses = [response]
        }
        self.timesHeard = timesHeard
    }
    
    // Add a response if it doesn't exist
    func addResponse(_ newResponse: String) {
        if !extraResponses.contains(newResponse) {
            extraResponses.append(newResponse)
        }
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
