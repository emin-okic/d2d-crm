//
//  RecordingRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

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
        HStack {
            VStack(alignment: .leading) {
                if isEditing {
                    TextField("Enter name", text: $editedFileName, onCommit: {
                        onRename(editedFileName)
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(recording.fileName)
                        .font(.headline)
                        .onTapGesture(count: 2) {
                            editedFileName = recording.fileName
                            onRename("") // trigger edit mode in parent
                        }
                }

                if let text = recording.objection?.text {
                    Text("Objection: \(text)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let rating = recording.rating {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < rating ? "star.fill" : "star")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(i < rating ? .yellow : .gray.opacity(0.4))
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            Button(action: onPlayToggle) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}
