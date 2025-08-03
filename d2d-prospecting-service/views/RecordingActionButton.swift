//
//  RecordingActionButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/3/25.
//
import SwiftUI

struct RecordingActionButton: View {
    let systemName: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(color)
                    .shadow(radius: 3)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
    }
}
