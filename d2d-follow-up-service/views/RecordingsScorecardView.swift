//
//  RecordingsScorecardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct RecordingsScorecardView: View {
    let unlocked: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(unlocked ? "Recordings" : "Recording Studio")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .top)

            if unlocked {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)

                    Text("Locked")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90)
        .background(
            unlocked
            ? Color(.secondarySystemBackground)
            : Color(.secondarySystemBackground).opacity(0.6)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(unlocked ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
