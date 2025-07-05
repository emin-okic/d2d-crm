//
//  ProfileController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

/// A utility struct that provides analytics and summaries based on a collection of `Prospect` objects.
///
struct ProfileController {
    
    /// Computes the total number of knocks recorded across all prospects.
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    /// - Returns: Total knock count.
    static func totalKnocks(from prospects: [Prospect]) -> Int {
        prospects.reduce(0) { sum, prospect in
            sum + prospect.knockHistory.count
        }
    }

    /// Aggregates the number of knocks per list category (e.g., "Prospects", "Customers").
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    /// - Returns: Dictionary mapping list names to total knocks.
    static func knocksByList(from prospects: [Prospect]) -> [String: Int] {
        var result: [String: Int] = [:]
        for p in prospects {
            result[p.list, default: 0] += p.knockHistory.count
        }
        return result
    }

    /// Calculates how many knocks were answered versus not answered.
    ///
    /// - Parameters:
    ///   - prospects: An array of `Prospect` objects.
    /// - Returns: A tuple containing counts of answered and not answered knocks.
    static func knocksAnsweredVsUnanswered(from prospects: [Prospect]) -> (answered: Int, unanswered: Int) {
        var answered = 0, unanswered = 0
        for p in prospects {
            for k in p.knockHistory {
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
