//
//  KnockingHistoryView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/5/25.
//

import SwiftUI
import SwiftData

struct KnockingHistoryView: View {
    
    @Bindable var prospect: Prospect
    
    var body: some View {
        Section(header: Text("Knock History")) {
            if prospect.knockHistory.isEmpty {
                Text("No knocks recorded yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(prospect.sortedKnocks) { knock in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(knock.status).fontWeight(.semibold)
                            Spacer()
                            Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Lat: \(String(format: "%.4f", knock.latitude)), Lon: \(String(format: "%.4f", knock.longitude))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
