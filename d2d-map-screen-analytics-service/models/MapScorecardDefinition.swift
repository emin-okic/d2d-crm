//
//  MapScorecardDefinition.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI

enum MapScorecardMetric: String, CaseIterable {
    case knocks
    case sales
    case streak

    var noun: String {
        switch self {
        case .knocks:
            "Knocks"
        case .sales:
            "Sales"
        case .streak:
            "Streak"
        }
    }

    var closedNoun: String {
        switch self {
        case .knocks:
            "knocks"
        case .sales:
            "closed"
        case .streak:
            "days"
        }
    }

    var icon: String {
        switch self {
        case .knocks:
            "door.left.hand.open"
        case .sales:
            "checkmark.seal.fill"
        case .streak:
            "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .knocks:
            .blue
        case .sales:
            .green
        case .streak:
            .orange
        }
    }
}

enum MapScorecardPeriod: String, CaseIterable {
    case daily
    case weekly
    case monthly

    var titlePrefix: String {
        switch self {
        case .daily:
            "Today's"
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        }
    }

    var chartScopeText: String {
        switch self {
        case .daily:
            "today"
        case .weekly:
            "this week"
        case .monthly:
            "this month"
        }
    }

    func contains(_ date: Date, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        switch self {
        case .daily:
            return calendar.isDate(date, inSameDayAs: now)
        case .weekly:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
            return interval.contains(date)
        case .monthly:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return false }
            return interval.contains(date)
        }
    }
}

struct MapScorecardDefinition: Identifiable, Hashable, CaseIterable {
    let metric: MapScorecardMetric
    let period: MapScorecardPeriod

    var id: String { "\(period.rawValue).\(metric.rawValue)" }
    var title: String {
        metric == .streak ? "Knock Streak" : "\(period.titlePrefix) \(metric.noun)"
    }
    var description: String {
        switch (metric, period) {
        case (.knocks, .daily):
            "Track the doors you hit today and keep the route moving."
        case (.sales, .daily):
            "Keep today's closes front and center while you work the map."
        case (.streak, _):
            "Show your active knocking streak and protect the run."
        case (.knocks, .weekly):
            "Watch weekly activity build across every territory pass."
        case (.sales, .weekly):
            "Measure weekly wins without leaving the map."
        case (.knocks, .monthly):
            "See month-to-date knocking volume at a glance."
        case (.sales, .monthly):
            "Keep your monthly close count visible during planning."
        }
    }
    var icon: String { metric.icon }
    var color: Color { metric.color }

    static let allCases: [MapScorecardDefinition] = [
        .init(metric: .knocks, period: .daily),
        .init(metric: .sales, period: .daily),
        .init(metric: .streak, period: .daily),
        .init(metric: .knocks, period: .weekly),
        .init(metric: .sales, period: .weekly),
        .init(metric: .knocks, period: .monthly),
        .init(metric: .sales, period: .monthly)
    ]

    static let defaultSelection: [MapScorecardDefinition] = [
        .init(metric: .knocks, period: .daily),
        .init(metric: .sales, period: .daily)
    ]

    static func definition(for id: String) -> MapScorecardDefinition? {
        allCases.first { $0.id == id }
    }
}
