//
//  SuggestedProspectScorecardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI

struct SuggestedProspectScorecardView: View {
    let suggestion: Prospect
    var onAdd: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text("Suggested Neighbor")
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Details
                VStack(alignment: .leading, spacing: 6) {
                    Label("Potential Lead", systemImage: "person.fill")
                    Label(suggestion.address, systemImage: "mappin.and.ellipse")
                }
                .foregroundStyle(.secondary)

                // CTA
                Button(action: onAdd) {
                    Label("Add Prospect", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120) // medium widget-ish
            .background(
                // Depth + soft stroke like an Apple widget
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
            )

            // Dismiss (X)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss suggestion")
        }
    }
}
