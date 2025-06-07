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

    /// Initializes the profile view with a login state binding and user email.
    /// Filters prospects to only include those associated with the current user.
    init(isLoggedIn: Binding<Bool>, userEmail: String) {
        self._isLoggedIn = isLoggedIn
        self.userEmail = userEmail

        // Filter the query to only show prospects for this user
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    var body: some View {
        // Calculate stats
        let totalKnocks = ProfileController.totalKnocks(from: prospects, userEmail: userEmail)
        let knocksByList = ProfileController.knocksByList(from: prospects, userEmail: userEmail)
        let answeredVsUnanswered = ProfileController.knocksAnsweredVsUnanswered(from: prospects, userEmail: userEmail)

        NavigationView {
            Form {
                // MARK: Total Knocks Summary
                Section(header: Text("Summary")) {
                    Text("Total Knocks: \(totalKnocks)")
                        .font(.headline)
                }

                // MARK: Knocks Grouped by List
                Section(header: Text("Knocks by List")) {
                    Chart {
                        ForEach(knocksByList.sorted(by: { $0.key < $1.key }), id: \.key) { list, total in
                            BarMark(
                                x: .value("List", list),
                                y: .value("Knocks", total)
                            )
                        }
                    }
                    .frame(height: 120)
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
}
