//
//  ProfileView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import SwiftUI
import Charts
import SwiftData

/// A view that displays summary analytics about the current user's knocking activity,
/// including total knocks, knocks grouped by list, and answered vs. not answered statistics.
///
/// The profile also includes a logout button, which resets the app's login state.
struct ProfileView: View {
    /// Whether the user is currently logged in.
    @Binding var isLoggedIn: Bool

    /// The logged-in user's email address, used to filter their data.
    let userEmail: String

    /// A query that fetches all `Prospect` records associated with the current user.
    @Query private var prospects: [Prospect]
    @Query private var allProspects: [Prospect]        // Global
    
    @Query private var trips: [Trip]

    /// Initializes the profile view with a login state binding and user email.
    /// Filters prospects to only include those associated with the current user.
    init(isLoggedIn: Binding<Bool>, userEmail: String) {
        self._isLoggedIn = isLoggedIn
        self.userEmail = userEmail

        // Fetch prospects and trips for this user
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
        _trips = Query(filter: #Predicate<Trip> { $0.userEmail == userEmail })
    }

    var body: some View {
        // Calculate stats
        let totalKnocks = ProfileController.totalKnocks(from: prospects, userEmail: userEmail)
        let knocksByList = ProfileController.knocksByList(from: prospects, userEmail: userEmail)
        let answeredVsUnanswered = ProfileController.knocksAnsweredVsUnanswered(from: prospects, userEmail: userEmail)

        NavigationView {
            Form {
                
                // Get personal and global knock counts
                let yourKnocks = ProfileController.totalKnocks(from: prospects, userEmail: userEmail)
                let globalKnocks = ProfileController.totalKnocks(from: allProspects)

                // MARK: Total Knocks Summary
                Section(header: Text("Summary")) {
                    HStack(spacing: 12) {
                        LeaderboardCardView(title: "You", count: yourKnocks)
                        LeaderboardCardView(title: "Global", count: globalKnocks)
                    }
                    .padding(.vertical, 8)
                }

                // MARK: Answered vs Not Answered Chart
                Section(header: Text("Answered vs Unanswered")) {
                    Chart {
                        BarMark(
                            x: .value("Status", "Answered"),
                            y: .value("Count", answeredVsUnanswered.answered)
                        )
                        BarMark(
                            x: .value("Status", "Not Answered"),
                            y: .value("Count", answeredVsUnanswered.unanswered)
                        )
                    }
                    .frame(height: 120)
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
                            AxisValueLabel(format: .dateTime.weekday(.narrow)) // M, T, W...
                        }
                    }
                    .frame(height: 160)
                }

                // MARK: Log Out Button
                Section {
                    Button(role: .destructive) {
                        isLoggedIn = false
                    } label: {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private var milesByDay: [(date: Date, miles: Double)] {
        let calendar = Calendar.current
        let now = Date()

        // Step 1: Get start of the current week (Monday)
        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: startOfToday) // 1 = Sunday, 2 = Monday, ...
        let daysFromMonday = (weekday + 5) % 7 // shift so Monday = 0
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfToday) else { return [] }

        // Step 2: Create Mon–Sun placeholder with 0 miles
        var result: [Date: Double] = [:]
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                result[calendar.startOfDay(for: day)] = 0
            }
        }

        // Step 3: Group trips by start-of-day and sum mileage
        let grouped = Dictionary(grouping: trips) { trip in
            calendar.startOfDay(for: trip.date)
        }

        for (day, tripsOnDay) in grouped {
            if result[day] != nil {
                result[day]! += tripsOnDay.reduce(0) { $0 + $1.miles }
            }
        }

        // Step 4: Return sorted list of 7 entries
        return result
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }
}
