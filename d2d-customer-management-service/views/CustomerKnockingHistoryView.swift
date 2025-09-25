//
//  CustomerKnockingHistoryView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI
import SwiftData

/// A view that displays the knock history for a given `Customer`.
///
/// - Shows a list of knocks in reverse chronological order (most recent first)
/// - Displays the status, date/time, and location (latitude/longitude) of each knock
/// - If no knock history exists, shows a placeholder message
struct CustomerKnockingHistoryView: View {
    
    @Bindable var customer: Customer
    
    var body: some View {
        Section {
            if customer.knockHistory.isEmpty {
                // Show message if there are no recorded knocks
                Text("No knocks recorded yet.")
                    .foregroundColor(.secondary)
            } else {
                // Iterate through the customer's sorted knock history
                ForEach(customer.sortedKnocks) { knock in
                    VStack(alignment: .leading) {
                        HStack {
                            // Knock status (e.g., Answered, Not Answered)
                            Text(knock.status)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Formatted date/time of knock
                            Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.gray)
                        }
                        
                        // Optional: show coordinates if you want
                        if knock.latitude != 0 && knock.longitude != 0 {
                            Text("📍 \(knock.latitude), \(knock.longitude)")
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
