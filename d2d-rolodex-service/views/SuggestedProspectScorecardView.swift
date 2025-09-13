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

struct SuggestedProspectBannerView: View {
    let suggestion: Prospect
    var onAdd: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Neighbor")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(suggestion.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // Buttons vertical
            VStack(spacing: 12) {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
