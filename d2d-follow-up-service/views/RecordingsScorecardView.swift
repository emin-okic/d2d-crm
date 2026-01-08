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
    let action: () -> Void   // ✅ Add action parameter

    var body: some View {
        Button(action: action) { // ✅ Use action here
            HStack(spacing: 12) {
                
                Image(systemName: unlocked ? "mic.fill" : "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(unlocked ? .blue : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(unlocked ? "Recordings" : "Recording Studio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if unlocked {
                        Text("\(count)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text("Locked")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: 72)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(unlocked ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
