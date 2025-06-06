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
    @Query var prospects: [Prospect]
    @Binding var isLoggedIn: Bool

    var body: some View {
        let totalKnocks = ProfileController.totalKnocks(from: prospects)
        let knocksByList = ProfileController.knocksByList(from: prospects)
        let answeredVsUnanswered = ProfileController.knocksAnsweredVsUnanswered(from: prospects)

        NavigationView {
            Form {
                Section(header: Text("Summary")) {
                    Text("Total Knocks: \(totalKnocks)")
                        .font(.headline)
                }

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
