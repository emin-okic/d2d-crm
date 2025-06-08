//
//  User.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import Foundation
import SwiftData

/// A data model representing a user in the D2D CRM app.
///
/// This model is used for local authentication and user-specific data separation.
/// Each user has an email, password, and a unique identifier.
///
/// This is stored using SwiftData and queried during login or account creation flows.
@Model
class User {

    /// The user's email address (serves as the username for login).
    var email: String

    /// The user's password (stored in plain text for simplicity—should be hashed in production).
    var password: String

    /// A unique identifier for the user (generated automatically by default).
    var id: UUID
    
    var isVerified: Bool

    /// Initializes a new `User` instance.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - id: Optional UUID; defaults to a newly generated UUID.
    init(email: String, password: String, isVerified: Bool = false, id: UUID = UUID()) {
        self.email = email
        self.password = password
        self.id = id
        self.isVerified = isVerified
    }
}
