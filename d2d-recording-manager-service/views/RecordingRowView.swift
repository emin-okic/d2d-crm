//
//  RecordingRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI

import SwiftUI

struct RecordingRowView: View {
    var recording: Recording
    var isEditing: Bool
    @Binding var editedFileName: String
    var onRename: (String) -> Void
    var onPlayToggle: () -> Void
    var isPlaying: Bool
    var onSelect: () -> Void

    var body: some View {
        HStack(spacing: 16) {

            // MARK: - Main Content
            VStack(alignment: .leading, spacing: 8) {

                // Title / Rename
                if isEditing {
                    TextField("Recording name", text: $editedFileName, onCommit: {
                        onRename(editedFileName)
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(recording.fileName)
                        .font(.headline)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            editedFileName = recording.fileName
                            onRename("") // trigger edit mode
                        }
                }

                // Objection pill
                if let text = recording.objection?.text {
                    Text(text)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }

                // Rating
                if let rating = recording.rating {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(
                                    i < rating ? .yellow : .gray.opacity(0.4)
                                )
                        }
                    }
                }
            }

            Spacer()

            // MARK: - Play Button
            Button(action: onPlayToggle) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isPlaying ? Color.orange : Color.blue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}
