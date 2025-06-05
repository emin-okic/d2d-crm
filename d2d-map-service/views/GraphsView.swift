//
//  GraphsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import SwiftUI
import Charts
import SwiftData

struct GraphView: View {
    @Query var prospects: [Prospect]

    var body: some View {
        let totalKnocks = GraphController.totalKnocks(from: prospects)
        let knocksByList = GraphController.knocksByList(from: prospects)
        let answeredVsUnanswered = GraphController.knocksAnsweredVsUnanswered(from: prospects)

        NavigationView {
            VStack {
                Text("Total Knocks: \(totalKnocks)")
                    .font(.title2)
                    .padding(.bottom)

                Chart {
                    ForEach(knocksByList.sorted(by: { $0.key < $1.key }), id: \.key) { list, total in
                        BarMark(
                            x: .value("List", list),
                            y: .value("Knocks", total)
                        )
                    }
                }
                .frame(height: 120)
                .padding()

                Text("Answered vs Unanswered Knocks")
                    .font(.headline)
                    .padding(.top)

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
                .padding()

                Spacer()
            }
            .navigationTitle("Knock Report")
        }
    }
}


