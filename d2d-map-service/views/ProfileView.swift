//
//  ProfileView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//
import SwiftUI
import Charts
import SwiftData

struct ProfileView: View {
    @Query private var prospects: [Prospect]
    @Query private var trips: [Trip]

    var body: some View {
        let totalKnocks = ProfileController.totalKnocks(from: prospects)
        let answeredVsUnanswered = ProfileController.knocksAnsweredVsUnanswered(from: prospects)

        // New summary stats
        let totalProspects = prospects.count
        let totalCustomers = prospects.filter { $0.list == "Customers" }.count
        let averageKnocksPerCustomer: Double = {
            let customerKnocks = prospects
                .filter { $0.list == "Customers" }
                .map { $0.knockHistory.count }
            guard !customerKnocks.isEmpty else { return 0 }
            return Double(customerKnocks.reduce(0, +)) / Double(customerKnocks.count)
        }()

        NavigationView {
            Form {

                // MARK: Total Summary
                Section(header: Text("Summary")) {
                    HStack(alignment: .center, spacing: 10) {
                        LeaderboardCardView(title: "Prospects", count: totalProspects)
                        LeaderboardCardView(title: "Customers", count: totalCustomers)
                        LeaderboardCardView(
                            title: "Avg Knocks/Customer",
                            count: Int(averageKnocksPerCustomer.rounded())
                        )
                    }
                    .padding(.vertical, 8)
                }

                // MARK: Answered vs Not Answered Chart
                Section(header: Text("Prospecting Activity")) {
                    VStack(alignment: .leading, spacing: 10) {
                        LeaderboardCardView(title: "Total Knocks", count: totalKnocks)
                        Chart {
                            BarMark(x: .value("Status", "Answered"), y: .value("Count", answeredVsUnanswered.answered))
                            BarMark(x: .value("Status", "Not Answered"), y: .value("Count", answeredVsUnanswered.unanswered))
                        }
                        .frame(height: 120)
                    }
                }

                // MARK: Mileage by Day (Past 7 Days)
                Section(header: Text("Mileage This Week")) {
                    Chart {
                        ForEach(milesByDay, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Miles", item.miles)
                            )
                            .foregroundStyle(Color.green)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 160)
                }

            }
            .navigationTitle("Profile")
        }
    }

    private var milesByDay: [(date: Date, miles: Double)] {
        let calendar = Calendar.current
        let now = Date()

        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysFromMonday = (weekday + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfToday) else { return [] }

        var result: [Date: Double] = [:]
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                result[calendar.startOfDay(for: day)] = 0
            }
        }

        let grouped = Dictionary(grouping: trips) { calendar.startOfDay(for: $0.date) }

        for (day, tripsOnDay) in grouped {
            if result[day] != nil {
                result[day]! += tripsOnDay.reduce(0) { $0 + $1.miles }
            }
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }
}
