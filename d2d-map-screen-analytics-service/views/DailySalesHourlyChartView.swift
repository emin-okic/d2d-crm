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

    private var hourlyBuckets: [HourlyKnockBucket] {
        let calendar = Calendar.current
        let today = Date()

        let todaysSales = allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today) &&
            $0.status == "Converted To Sale"
        }

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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Hourly Sales Progress")
                .font(.headline)

            Chart(hourlyBuckets) { bucket in
                BarMark(
                    x: .value("Hour", bucket.hour),
                    y: .value("Sales", bucket.count)
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: Array(stride(from: 0, through: 23, by: 3))) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour)")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 140)
        }
        .padding()
    }
}
