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

                        // MARK: - Contact Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            associatedContactSection
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

    @ViewBuilder
    private var associatedContactSection: some View {
        if let prospect = recording.prospect {
            NavigationLink {
                ProspectDetailsView(prospect: prospect)
                    .navigationBarBackButtonHidden(true)
            } label: {
                associatedContactCard(contactType: "Prospect")
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()
            })
        } else if let customer = recording.customer {
            NavigationLink {
                CustomerDetailsView(customer: customer)
                    .navigationBarBackButtonHidden(true)
            } label: {
                associatedContactCard(contactType: "Customer")
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()
            })
        } else {
            unassociatedContactCard
        }
    }

    private func associatedContactCard(contactType: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recording.associatedContactIconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(recording.customer == nil ? .blue : .green)
                .frame(width: 34, height: 34)
                .background((recording.customer == nil ? Color.blue : Color.green).opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(contactType)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(recording.associatedContactName ?? contactType)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let address = recording.associatedContactAddress {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var unassociatedContactCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Unassociated")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("This recording was saved before contact associations were available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            Task { @MainActor in
                currentTime = audioPlayer?.currentTime ?? 0
            }
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
