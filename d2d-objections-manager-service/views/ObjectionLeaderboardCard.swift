//
//  ObjectionLeaderboardCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionLeaderboardCard: View {
    let ranked: RankedObjection
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                }

                RankBadge(rank: ranked.rank)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ranked.objection.text)
                        .font(.headline)

                    Text("Heard \(ranked.objection.timesHeard) times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
