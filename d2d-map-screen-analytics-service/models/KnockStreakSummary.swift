//
//  KnockStreakSummary.swift
//  d2d-studio
//
//  Created by Codex on 8/3/26.
//

import Foundation

struct KnockStreakSummary {
    let currentStreak: Int
    let longestStreak: Int
    let totalActiveDays: Int
    let knockedToday: Bool
    let lastKnockDate: Date?
    let days: [KnockStreakDay]

    var isAtRiskToday: Bool {
        currentStreak > 2 && knockedToday == false
    }

    var statusText: String {
        if knockedToday {
            return currentStreak == 1 ? "Started today" : "Protected today"
        }

        guard currentStreak > 0 else { return "No active streak" }
        return "At risk today"
    }
}

struct KnockStreakDay: Identifiable {
    let date: Date
    let count: Int

    var id: Date { date }
}

enum KnockStreakCalculator {
    static func summary(
        from knocks: [Knock],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> KnockStreakSummary {
        let grouped = Dictionary(grouping: knocks) { knock in
            calendar.startOfDay(for: knock.date)
        }

        let activeDays = grouped.keys.sorted()
        let dayModels = activeDays.map { day in
            KnockStreakDay(date: day, count: grouped[day]?.count ?? 0)
        }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let knockedToday = grouped[today] != nil
        let currentAnchor = knockedToday ? today : yesterday
        let currentStreak = consecutiveCount(endingAt: currentAnchor, activeDays: Set(activeDays), calendar: calendar)

        return KnockStreakSummary(
            currentStreak: currentStreak,
            longestStreak: longestConsecutiveCount(activeDays: activeDays, calendar: calendar),
            totalActiveDays: activeDays.count,
            knockedToday: knockedToday,
            lastKnockDate: knocks.map(\.date).max(),
            days: dayModels
        )
    }

    static func recentDays(
        from summary: KnockStreakSummary,
        count: Int = 14,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [KnockStreakDay] {
        let today = calendar.startOfDay(for: now)
        let countsByDay = Dictionary(uniqueKeysWithValues: summary.days.map { ($0.date, $0.count) })

        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(count - 1 - offset), to: today) else {
                return nil
            }

            return KnockStreakDay(date: date, count: countsByDay[date] ?? 0)
        }
    }

    private static func consecutiveCount(
        endingAt anchor: Date,
        activeDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        var cursor = anchor
        var count = 0

        while activeDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return count
    }

    private static func longestConsecutiveCount(activeDays: [Date], calendar: Calendar) -> Int {
        guard activeDays.isEmpty == false else { return 0 }

        var longest = 1
        var current = 1

        for index in activeDays.indices.dropFirst() {
            let previous = activeDays[activeDays.index(before: index)]
            let expected = calendar.date(byAdding: .day, value: 1, to: previous)

            if expected == activeDays[index] {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }

        return max(longest, current)
    }
}
