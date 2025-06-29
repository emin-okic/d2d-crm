//
//  RecordingsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
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
            VStack(spacing: 16) {
                header

                if isRecording {
                    recordingIndicator
                }

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
                    }
                }
                
            }
            .padding()
            .navigationTitle("")
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

    private var header: some View {
        HStack {
            Text("Recordings")
                .font(.largeTitle.bold())
            Spacer()

            // Always visible trash icon
            Button {
                isEditing.toggle()
                if !isEditing {
                    selectedRecordings.removeAll()
                }
            } label: {
                Image(systemName: isEditing ? "xmark.circle.fill" : "trash")
                    .font(.title2)
                    .padding(8)
                    .background(isEditing ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                    .clipShape(Circle())
                    .foregroundColor(isEditing ? .gray : .red)
            }

            // Only shows delete if editing is active
            if isEditing {
                Button {
                    deleteSelected()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(selectedRecordings.isEmpty)
            }

            // Add button
            Button {
                showingObjectionPicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
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
