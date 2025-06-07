//
//  Knock.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import SwiftData

/// A model representing a single knock interaction at a prospect's address.
/// Used to track door-to-door activity such as when a user visited and the outcome.
@Model
class Knock {
    
    /// The date and time when the knock occurred.
    var date: Date
    
    /// The status of the knock (e.g., "Answered" or "Not Answered").
    var status: String
    
    /// The latitude coordinate of where the knock occurred.
    var latitude: Double
    
    /// The longitude coordinate of where the knock occurred.
    var longitude: Double
    
    /// The email of the user who performed the knock.
    var userEmail: String

    /// Initializes a new knock record.
    /// - Parameters:
    ///   - date: The date and time of the knock.
    ///   - status: The status of the knock (e.g., "Answered").
    ///   - latitude: The latitude coordinate of the knock.
    ///   - longitude: The longitude coordinate of the knock.
    ///   - userEmail: The email address of the user who performed the knock.
    init(date: Date, status: String, latitude: Double, longitude: Double, userEmail: String) {
        self.date = date
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.userEmail = userEmail
    }
}
