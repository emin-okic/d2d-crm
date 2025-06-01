//
//  GraphsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import SwiftUI
import Charts

struct GraphView: View {
    var prospects: [Prospect]

    var body: some View {
        let totalKnocks = GraphController.totalKnocks(from: prospects)
        let knocksByList = GraphController.knocksByList(from: prospects)
        
        return NavigationView {
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
                
                Spacer()
            }
            .navigationTitle("Knock Report")
        }
    }
}

