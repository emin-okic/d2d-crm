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

private struct SalesScorecardEntry: TimelineEntry {
    let date: Date
    let weeklyKnocks: Int
    let weeklySales: Int
    let todayKnocks: Int

    var conversionRate: Double {
        guard weeklyKnocks > 0 else { return 0 }
        return Double(weeklySales) / Double(weeklyKnocks)
    }
}

private struct SalesScorecardProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.okic.d2dcrm")

    func placeholder(in context: Context) -> SalesScorecardEntry {
        SalesScorecardEntry(date: Date(), weeklyKnocks: 84, weeklySales: 7, todayKnocks: 18)
    }

    func getSnapshot(in context: Context, completion: @escaping (SalesScorecardEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalesScorecardEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        completion(Timeline(entries: [entry(at: now)], policy: tomorrow.map(TimelineReloadPolicy.after) ?? .atEnd))
    }

    private func entry(at date: Date) -> SalesScorecardEntry {
        let calendar = Calendar.current
        let week = calendar.dateInterval(of: .weekOfYear, for: date)
        let knockDates = dates(forKey: "scorecardKnockDates")
        let saleDates = dates(forKey: "scorecardSaleDates")

        return SalesScorecardEntry(
            date: date,
            weeklyKnocks: knockDates.filter { week?.contains($0) == true }.count,
            weeklySales: saleDates.filter { week?.contains($0) == true }.count,
            todayKnocks: knockDates.filter { calendar.isDate($0, inSameDayAs: date) }.count
        )
    }

    private func dates(forKey key: String) -> [Date] {
        let timestamps = defaults?.array(forKey: key)?
            .compactMap { ($0 as? NSNumber)?.doubleValue } ?? []
        return timestamps.map(Date.init(timeIntervalSince1970:))
    }
}

private struct SalesScorecardEntryView: View {
    let entry: SalesScorecardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SalesScorecardHeader(date: entry.date)
            HStack(spacing: 0) {
                SalesScorecardMetric(
                    title: "Knocks",
                    value: entry.weeklyKnocks,
                    systemImage: "door.left.hand.open",
                    color: .blue
                )
                SalesScorecardMetric(
                    title: "Sales",
                    value: entry.weeklySales,
                    systemImage: "checkmark.seal.fill",
                    color: .green
                )
                SalesScorecardConversion(rate: entry.conversionRate)
            }

            Label("\(entry.todayKnocks) knocks today", systemImage: "bolt.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "d2dcrm://scorecard"))
    }
}

private struct SalesScorecardHeader: View {
    let date: Date

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: 26, height: 26)
                .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Text("WEEKLY SCORECARD")
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)

            Spacer()

            Text(date, format: .dateTime.month(.abbreviated).day())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SalesScorecardMetric: View {
    let title: LocalizedStringKey
    let value: Int
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)

            Text(value, format: .number)
                .font(.title.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SalesScorecardConversion: View {
    let rate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Conversion", systemImage: "percent")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .lineLimit(1)

            Text(rate, format: .percent.precision(.fractionLength(0)))
                .font(.title.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SalesScorecardBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color.indigo.opacity(0.09)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct D2DSalesScorecardWidget: Widget {
    let kind = "d2d_sales_scorecard"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalesScorecardProvider()) { entry in
            if #available(iOS 17.0, *) {
                SalesScorecardEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        SalesScorecardBackground()
                    }
            } else {
                SalesScorecardEntryView(entry: entry)
                    .padding()
                    .background(SalesScorecardBackground())
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Weekly Sales Scorecard")
        .description("Track this week's knocks, sales, and conversion at a glance.")
    }
}
