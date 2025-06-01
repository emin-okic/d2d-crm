//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//
import Foundation

struct Prospect: Identifiable, Equatable, Hashable {
    let id: UUID
    var fullName: String
    var address: String
    var count: Int
    var list: String
    var knockHistory: [(date: Date, status: String)]

    // Manually define Equatable
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id &&
        lhs.fullName == rhs.fullName &&
        lhs.address == rhs.address &&
        lhs.count == rhs.count &&
        lhs.list == rhs.list &&
        lhs.knockHistory.elementsEqual(rhs.knockHistory, by: { $0.date == $1.date && $0.status == $1.status })
    }

    // Manually define Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fullName)
        hasher.combine(address)
        hasher.combine(count)
        hasher.combine(list)
        for record in knockHistory {
            hasher.combine(record.date)
            hasher.combine(record.status)
        }
    }
}
