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
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(recording.fileName.replacingOccurrences(of: ".m4a", with: ""))
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    if let text = recording.objection?.text {
                        Text("Objection: \(text)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rating = recording.rating {
                        HStack(spacing: 12) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < rating ? "star.fill" : "star")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(i < rating ? .yellow : .gray.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top)

                WaveformView(samples: waveformSamples, currentProgress: currentTime / duration) { tappedProgress in
                    seek(to: tappedProgress)
                }
                .frame(height: 60)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )

                // Time and controls
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption.monospacedDigit())
                    Spacer()
                    Text(formatTime(duration))
                        .font(.caption.monospacedDigit())
                }
                .padding(.horizontal)

                Button(action: playOrPause) {
                    Image(systemName: (audioPlayer?.isPlaying ?? false) ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.blue)
                        .shadow(radius: 4)
                }
                .padding(.vertical)

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Label("Delete Recording", systemImage: "trash")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadAudio()
            }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        }
    }

    func loadAudio() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(recording.fileName)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 1
            waveformSamples = generateFakeWaveform()
        } catch {
            print("Failed to load audio: \(error)")
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
        if !player.isPlaying {
            player.play()
        }
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
