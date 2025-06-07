//
//  User.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import Foundation
import SwiftData

@Model
class User {
    var email: String
    var password: String  // ✅ Add this
    var id: UUID

    init(email: String, password: String, id: UUID = UUID()) {
        self.email = email
        self.password = password
        self.id = id
    }
}
