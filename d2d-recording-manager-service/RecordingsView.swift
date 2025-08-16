//
//  RecordingsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI
import AVFoundation
import SwiftData
import Speech

struct RecordingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recordings: [Recording]
    @Query private var objections: [Objection]

    @State private var isRecording = false
    @State private var selectedObjection: Objection?
    @State private var currentFileName: String?
    @State private var showingObjectionPicker = false
    @State private var currentlyPlayingFile: String?
    @State private var selectedRecording: Recording?

    @State private var editingRecording: Recording?
    @State private var editedFileName: String = ""
    
    @State private var isEditing = false
    @State private var selectedRecordings: Set<Recording> = []

    private let recorder = RecordingManager()
    private let playback = PlaybackManager()
    private let transcriber = Transcriber()
    private let scorer = PitchAnalyzer()

    var body: some View {
        NavigationView {
            ZStack {
                // ========= MAIN CONTENT =========
                VStack(alignment: .leading, spacing: 12) {
                    // Header (no trailing buttons now)
                    // Header
                    VStack(alignment: .center, spacing: 5) {
                        Text("Recent Conversations")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("\(totalRecordings) Recordings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // List
                    if recordings.isEmpty {
                        Text("No Recordings Yet")
                            .font(.title3)                // bigger, like a subtitle
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)  // subtle but readable
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)       // more breathing room
                        
                    } else {
                        List {
                            ForEach(recordings) { recording in
                                HStack {
                                    if isEditing {
                                        Image(systemName: selectedRecordings.contains(recording) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.blue)
                                            .onTapGesture {
                                                toggleSelection(for: recording)
                                            }
                                    }

                                    RecordingRowView(
                                        recording: recording,
                                        isEditing: editingRecording?.id == recording.id,
                                        editedFileName: $editedFileName,
                                        onRename: { newName in
                                            if newName.isEmpty {
                                                editingRecording = recording
                                            } else {
                                                recorder.rename(recording: recording, to: newName)
                                                editingRecording = nil
                                            }
                                        },
                                        onPlayToggle: {
                                            playback.toggle(fileName: recording.fileName, currentlyPlayingFile: $currentlyPlayingFile)
                                        },
                                        isPlaying: currentlyPlayingFile == recording.fileName,
                                        onSelect: {
                                            if isEditing {
                                                toggleSelection(for: recording)
                                            } else {
                                                selectedRecording = recording
                                            }
                                        }
                                    )
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .padding(.horizontal, 20)
                    }

                    if isRecording {
                        recordingIndicator
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 0)
                }

                // ========= FLOATING BOTTOM-LEFT TOOLBAR =========
                VStack(spacing: 12) {
                    // Add Recording (top)
                    Button {
                        showingObjectionPicker = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }

                    // Trash (bottom)
                    Button {
                        if isEditing, !selectedRecordings.isEmpty {
                            deleteSelected()
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isEditing.toggle()
                                if !isEditing { selectedRecordings.removeAll() }
                            }
                        }
                    } label: {
                        Image(systemName: (isEditing && !selectedRecordings.isEmpty) ? "trash.fill" : "trash")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel(isEditing ? "Delete selected recordings" : "Edit / select recordings")
                }
                .padding(.bottom, 30)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .zIndex(999)
            }
            // Sheets stay the same
            .sheet(isPresented: $showingObjectionPicker) {
                ObjectionPickerView(objections: objections) { selected in
                    selectedObjection = selected
                    startRecording()
                    showingObjectionPicker = false
                }
            }
            .sheet(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording) {
                    recorder.delete(recording: recording, context: modelContext)
                    selectedRecording = nil
                }
            }
        }
    }
    
    private var totalRecordings: Int {
        recordings.count
    }

    private var averageScore: Double {
        let scores = recordings.compactMap { Double($0.rating ?? 0) }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private var header: some View {
        HStack {
            Text("Recordings")
                .font(.headline)
            Spacer()
            Button {
                isEditing.toggle()
                if !isEditing {
                    selectedRecordings.removeAll()
                }
            } label: {
                Image(systemName: isEditing ? "xmark.circle.fill" : "trash")
                    .font(.title3)
            }

            if isEditing {
                Button {
                    deleteSelected()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                }
                .disabled(selectedRecordings.isEmpty)
            }

            Button {
                showingObjectionPicker = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
    }

    private var recordingIndicator: some View {
        VStack(spacing: 8) {
            if let text = selectedObjection?.text {
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
            }

            Button("Stop Recording") {
                if let fileName = currentFileName {
                    stopRecording(fileName: fileName)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    func startRecording() {
        let result = recorder.start()
        currentFileName = result.fileName
        isRecording = result.started
    }

    func stopRecording(fileName: String) {
        recorder.stop()
        isRecording = false

        guard let url = recorder.url(for: fileName) else { return }

        transcriber.transcribe(url: url) { transcription in
            DispatchQueue.main.async {
                let expected = selectedObjection?.response ?? ""
                let score = transcription.map { scorer.score(user: $0, expected: expected) }

                let newRecording = Recording(
                    fileName: fileName,
                    date: Date(),
                    objection: selectedObjection,
                    rating: score
                )

                modelContext.insert(newRecording)
            }
        }

        currentFileName = nil
    }
    
    private func toggleSelection(for recording: Recording) {
        if selectedRecordings.contains(recording) {
            selectedRecordings.remove(recording)
        } else {
            selectedRecordings.insert(recording)
        }
    }

    private func deleteSelected() {
        for rec in selectedRecordings {
            recorder.delete(recording: rec, context: modelContext)
        }
        selectedRecordings.removeAll()
    }
}
