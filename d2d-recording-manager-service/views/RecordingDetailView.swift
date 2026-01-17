//
//  RecordingDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct RecordingDetailView: View {
    @Bindable var recording: Recording
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Editing State
    @State private var tempFileName: String = ""
    @State private var showRevertConfirmation = false

    // MARK: - Audio
    @State private var audioPlayer: AVAudioPlayer?
    @State private var waveformSamples: [CGFloat] = []
    @State private var duration: TimeInterval = 1
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    
    @State private var tempTitle: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - Header Card
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Editable Title
                            TextField("Recording Title", text: $tempTitle)
                                .font(.title2.bold())
                                .textFieldStyle(.plain)
                            
                            if let text = recording.objection?.text {
                                TagView(text: text, color: .blue)
                            }
                            
                            // Always show stars, even if rating is nil or 0
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { i in
                                    Image(systemName: i < (recording.rating ?? 0) ? "star.fill" : "star")
                                        .foregroundColor(i < (recording.rating ?? 0) ? .yellow : .gray.opacity(0.4))
                                        .onTapGesture {
                                            
                                            // Haptics & sound
                                            RecordingScreenHapticsController.shared.lightTap()
                                            RecordingScreenSoundController.shared.playSound1()
                                            
                                            recording.rating = i + 1
                                            try? modelContext.save()
                                        }
                                }
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        
                        // MARK: - Playback Card
                        VStack(spacing: 16) {
                            
                            WaveformView(
                                samples: waveformSamples,
                                currentProgress: currentTime / duration
                            ) { seek(to: $0) }
                                .frame(height: 60)
                            
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(duration))
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                RecordingScreenHapticsController.shared.lightTap()
                                RecordingScreenSoundController.shared.playSound1()
                                playOrPause()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    Text(isPlaying ? "Pause" : "Play Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isPlaying ? Color.orange : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                        }
                        .padding()
                        .background(cardBackground)
                        
                    }
                    .padding()
                }
                .navigationTitle("Recording")
                .navigationBarTitleDisplayMode(.inline)
                
                
                RecordingDetailToolbarView(
                    onDeleteTapped: {
                        onDelete()
                        dismiss()
                    }
                )
                
            }

            // MARK: - Toolbar
            .toolbar {

                // ⬅️ Back Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                        RecordingScreenHapticsController.shared.lightTap()
                        RecordingScreenSoundController.shared.playSound1()
                        
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                // Save / Revert
                if hasUnsavedEdits {
                    
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        
                        Button("Revert") {
                            
                            RecordingScreenHapticsController.shared.lightTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            showRevertConfirmation = true
                        }
                        .foregroundColor(.red)

                        Button("Save") {
                            
                            RecordingScreenHapticsController.shared.successConfirmationTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            commitEdits()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
                Button("Revert", role: .destructive) {
                    
                    RecordingScreenHapticsController.shared.mediumTap()
                    RecordingScreenSoundController.shared.playSound1()
                    
                    revertEdits()
                }
                Button("Cancel", role: .cancel) {
                    
                    RecordingScreenHapticsController.shared.lightTap()
                    RecordingScreenSoundController.shared.playSound1()
                    
                }
            } message: {
                Text("This will discard any unsaved changes.")
            }
            .onAppear {
                tempTitle = recording.title
                loadAudio()
            }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        }
    }

    // MARK: - Derived State

    private var hasUnsavedEdits: Bool {
        tempTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            != recording.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.04))
            )
    }

    // MARK: - Save / Revert

    private func commitEdits() {
        let trimmed = tempTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recording.title = trimmed
        try? modelContext.save()
    }

    private func revertEdits() {
        tempTitle = recording.title
    }

    // MARK: - Audio Helpers

    func loadAudio() {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(recording.fileName)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 1
            waveformSamples = generateFakeWaveform()
        } catch {
            print("❌ Failed to load audio:", error)
        }
    }

    func playOrPause() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            timer?.invalidate()
        } else {
            player.play()
            startTimer()
        }
    }

    func seek(to progress: CGFloat) {
        guard let player = audioPlayer else { return }
        let time = Double(progress) * player.duration
        player.currentTime = time
        currentTime = time
        if !player.isPlaying { player.play() }
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            currentTime = audioPlayer?.currentTime ?? 0
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func generateFakeWaveform() -> [CGFloat] {
        (0..<100).map { _ in .random(in: 0.2...1.0) }
    }
}
