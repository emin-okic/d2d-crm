//
//  Prospects.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import Foundation
import SwiftData

/// A model representing a door-to-door sales prospect.
/// Each prospect contains personal and tracking information such as name, address, interaction count, and associated knocks.
@Model
class Prospect {
    
    /// The full name of the prospect.
    var fullName: String

    /// The address of the prospect.
    var address: String

    /// A counter representing how many times this prospect has been interacted with.
    var count: Int

    /// The category list the prospect belongs to (e.g., "Prospects", "Customers").
    var list: String

    /// A history of knock attempts related to this prospect.
    var knockHistory: [Knock]
    
    /// The email of the user who created or owns this prospect.
    var userEmail: String
    
    // Add this to your Prospect class:
    var notes: [Note] = []
    
    var contactEmail: String = ""
    var contactPhone: String = ""

    /// Initializes a new prospect.
    /// - Parameters:
    ///   - fullName: The prospect’s full name.
    ///   - address: The physical address of the prospect.
    ///   - count: The initial count of knock attempts. Defaults to 0.
    ///   - list: The list name to categorize this prospect. Defaults to "Prospects".
    ///   - userEmail: The email address of the associated user.
    init(fullName: String, address: String, count: Int = 0, list: String = "Prospects", userEmail: String) {
        self.fullName = fullName
        self.address = address
        self.count = count
        self.list = list
        self.knockHistory = []
        self.userEmail = userEmail
    }
}

extension Prospect {
    /// Returns the knock history sorted in descending order by date (most recent first).
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}
