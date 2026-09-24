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
        SimpleEntry(
            date: Date(),
            appointmentsToday: 3,
            nextAppointmentDate: Date().addingTimeInterval(60 * 60),
            overdueAppointments: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let now = Date()
        completion(entry(at: now))
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
        let entries = refreshDates.map(entry(at:))
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private var appointmentDates: [Date] {
        let timestamps = defaults?.array(forKey: "appointmentDates")?
            .compactMap { ($0 as? NSNumber)?.doubleValue } ?? []
        return timestamps.map(Date.init(timeIntervalSince1970:))
    }

    private func entry(at date: Date) -> SimpleEntry {
        let calendar = Calendar.current
        let openAppointmentsToday = appointmentDates
            .filter { calendar.isDate($0, inSameDayAs: date) }
            .sorted()
        let upcomingAppointments = openAppointmentsToday.filter { $0 > date }
        let overdueAppointments = openAppointmentsToday.filter { $0 <= date }

        return SimpleEntry(
            date: date,
            appointmentsToday: openAppointmentsToday.count,
            nextAppointmentDate: upcomingAppointments.first,
            overdueAppointments: overdueAppointments.count
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let appointmentsToday: Int
    let nextAppointmentDate: Date?
    let overdueAppointments: Int
}

struct d2d_widget_serviceEntryView: View {
    let entry: Provider.Entry

    private var appointmentLabel: String {
        entry.appointmentsToday == 1 ? "appointment" : "appointments"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack(alignment: .bottom, spacing: 16) {
                appointmentSummary

                Spacer(minLength: 8)

                nextAppointment
            }
        }
        .widgetURL(URL(string: "d2dcrm://followup?filter=today"))
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 26, height: 26)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text("D2D SCHEDULE")
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)

            Spacer()

            Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var appointmentSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(entry.appointmentsToday)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("\(appointmentLabel) remaining")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var nextAppointment: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if entry.overdueAppointments > 0 {
                Text("NEEDS FOLLOW-UP")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.orange)

                Label(
                    "\(entry.overdueAppointments) overdue",
                    systemImage: "exclamationmark.circle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            } else if let nextAppointmentDate = entry.nextAppointmentDate {
                Text("UP NEXT")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.blue)

                Text(nextAppointmentDate, format: .dateTime.hour().minute())
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Text("SCHEDULE CLEAR")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.green)

                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }

            Label("View schedule", systemImage: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(TrailingIconLabelStyle())
        }
        .padding(.leading, 16)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.secondary.opacity(0.18))
                .frame(width: 1)
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

private struct AppointmentWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color.blue.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct d2d_widget_service: Widget {
    let kind: String = "d2d_widget_service"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                d2d_widget_serviceEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        AppointmentWidgetBackground()
                    }
            } else {
                d2d_widget_serviceEntryView(entry: entry)
                    .padding()
                    .background(AppointmentWidgetBackground())
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Today's Schedule")
        .description("See your remaining appointments and next scheduled time at a glance.")
    }
}
