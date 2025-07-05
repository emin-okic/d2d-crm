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

    private var now: Date { Date() }
    private var calendar: Calendar { .current }

    private var knocks: [Knock] {
        prospects.flatMap(\.knockHistory)
    }

    private var hourlyKnocks: [(Int, Int)] {
        var counts = Array(repeating: 0, count: 24)
        for knock in knocks {
            let hour = calendar.component(.hour, from: knock.date)
            counts[hour] += 1
        }
        return counts.enumerated().map { ($0.offset, $0.element) }
    }

    private var knocksThisHour: Int {
        let hour = calendar.component(.hour, from: now)
        return hourlyKnocks.first(where: { $0.0 == hour })?.1 ?? 0
    }

    private var dailyKnocks: [(Date, Int)] {
        var result: [Date: Int] = [:]
        for knock in knocks {
            let day = calendar.startOfDay(for: knock.date)
            result[day, default: 0] += 1
        }
        return result.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    private var knocksToday: Int {
        let today = calendar.startOfDay(for: now)
        return dailyKnocks.first(where: { calendar.isDate($0.0, inSameDayAs: today) })?.1 ?? 0
    }

    private var knocksThisWeek: Int {
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return knocks.filter { $0.date >= weekStart }.count
    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Hourly
                VStack(spacing: 16) {
                    Text("Hourly Activity")
                        .font(.title).bold()

                    HStack(spacing: 12) {
                        LeaderboardCardView(title: "This Hour", count: knocksThisHour)
                        LeaderboardCardView(title: "Today", count: knocksToday)
                        LeaderboardCardView(title: "This Week", count: knocksThisWeek)
                    }
                    .padding(.horizontal, 20)

                    Chart {
                        ForEach(hourlyKnocks, id: \.0) { hour, count in
                            BarMark(
                                x: .value("Hour", hour),
                                y: .value("Knocks", count)
                            )
                        }
                    }
                    .frame(height: 180)
                    .padding(.top, 8)
                }
                .tag(0)
                .padding()

                // Page 2: Daily
                VStack(spacing: 16) {
                    Text("Daily Activity")
                        .font(.title).bold()

                    HStack(spacing: 12) {
                        LeaderboardCardView(title: "Today", count: knocksToday)
                        LeaderboardCardView(title: "This Week", count: knocksThisWeek)
                    }
                    .padding(.horizontal, 20)

                    Chart {
                        ForEach(dailyKnocks, id: \.0) { date, count in
                            BarMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Knocks", count)
                            )
                        }
                    }
                    .frame(height: 180)
                    .padding(.top, 8)
                }
                .tag(1)
                .padding()

                // Page 3: Summary
                VStack(spacing: 16) {
                    Text("Weekly Summary")
                        .font(.title).bold()

                    LeaderboardCardView(title: "Knocks This Week", count: knocksThisWeek)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    Spacer()
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
