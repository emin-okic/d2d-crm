//
//  ProfileController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

struct ProfileController {
    static func totalKnocks(from prospects: [Prospect], userEmail: String? = nil) -> Int {
        prospects.reduce(0) { sum, prospect in
            sum + prospect.knockHistory.filter { userEmail == nil || $0.userEmail == userEmail }.count
        }
    }

    static func knocksByList(from prospects: [Prospect], userEmail: String? = nil) -> [String: Int] {
        var result: [String: Int] = [:]
        for p in prospects {
            let knocks = p.knockHistory.filter { userEmail == nil || $0.userEmail == userEmail }.count
            result[p.list, default: 0] += knocks
        }
        return result
    }

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
