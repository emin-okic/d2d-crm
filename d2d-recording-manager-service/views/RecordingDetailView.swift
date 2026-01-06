//
//  RecordingDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI
import AVFoundation

struct RecordingDetailView: View {
    let recording: Recording
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var audioPlayer: AVAudioPlayer?
    @State private var waveformSamples: [CGFloat] = []
    @State private var duration: TimeInterval = 1
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recording.fileName.replacingOccurrences(of: ".m4a", with: ""))
                            .font(.title2.bold())

                        HStack(spacing: 8) {
                            if let text = recording.objection?.text {
                                TagView(text: text, color: .blue)
                            }
                        }

                        if let rating = recording.rating {
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { i in
                                    Image(systemName: i < rating ? "star.fill" : "star")
                                        .foregroundColor(i < rating ? .yellow : .gray.opacity(0.4))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(cardBackground)

                    // MARK: - Playback Card
                    VStack(spacing: 16) {

                        WaveformView(
                            samples: waveformSamples,
                            currentProgress: currentTime / duration
                        ) { tappedProgress in
                            seek(to: tappedProgress)
                        }
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

                        Button(action: playOrPause) {
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

                    // MARK: - Danger Zone
                    VStack(spacing: 8) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete Recording", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { loadAudio() }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        }
    }

    // MARK: - Helpers

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
