//
//  DailySalesHourlyChartView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI
import Charts
import SwiftData

struct DailySalesHourlyChartView: View {

    @Query private var allKnocks: [Knock]

    private var todaysKnocks: [Knock] {
        let calendar = Calendar.current
        let today = Date()

        return allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }
    }

    private var todaysSales: [Knock] {
        todaysKnocks.filter { isSale($0) }
    }

    private var hourlyBuckets: [HourlyKnockBucket] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: todaysSales) {
            calendar.component(.hour, from: $0.date)
        }

        return (0...23).map { hour in
            HourlyKnockBucket(
                hour: hour,
                count: grouped[hour]?.count ?? 0
            )
        }
    }

    private var activeBuckets: [HourlyKnockBucket] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return hourlyBuckets.filter { $0.hour <= currentHour }
    }

    private var totalSales: Int {
        todaysSales.count
    }

    private var conversionRate: Int {
        guard !todaysKnocks.isEmpty else { return 0 }
        return Int((Double(totalSales) / Double(todaysKnocks.count) * 100).rounded())
    }

    private var peakBucket: HourlyKnockBucket? {
        hourlyBuckets.max { $0.count < $1.count }
    }

    private var peakCount: Int {
        max(peakBucket?.count ?? 0, 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                momentumChart
                closeDensityStrip
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.16), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(Double(conversionRate) / 100, 1))
                    .stroke(
                        AngularGradient(colors: [.green, .mint, .yellow, .green], center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(totalSales)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("closed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Sales Progress")
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("Closed deals and conversion pace for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    metricChip("Conversion", "\(conversionRate)%", .green)
                    metricChip("Peak Close", peakHourText, .orange)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var momentumChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sales momentum")
                    .font(.headline)

                Spacer()

                Text("\(todaysKnocks.count) knocks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Chart(activeBuckets) { bucket in
                AreaMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Sales", bucket.count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green.opacity(0.34), Color.green.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Sales", bucket.count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Sales", bucket.count)
                )
                .symbolSize(bucket.count == peakCount && peakCount > 0 ? 104 : 44)
                .foregroundStyle(bucket.count == peakCount && peakCount > 0 ? Color.green : Color.orange.opacity(0.62))
            }
            .chartXScale(domain: 0...23)
            .chartYScale(domain: 0...max(peakCount + 1, 2))
            .chartXAxis {
                AxisMarks(values: Array(stride(from: 0, through: 23, by: 4))) { value in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.10))
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(hourLabel(for: hour))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 190)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private var closeDensityStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Close density")
                    .font(.headline)

                Spacer()

                Label("sale hours", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 12), spacing: 5) {
                ForEach(hourlyBuckets) { bucket in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(heatColor(for: bucket.count))
                        .frame(height: 28)
                        .overlay {
                            if bucket.count > 0 {
                                Image(systemName: bucket.count > 1 ? "checkmark.seal.fill" : "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel("\(hourLabel(for: bucket.hour)), \(bucket.count) sales")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private var peakHourText: String {
        guard let peakBucket, peakBucket.count > 0 else { return "--" }
        return hourLabel(for: peakBucket.hour)
    }

    private func metricChip(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(0.10)))
    }

    private func heatColor(for count: Int) -> Color {
        guard count > 0 else { return Color.secondary.opacity(0.12) }
        let intensity = min(Double(count) / Double(peakCount), 1)
        return Color.green.opacity(0.32 + (0.68 * intensity))
    }

    private func hourLabel(for hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }

    private func isSale(_ knock: Knock) -> Bool {
        knock.status.lowercased().contains("converted") ||
        knock.status.lowercased().contains("sale")
    }
}
