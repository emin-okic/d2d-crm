//
//  ActivityOnboardingFlowView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/5/25.
//
import SwiftUI
import Charts
import SwiftData

struct ActivityOnboardingFlowView: View {
    @Binding var isPresented: Bool
    @Query private var prospects: [Prospect]
    @State private var currentPage = 0

    private var hourlyKnocks: [(Int, Int)] {
        var hourlyCounts = Array(repeating: 0, count: 24)
        for knock in prospects.flatMap(\.knockHistory) {
            let hour = Calendar.current.component(.hour, from: knock.date)
            hourlyCounts[hour] += 1
        }
        return hourlyCounts.enumerated().map { ($0.offset, $0.element) }
    }

    private var dailyKnocks: [(Date, Int)] {
        var result: [Date: Int] = [:]
        let calendar = Calendar.current

        for knock in prospects.flatMap(\.knockHistory) {
            let day = calendar.startOfDay(for: knock.date)
            result[day, default: 0] += 1
        }

        return result.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Hourly
                VStack(spacing: 16) {
                    Text("Hourly Activity")
                        .font(.title).bold()
                    Chart {
                        ForEach(hourlyKnocks, id: \.0) { hour, count in
                            BarMark(x: .value("Hour", hour),
                                    y: .value("Knocks", count))
                        }
                    }
                    .frame(height: 180)
                }
                .tag(0)
                .padding()

                // Page 2: Daily
                VStack(spacing: 16) {
                    Text("Daily Activity")
                        .font(.title).bold()
                    Chart {
                        ForEach(dailyKnocks, id: \.0) { date, count in
                            BarMark(x: .value("Day", date, unit: .day),
                                    y: .value("Knocks", count))
                        }
                    }
                    .frame(height: 180)
                }
                .tag(1)
                .padding()

                // Page 3: Summary
                VStack(spacing: 16) {
                    Text("Weekly Summary")
                        .font(.title).bold()
                    let total = dailyKnocks.map(\.1).reduce(0, +)
                    Text("Total knocks this week: \(total)")
                        .font(.headline)
                }
                .tag(2)
                .padding()
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            Button(currentPage < 2 ? "Next" : "Close") {
                if currentPage < 2 {
                    currentPage += 1
                } else {
                    isPresented = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
        }
    }
}
