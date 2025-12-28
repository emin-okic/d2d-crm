//
//  WeeklyMilesSegment.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import Foundation

struct WeeklyMilesSegment: Identifiable {
    let id = UUID()
    let day: String   // e.g., "Mon", "Tue"
    let miles: Double
}

extension Array where Element == Trip {
    func weeklyMilesSegments() -> [WeeklyMilesSegment] {
        let calendar = Calendar.current
        let today = Date()
        var segments: [WeeklyMilesSegment] = []

        for offset in (0..<7).reversed() { // 7 days, oldest first
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date)-1]
            let miles = self.filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.miles }
            segments.append(WeeklyMilesSegment(day: dayName, miles: miles))
        }

        return segments
    }
}
