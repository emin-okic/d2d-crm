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
    var response: String
    var timesHeard: Int

    init(text: String, response: String = "", timesHeard: Int = 0) {
        self.text = text
        self.response = response
        self.timesHeard = timesHeard
    }

    static func == (lhs: Objection, rhs: Objection) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Objection: Identifiable {}
