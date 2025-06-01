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
    var knockHistory: [Knock]

    // update your Equatable and Hashable to handle [Knock]
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id &&
        lhs.fullName == rhs.fullName &&
        lhs.address == rhs.address &&
        lhs.count == rhs.count &&
        lhs.list == rhs.list &&
        lhs.knockHistory == rhs.knockHistory  // [Knock] is Equatable now
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fullName)
        hasher.combine(address)
        hasher.combine(count)
        hasher.combine(list)
        hasher.combine(knockHistory)
    }
}
