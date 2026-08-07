//
//  TripManagerScorecardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/7/26.
//

import SwiftUI

struct TripManagerScorecardView: View {
    let title: String
    let count: Int
    let action: () -> Void

    private let accentColor: Color = .orange

    var body: some View {
        Button {
            FollowUpScreenHapticsController.shared.lightTap()
            FollowUpScreenSoundController.shared.playSound1()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(accentColor.opacity(0.14)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(count)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
                    .shadow(color: accentColor.opacity(0.14), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), accentColor.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
