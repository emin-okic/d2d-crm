//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//
import Foundation

struct Prospect: Identifiable, Hashable {
    let id: UUID
    var fullName: String
    var address: String
    var count: Int
    var list: String
    var knockHistory: [String]  // e.g., ["Answered", "Not Answered", ...]
}
