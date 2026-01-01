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
        VStack(alignment: .leading, spacing: 6) {
            Text("Objection Leaderboard")
                .font(.title2.bold())

            Text("Top objections ranked by frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label("\(total) Tracked", systemImage: "chart.bar.xaxis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}
