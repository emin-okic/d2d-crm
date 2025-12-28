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
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }

        var segments: [MonthlyMilesSegment] = []

        // Use a compatible default Range<Int>
        let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: startOfMonth) ?? 1..<5

        for week in weekRange {
            guard let weekStart = calendar.date(byAdding: .weekOfMonth, value: week-1, to: startOfMonth),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { continue }

            let miles = self.filter { $0.date >= weekStart && $0.date <= weekEnd }
                .reduce(0) { $0 + $1.miles }

            segments.append(MonthlyMilesSegment(weekLabel: "W\(week)", miles: miles))
        }

        return segments
    }
}
