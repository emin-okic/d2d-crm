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
    
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false
    
    @State private var recordingStart: Date?
    private var elapsed: TimeInterval {
        guard let start = recordingStart, isRecording else { return 0 }
        return nowTick.timeIntervalSince(start)    // 👈 recomputes as nowTick advances
    }
    @State private var nowTick = Date()            // 👈 drives elapsed updates
    @State private var level: CGFloat = 0          // 👈 live audio level 0...1
    @State private var tickTimer: Timer?           // 👈 timer ref so we can stop it
    
    @State private var recordingOptionsExpanded = false

    var body: some View {
        NavigationView {
            ZStack {
                // ========= MAIN CONTENT =========
                VStack(alignment: .leading, spacing: 12) {

                    
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
                    
                    if isRecording {
                        RecordingNowCard(
                            objectionText: selectedObjection?.text,
                            elapsed: elapsed,
                            level: level,                          // 👈 new param
                            onStop: {
                                if let fileName = currentFileName {
                                    stopRecording(fileName: fileName)
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

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
                                .padding(.vertical, 5)
                                .background(
                                            (isEditing && selectedRecordings.contains(recording))
                                            ? Color.red.opacity(0.06)
                                            : Color.clear
                                        )
                            }
                        }
                        .listStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }

                // ========= FLOATING BOTTOM-LEFT TOOLBAR =========
                VStack(spacing: 12) {
                    
                    ExpandableOptionsMenu(isExpanded: $recordingOptionsExpanded) {
                        RecordingOptionsRow(
                            onAddRecording: {
                                recordingOptionsExpanded = false
                                showingObjectionPicker = true
                            },
                            onDelete: {
                                recordingOptionsExpanded = false

                                if isEditing {
                                    if selectedRecordings.isEmpty {
                                        isEditing = false
                                        trashPulse = false
                                    } else {
                                        showDeleteConfirm = true
                                    }
                                } else {
                                    isEditing = true
                                    trashPulse = true
                                }
                            },
                            isEditing: isEditing
                        )
                    }
                    
                }
                .padding(.bottom, 30)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .zIndex(999)
            }
            .alert("Delete selected recordings?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteSelected()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isEditing = false
                        trashPulse = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action can’t be undone.")
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
        if result.started {
            recordingStart = Date()
            // start UI tick + level polling
            tickTimer?.invalidate()
            tickTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                nowTick = Date()                   // 👈 forces body update for timer
                level = recorder.currentLevel()    // 👈 pull mic level
            }
            RunLoop.current.add(tickTimer!, forMode: .common)
        }
    }

    func stopRecording(fileName: String) {
        recorder.stop()
        isRecording = false
        recordingStart = nil
        tickTimer?.invalidate()                    // 👈 stop ticking/polling
        tickTimer = nil
        level = 0

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
