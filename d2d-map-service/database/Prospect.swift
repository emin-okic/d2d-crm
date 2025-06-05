//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//
import Foundation
import SwiftData

@Model
class Prospect {
    var fullName: String
    var address: String
    var count: Int
    var list: String
    var knockHistory: [Knock]

    init(fullName: String, address: String, count: Int = 0, list: String = "Prospects") {
        self.fullName = fullName
        self.address = address
        self.count = count
        self.list = list
        self.knockHistory = []
    }
}

extension Prospect {
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}
