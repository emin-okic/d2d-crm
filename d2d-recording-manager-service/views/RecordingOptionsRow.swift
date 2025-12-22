//
//  RecordingOptionsRow.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/22/25.
//

import SwiftUI

struct RecordingOptionsRow: View {
    let onAddRecording: () -> Void
    let onDelete: () -> Void
    let isEditing: Bool

    var body: some View {
        HStack(spacing: 16) {

            Button {
                onAddRecording()
            } label: {
                option(
                    icon: "mic.fill",
                    label: "Record",
                    color: .blue
                )
            }

            Button {
                onDelete()
            } label: {
                option(
                    icon: "trash.fill",
                    label: isEditing ? "Done" : "Delete",
                    color: .red
                )
            }
        }
    }

    private func option(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(color)
    }
}
