//
//  Trip.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//

import Foundation
import SwiftData

@Model
class Trip {
    var id: UUID
    var startAddress: String
    var endAddress: String
    var miles: Double
    var date: Date

    init(startAddress: String, endAddress: String, miles: Double, date: Date = .now, id: UUID = UUID()) {
        self.id = id
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.miles = miles
        self.date = date
    }
}
