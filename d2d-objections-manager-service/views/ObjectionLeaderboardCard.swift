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
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                        .symbolEffect(.bounce, value: isSelected)
                        .transition(.scale.combined(with: .opacity))
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

                if !isEditing {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.10) : Color(.systemBackground))
                    .shadow(
                        color: isSelected ? Color.blue.opacity(0.12) : Color.black.opacity(0.06),
                        radius: isSelected ? 7 : 4,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue.opacity(0.75) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.easeInOut(duration: 0.16), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
