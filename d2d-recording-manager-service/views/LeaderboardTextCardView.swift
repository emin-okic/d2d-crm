//
//  LeaderboardTextCardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/16/25.
//

import SwiftUI

struct LeaderboardTextCardView: View {
    let title: String
    let text: String
    let topObjections: [String] = ["Price", "Timing", "Need Approval"] // optional mini pills

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Title
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1.0)

            // Main value
            Text(text.isEmpty ? "—" : text)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal, 10)
    }
}
