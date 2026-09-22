//
//  LeaderboardHeaderView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI


struct LeaderboardHeaderView: View {
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title & subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Objection Leaderboard")
                    .font(.title2.bold())
                Text("Top objections tracked by frequency")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Big total
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(total)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                Text("Total Tracked")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

        }
        .padding()
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
        .padding(.horizontal)
    }
}
