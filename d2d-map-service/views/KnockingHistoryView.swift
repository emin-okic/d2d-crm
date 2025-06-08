//
//  KnockingHistoryView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/5/25.
//

import SwiftUI
import SwiftData

/// A view that displays the knock history for a given `Prospect`.
///
/// - Shows a list of knocks in reverse chronological order (most recent first)
/// - Displays the status, date/time, and location (latitude/longitude) of each knock
/// - If no knock history exists, shows a placeholder message
struct KnockingHistoryView: View {
    
    /// The prospect whose knock history is being displayed.
    @Bindable var prospect: Prospect
    
    var body: some View {
        Section() {
            if prospect.knockHistory.isEmpty {
                // Show message if there are no recorded knocks
                Text("No knocks recorded yet.")
                    .foregroundColor(.secondary)
            } else {
                // Iterate through the prospect's sorted knock history
                ForEach(prospect.sortedKnocks) { knock in
                    VStack(alignment: .leading) {
                        HStack {
                            // Knock status (e.g., Answered, Not Answered)
                            Text(knock.status)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Formatted date/time of knock
                            Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // Display knock location coordinates
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
