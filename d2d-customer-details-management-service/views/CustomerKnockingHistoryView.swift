//
//  CustomerKnockingHistoryView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData

struct CustomerKnockingHistoryView: View {
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if customer.knockHistory.isEmpty {
                Text("No knock history yet.")
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(customer.knockHistory.sorted(by: { $0.date > $1.date })) { knock in
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

                                // Always show coordinates since they're non-optional
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
        .navigationTitle("Knocking History")
    }

    private func icon(for status: String) -> String {
        let lower = status.lowercased()
        if lower.contains("converted") || lower.contains("sale") {
            return "checkmark.seal.fill"
        } else if lower.contains("follow") {
            return "clock.fill"
        } else if lower.contains("wasn") || lower.contains("no answer") {
            return "house.slash.fill"
        } else {
            return "hand.tap.fill"
        }
    }
}
