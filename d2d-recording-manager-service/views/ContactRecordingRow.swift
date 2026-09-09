//
//  ContactRecordingRow.swift
//  d2d-studio
//
//  Created by Codex on 9/9/26.
//

import SwiftUI

struct ContactRecordingsHistoryView: View {
    let contactName: String
    let contactType: String
    let recordings: [Recording]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRecording: Recording?
    
    private let recordingManager = RecordingManager()
    
    var body: some View {
        NavigationStack {
            List {
                if recordings.isEmpty {
                    ContentUnavailableView(
                        "No Recordings",
                        systemImage: "waveform",
                        description: Text("Recordings assigned to this \(contactType.lowercased()) will appear here.")
                    )
                } else {
                    Section {
                        ForEach(recordings) { recording in
                            Button {
                                ContactScreenHapticsController.shared.lightTap()
                                ContactScreenSoundController.shared.playSound1()
                                selectedRecording = recording
                            } label: {
                                ContactRecordingRow(recording: recording)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contactType)
                            Text(contactName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording) {
                    recordingManager.delete(recording: recording, context: modelContext)
                    selectedRecording = nil
                }
            }
        }
    }
}

struct ContactRecordingRow: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(recording.date.formatted(date: .abbreviated, time: .shortened))
                    
                    if let rating = recording.rating {
                        Text("\(rating)/5")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
