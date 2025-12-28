//
//  YearlyMilesSegment.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import Foundation

struct YearlyMilesSegment: Identifiable {
    let id = UUID()
    let month: String   // e.g., "Jan"
    let miles: Double
}

extension Array where Element == Trip {
    func yearlyMilesSegments() -> [YearlyMilesSegment] {
        let calendar = Calendar.current
        var segments: [YearlyMilesSegment] = []

        let currentYear = calendar.component(.year, from: Date())

        for monthIndex in 1...12 {
            // Get the start of the month
            var components = DateComponents()
            components.year = currentYear
            components.month = monthIndex
            components.day = 1
            guard let monthStart = calendar.date(from: components) else { continue }

            // Get the end of the month
            guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart),
                  let monthEnd = calendar.date(byAdding: .day, value: monthRange.count - 1, to: monthStart) else { continue }

            // Sum trips in this month
            let miles = self.filter { $0.date >= monthStart && $0.date <= monthEnd }
                .reduce(0) { $0 + $1.miles }

            let monthName = calendar.monthSymbols[monthIndex - 1] // "Jan", "Feb", etc.
            segments.append(YearlyMilesSegment(month: monthName, miles: miles))
        }

        return segments
    }
}
