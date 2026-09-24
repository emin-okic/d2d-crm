//
//  d2d_widget_service.swift
//  d2d-widget-service
//
//  Created by Emin Okic on 7/19/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.okic.d2dcrm")

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), appointmentsToday: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let now = Date()
        completion(SimpleEntry(date: now, appointmentsToday: appointmentCount(at: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        let futureAppointmentsToday = appointmentDates.filter {
            $0 > now && calendar.isDateInToday($0)
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let refreshDates = ([now] + futureAppointmentsToday + [tomorrow].compactMap { $0 })
            .sorted()
        let entries = refreshDates.map {
            SimpleEntry(date: $0, appointmentsToday: appointmentCount(at: $0))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private var appointmentDates: [Date] {
        let timestamps = defaults?.array(forKey: "appointmentDates") as? [Double] ?? []
        return timestamps.map(Date.init(timeIntervalSince1970:))
    }

    private func appointmentCount(at date: Date) -> Int {
        let calendar = Calendar.current
        return appointmentDates.filter {
            $0 > date && calendar.isDate($0, inSameDayAs: date)
        }.count
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let appointmentsToday: Int
}

struct d2d_widget_serviceEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Appointments Today")
                .font(.headline)
            Text("\(entry.appointmentsToday)")
                .font(.system(size: 32, weight: .bold))
        }
        .padding()
        
        // make the whole widget tappable
        .widgetURL(URL(string: "d2dcrm://followup?filter=today"))
    }
}

struct d2d_widget_service: Widget {
    let kind: String = "d2d_widget_service"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                d2d_widget_serviceEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                d2d_widget_serviceEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("D2D Studio Widget")
        .description("This is a widget for the d2d studio to check your appointments.")
    }
}
