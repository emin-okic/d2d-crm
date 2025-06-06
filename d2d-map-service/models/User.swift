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
    var id: UUID

    init(email: String, id: UUID = UUID()) {
        self.email = email
        self.id = id
    }
}
