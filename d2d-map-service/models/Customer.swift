//
//  Customer.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/12/25.
//
import Foundation
import SwiftData

@Model
class Customer {
    var fullName: String
    var address: String
    var count: Int
    var knockHistory: [Knock]
    var notes: [Note] = []
    var contactEmail: String = ""
    var contactPhone: String = ""

    init(fullName: String, address: String, count: Int = 0) {
        self.fullName = fullName
        self.address = address
        self.count = count
        self.knockHistory = []
    }
}

extension Customer {
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}
