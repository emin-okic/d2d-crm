//
//  MonthlyMilesSegment.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import Foundation

struct MonthlyMilesSegment: Identifiable {
    let id = UUID()
    let weekLabel: String   // e.g., "Week 1"
    let miles: Double
}

extension Array where Element == Trip {
    func monthlyMilesSegments() -> [MonthlyMilesSegment] {
        let calendar = Calendar.current
        let now = Date()
        var segments: [MonthlyMilesSegment] = []

        // Get the current month
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        // Split into weeks (assuming 4 or 5 weeks)
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let totalDays = monthRange.count
        let weekCount = 5
        let daysPerWeek = totalDays / weekCount

        for weekIndex in 0..<weekCount {
            let startDay = weekIndex * daysPerWeek + 1
            var endDay = (weekIndex + 1) * daysPerWeek
            if weekIndex == weekCount - 1 { endDay = totalDays } // last week takes remaining days

            guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: startDay)),
                  let endDate = calendar.date(from: DateComponents(year: year, month: month, day: endDay)) else {
                continue
            }

            let miles = self.filter { trip in
                // check if trip.date is between startDate and endDate, ignoring time
                (calendar.compare(trip.date, to: startDate, toGranularity: .day) != .orderedAscending) &&
                (calendar.compare(trip.date, to: endDate, toGranularity: .day) != .orderedDescending)
            }
            .reduce(0) { $0 + $1.miles }

            segments.append(MonthlyMilesSegment(weekLabel: "W\(weekIndex+1)", miles: miles))
        }

        return segments
    }
}
