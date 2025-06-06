//
//  Knock.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import SwiftData

@Model
class Knock {
    var date: Date
    var status: String
    var latitude: Double
    var longitude: Double
    var userEmail: String  // New field

    init(date: Date, status: String, latitude: Double, longitude: Double, userEmail: String) {
        self.date = date
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.userEmail = userEmail
    }
}
