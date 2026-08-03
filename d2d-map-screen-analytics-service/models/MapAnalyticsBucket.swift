//
//  MapAnalyticsBucket.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import Foundation

struct MapAnalyticsBucket: Identifiable {
    let id: Int
    let index: Int
    let label: String
    let count: Int
}

enum MapAnalyticsCalculator {
    static func knocks(
        from allKnocks: [Knock],
        for definition: MapScorecardDefinition,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [Knock] {
        allKnocks.filter { knock in
            definition.period.contains(knock.date, calendar: calendar, now: now) && matches(knock, metric: definition.metric)
        }
    }

    static func totalCount(
        from allKnocks: [Knock],
        for definition: MapScorecardDefinition,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Int {
        knocks(from: allKnocks, for: definition, calendar: calendar, now: now).count
    }

    static func sourceKnockCount(
        from allKnocks: [Knock],
        for period: MapScorecardPeriod,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Int {
        allKnocks.filter { period.contains($0.date, calendar: calendar, now: now) }.count
    }

    static func buckets(
        from allKnocks: [Knock],
        for definition: MapScorecardDefinition,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [MapAnalyticsBucket] {
        let scopedKnocks = knocks(from: allKnocks, for: definition, calendar: calendar, now: now)

        switch definition.period {
        case .daily:
            let grouped = Dictionary(grouping: scopedKnocks) { calendar.component(.hour, from: $0.date) }
            return (0...23).map { hour in
                MapAnalyticsBucket(id: hour, index: hour, label: hourLabel(for: hour), count: grouped[hour]?.count ?? 0)
            }
        case .weekly:
            let grouped = Dictionary(grouping: scopedKnocks) { weekdayIndex(for: $0.date, calendar: calendar) }
            return (0...6).map { index in
                MapAnalyticsBucket(id: index, index: index, label: weekdayLabel(for: index, calendar: calendar), count: grouped[index]?.count ?? 0)
            }
        case .monthly:
            guard let interval = calendar.dateInterval(of: .month, for: now),
                  let dayRange = calendar.range(of: .day, in: .month, for: interval.start) else {
                return []
            }

            let grouped = Dictionary(grouping: scopedKnocks) { calendar.component(.day, from: $0.date) }
            return dayRange.map { day in
                MapAnalyticsBucket(id: day, index: day, label: "\(day)", count: grouped[day]?.count ?? 0)
            }
        }
    }

    static func activeBuckets(
        from buckets: [MapAnalyticsBucket],
        for period: MapScorecardPeriod,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [MapAnalyticsBucket] {
        switch period {
        case .daily:
            let currentHour = calendar.component(.hour, from: now)
            return buckets.filter { $0.index <= currentHour }
        case .weekly:
            let currentWeekday = weekdayIndex(for: now, calendar: calendar)
            return buckets.filter { $0.index <= currentWeekday }
        case .monthly:
            let currentDay = calendar.component(.day, from: now)
            return buckets.filter { $0.index <= currentDay }
        }
    }

    static func isSale(_ knock: Knock) -> Bool {
        let status = knock.status.lowercased()
        return status.contains("converted") || status.contains("sale")
    }

    static func isPositiveResponse(_ knock: Knock) -> Bool {
        let status = knock.status.lowercased()
        return status.contains("answered") || status.contains("converted") || status.contains("sale") || status.contains("follow")
    }

    private static func matches(_ knock: Knock, metric: MapScorecardMetric) -> Bool {
        switch metric {
        case .knocks:
            true
        case .sales:
            isSale(knock)
        }
    }

    private static func weekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private static func weekdayLabel(for index: Int, calendar: Calendar) -> String {
        let weekdayNumber = ((calendar.firstWeekday - 1 + index) % 7) + 1
        return calendar.veryShortWeekdaySymbols[weekdayNumber - 1]
    }

    private static func hourLabel(for hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}
