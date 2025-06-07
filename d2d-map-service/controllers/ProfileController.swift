//
//  ProfileController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

/// A utility struct that provides analytics and summaries based on a collection of `Prospect` objects.
///
/// These functions support filtering by `userEmail` to isolate data per user when needed.
struct ProfileController {
    
    /// Computes the total number of knocks recorded across all prospects.
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    ///   - userEmail: Optional filter to only count knocks made by a specific user.
    /// - Returns: Total knock count.
    static func totalKnocks(from prospects: [Prospect], userEmail: String? = nil) -> Int {
        prospects.reduce(0) { sum, prospect in
            sum + prospect.knockHistory.filter { userEmail == nil || $0.userEmail == userEmail }.count
        }
    }

    /// Aggregates the number of knocks per list category (e.g., "Prospects", "Customers").
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    ///   - userEmail: Optional filter to only count knocks made by a specific user.
    /// - Returns: Dictionary mapping list names to total knocks.
    static func knocksByList(from prospects: [Prospect], userEmail: String? = nil) -> [String: Int] {
        var result: [String: Int] = [:]
        for p in prospects {
            let knocks = p.knockHistory.filter { userEmail == nil || $0.userEmail == userEmail }.count
            result[p.list, default: 0] += knocks
        }
        return result
    }

    /// Calculates how many knocks were answered versus not answered.
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    ///   - userEmail: Optional filter to only count knocks made by a specific user.
    /// - Returns: A tuple containing counts of answered and not answered knocks.
    static func knocksAnsweredVsUnanswered(from prospects: [Prospect], userEmail: String? = nil) -> (answered: Int, unanswered: Int) {
        var answered = 0, unanswered = 0
        for p in prospects {
            for k in p.knockHistory where userEmail == nil || k.userEmail == userEmail {
                if k.status == "Answered" {
                    answered += 1
                } else if k.status == "Not Answered" {
                    unanswered += 1
                }
            }
        }
        return (answered, unanswered)
    }
}
