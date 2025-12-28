//
//  DailyMilesSegment.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import Foundation

struct DailyMilesSegment {
    let period: String // "Morning", "Afternoon", "Evening"
    let miles: Double
}

extension Array where Element == Trip {
    func dailyMilesSegments() -> [DailyMilesSegment] {
        let calendar = Calendar.current

        var morning: Double = 0
        var afternoon: Double = 0
        var evening: Double = 0

        for trip in self {
            let hour = calendar.component(.hour, from: trip.date)
            switch hour {
            case 0..<12: morning += trip.miles
            case 12..<18: afternoon += trip.miles
            default: evening += trip.miles
            }
        }

        return [
            DailyMilesSegment(period: "Morning", miles: morning),
            DailyMilesSegment(period: "Afternoon", miles: afternoon),
            DailyMilesSegment(period: "Evening", miles: evening)
        ]
    }

    var totalMiles: Double {
        reduce(0) { $0 + $1.miles }
    }
}
