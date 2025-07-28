//
//  d2d_widget_service.swift
//  d2d-widget-service
//
//  Created by Emin Okic on 7/19/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), appointmentsToday: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let count = UserDefaults(suiteName: "group.okic.d2dcrm")?.integer(forKey: "appointmentsToday") ?? 0
        completion(SimpleEntry(date: Date(), appointmentsToday: count))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let count = UserDefaults(suiteName: "group.okic.d2dcrm")?.integer(forKey: "appointmentsToday") ?? 0
        let entry = SimpleEntry(date: Date(), appointmentsToday: count)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
        completion(timeline)
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
        .widgetURL(URL(string: "d2dcrm://todaysappointments"))
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
