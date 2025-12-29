//
//  ProspectKnockingHistoryView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/21/25.
//


import SwiftUI
import SwiftData

struct ProspectKnockingHistoryView: View {
    
    @Bindable var prospect: Prospect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if prospect.knockHistory.isEmpty {
                Text("No knocks recorded yet.")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(prospect.sortedKnocks) { knock in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(knock.status, systemImage: icon(for: knock.status))
                                        .font(.subheadline)
                                        .labelStyle(.titleAndIcon)
                                    Spacer()
                                    Text(knock.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                // Display coordinates directly since they are non-optional
                                Text("📍 \(knock.latitude, specifier: "%.5f"), \(knock.longitude, specifier: "%.5f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                }
            }
        }
        //.navigationTitle("Knocking History")
    }
    
    /// Maps knock status to a system icon.
    private func icon(for status: String) -> String {
        let lower = status.lowercased()
        if lower.contains("converted") || lower.contains("sale") {
            return "checkmark.seal.fill"
        } else if lower.contains("follow") {
            return "clock.fill"
        } else if lower.contains("wasn") || lower.contains("no answer") {
            return "house.slash.fill"
        } else if lower.contains("unqualified") {
            return "xmark.octagon.fill"
        } else {
            return "hand.tap.fill"
        }
    }
}
