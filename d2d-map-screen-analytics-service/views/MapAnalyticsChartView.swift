//
//  MapAnalyticsChartView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI
import Charts
import SwiftData

struct MapAnalyticsChartView: View {
    let definition: MapScorecardDefinition

    @Query private var allKnocks: [Knock]

    private var scopedAllKnocks: [Knock] {
        allKnocks.filter { definition.period.contains($0.date) }
    }

    private var metricKnocks: [Knock] {
        MapAnalyticsCalculator.knocks(from: allKnocks, for: definition)
    }

    private var buckets: [MapAnalyticsBucket] {
        MapAnalyticsCalculator.buckets(from: allKnocks, for: definition)
    }

    private var activeBuckets: [MapAnalyticsBucket] {
        MapAnalyticsCalculator.activeBuckets(from: buckets, for: definition.period)
    }

    private var totalCount: Int {
        metricKnocks.count
    }

    private var peakBucket: MapAnalyticsBucket? {
        buckets.max { $0.count < $1.count }
    }

    private var peakCount: Int {
        max(peakBucket?.count ?? 0, 1)
    }

    private var rate: Int {
        guard scopedAllKnocks.isEmpty == false else { return 0 }

        switch definition.metric {
        case .knocks:
            let positiveCount = scopedAllKnocks.filter { MapAnalyticsCalculator.isPositiveResponse($0) }.count
            return Int((Double(positiveCount) / Double(scopedAllKnocks.count) * 100).rounded())
        case .sales:
            return Int((Double(totalCount) / Double(scopedAllKnocks.count) * 100).rounded())
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                progressChart
                densityGrid
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(definition.color.opacity(0.16), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(colors: ringColors, center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(totalCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(definition.metric.closedNoun)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                Text(chartTitle)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(chartSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    metricChip(rateTitle, "\(rate)%", definition.metric == .sales ? .green : .blue)
                    metricChip(peakTitle, peakLabel, .orange)
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

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(chartSectionTitle)
                    .font(.headline)

                Spacer()

                Text(chartTrailingText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Chart(activeBuckets) { bucket in
                AreaMark(
                    x: .value(axisTitle, bucket.index),
                    y: .value(definition.metric.noun, bucket.count)
                )
                .interpolationMethod(interpolationMethod)
                .foregroundStyle(
                    LinearGradient(
                        colors: [definition.color.opacity(0.34), definition.color.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value(axisTitle, bucket.index),
                    y: .value(definition.metric.noun, bucket.count)
                )
                .interpolationMethod(interpolationMethod)
                .foregroundStyle(definition.color)
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value(axisTitle, bucket.index),
                    y: .value(definition.metric.noun, bucket.count)
                )
                .symbolSize(bucket.count == peakCount && peakCount > 0 ? 104 : 44)
                .foregroundStyle(bucket.count == peakCount && peakCount > 0 ? definition.color : Color.orange.opacity(0.62))
            }
            .chartYScale(domain: 0...max(peakCount + 1, 2))
            .chartXAxis {
                AxisMarks(values: axisValues) { value in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.10))
                    AxisValueLabel {
                        if let index = value.as(Int.self) {
                            Text(axisLabel(for: index))
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

    private var densityGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(densityTitle)
                    .font(.headline)

                Spacer()

                Label(densityLabel, systemImage: definition.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(definition.color)
            }

            LazyVGrid(columns: densityColumns, spacing: 5) {
                ForEach(buckets) { bucket in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(heatColor(for: bucket.count))
                        .frame(height: 28)
                        .overlay {
                            densityOverlay(for: bucket.count)
                        }
                        .accessibilityLabel("\(bucket.label), \(bucket.count) \(definition.metric.noun.lowercased())")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    @ViewBuilder
    private func densityOverlay(for count: Int) -> some View {
        if count > 0 {
            switch definition.metric {
            case .knocks:
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            case .sales:
                Image(systemName: count > 1 ? "checkmark.seal.fill" : "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var chartTitle: String {
        switch definition.metric {
        case .knocks:
            "\(definition.period.titlePrefix) Knock Progress"
        case .sales:
            "\(definition.period.titlePrefix) Sales Progress"
        }
    }

    private var chartSubtitle: String {
        switch definition.metric {
        case .knocks:
            "Pace and response quality across \(definition.period.chartScopeText)"
        case .sales:
            "Closed deals and conversion pace for \(definition.period.chartScopeText)"
        }
    }

    private var chartSectionTitle: String {
        switch definition.metric {
        case .knocks:
            definition.period == .daily ? "Knock rhythm" : "Knock trend"
        case .sales:
            "Sales momentum"
        }
    }

    private var chartTrailingText: String {
        switch definition.metric {
        case .knocks:
            Date().formatted(.dateTime.month().day())
        case .sales:
            "\(scopedAllKnocks.count) knocks"
        }
    }

    private var rateTitle: String {
        switch definition.metric {
        case .knocks:
            "Response"
        case .sales:
            "Conversion"
        }
    }

    private var peakTitle: String {
        switch definition.metric {
        case .knocks:
            definition.period == .daily ? "Peak" : "Best Day"
        case .sales:
            definition.period == .daily ? "Peak Close" : "Best Day"
        }
    }

    private var peakLabel: String {
        guard let peakBucket, peakBucket.count > 0 else { return "--" }
        return peakBucket.label
    }

    private var densityTitle: String {
        switch definition.metric {
        case .knocks:
            definition.period == .daily ? "Hourly density" : "Daily density"
        case .sales:
            definition.period == .daily ? "Close density" : "Close distribution"
        }
    }

    private var densityLabel: String {
        switch definition.period {
        case .daily:
            definition.metric == .sales ? "sale hours" : "active hours"
        case .weekly:
            "week days"
        case .monthly:
            "month days"
        }
    }

    private var ringProgress: Double {
        switch definition.metric {
        case .knocks:
            min(Double(totalCount) / Double(peakCount * max(activeBuckets.count, 1)), 1)
        case .sales:
            min(Double(rate) / 100, 1)
        }
    }

    private var ringColors: [Color] {
        switch definition.metric {
        case .knocks:
            [.blue, .cyan, .blue]
        case .sales:
            [.green, .mint, .yellow, .green]
        }
    }

    private var interpolationMethod: InterpolationMethod {
        definition.period == .daily ? .catmullRom : .monotone
    }

    private var axisTitle: String {
        switch definition.period {
        case .daily:
            "Hour"
        case .weekly:
            "Day"
        case .monthly:
            "Month Day"
        }
    }

    private var axisValues: [Int] {
        switch definition.period {
        case .daily:
            Array(stride(from: 0, through: 23, by: 4))
        case .weekly:
            Array(0...6)
        case .monthly:
            buckets.map(\.index).filter { $0 == 1 || $0 % 5 == 0 || $0 == buckets.count }
        }
    }

    private var densityColumns: [GridItem] {
        switch definition.period {
        case .daily:
            Array(repeating: GridItem(.flexible(), spacing: 5), count: 12)
        case .weekly:
            Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
        case .monthly:
            Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
        }
    }

    private func axisLabel(for index: Int) -> String {
        buckets.first { $0.index == index }?.label ?? "\(index)"
    }

    private func heatColor(for count: Int) -> Color {
        guard count > 0 else { return Color.secondary.opacity(0.12) }
        let intensity = min(Double(count) / Double(peakCount), 1)
        return definition.color.opacity(0.32 + (0.68 * intensity))
    }
}
