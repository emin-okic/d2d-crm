//
//  RecordingNowCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/16/25.
//
import SwiftUI
import AVFoundation
import SwiftData
import Speech

struct RecordingNowCard: View {
    let objectionText: String?
    let elapsed: TimeInterval
    let onStop: () -> Void

    @State private var phase: CGFloat = 0
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 14) {
            // Top row: pulsing red dot + timer
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulsing ? 1.25 : 0.9)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)

                Text(timeString(from: elapsed))
                    .font(.system(.title3, design: .rounded)).monospacedDigit()
                    .fontWeight(.semibold)
            }

            // Objection chip (optional)
            if let text = objectionText, !text.isEmpty {
                Text(text)
                    .font(.footnote).fontWeight(.medium)
                    .padding(.vertical, 6).padding(.horizontal, 12)
                    .background(Capsule().fill(Color(.secondarySystemBackground)))
            }

            // Animated “waveform”
            InProgRecordingWaveView()
                .frame(height: 36)
                .padding(.horizontal, 18)

            // Stop button
            Button(action: onStop) {
                Label("Stop Recording", systemImage: "stop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.red)
                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                )
        )
        .onAppear { pulsing = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recording in progress")
    }

    private func timeString(from interval: TimeInterval) -> String {
        let total = Int(interval)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct InProgRecordingWaveView: View {
    // 14 bars with slight phase offsets for a “live” look
    private let barCount = 14
    @State private var t: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let _ = update(timeline.date.timeIntervalSinceReferenceDate)

            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule()
                        .fill(Color.blue.opacity(0.9))
                        .frame(width: 6, height: barHeight(for: i))
                        .animation(.easeInOut(duration: 0.25), value: t)
                }
            }
        }
    }

    private func update(_ now: TimeInterval) { t = CGFloat(now) }

    private func barHeight(for index: Int) -> CGFloat {
        // Sine waves with staggered phase/frequency = subtle lively motion
        let base: CGFloat = 12
        let amp: CGFloat = 18
        let speed: CGFloat = 1.6
        let phase = (CGFloat(index) * 0.45)
        let v = sin(t * speed + phase) * 0.5 + 0.5  // 0...1
        return base + amp * v
    }
}
