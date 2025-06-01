//
//  GraphController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

struct GraphController {
    static func totalKnocks(from prospects: [Prospect]) -> Int {
        prospects.map { $0.count }.reduce(0, +)
    }

    static func knocksByList(from prospects: [Prospect]) -> [String: Int] {
        Dictionary(grouping: prospects, by: { $0.list })
            .mapValues { $0.map(\.count).reduce(0, +) }
    }
    
    static func knocksAnsweredVsUnanswered(from prospects: [Prospect]) -> (answered: Int, unanswered: Int) {
        var answered = 0
        var unanswered = 0

        for prospect in prospects {
            for knock in prospect.knockHistory {
                if knock.status == "Answered" {
                    answered += 1
                } else if knock.status == "Not Answered" {
                    unanswered += 1
                }
            }
        }

        return (answered, unanswered)
    }
}
