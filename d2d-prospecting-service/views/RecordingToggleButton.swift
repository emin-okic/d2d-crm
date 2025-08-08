//
//  RecordingToggleButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/6/25.
//

import SwiftUI
import StoreKit

struct RecordingToggleButton: View {
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false

    @State private var showTogglePrompt = false
    @State private var showPromo = false
    @State private var showWalkthrough = false

    // NEW: full-screen celebration instead of overlay
    @State private var showCelebration = false

    var body: some View {
        Button(action: {
            if studioUnlocked {
                showTogglePrompt = true
            } else {
                showPromo = true
            }
        }) {
            Image(systemName: "mic.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(studioUnlocked ? (recordingModeEnabled ? .blue : .red) : .gray)
                .opacity(studioUnlocked ? (recordingModeEnabled ? 1.0 : 0.5) : 0.35)
                .symbolRenderingMode(.hierarchical)
                .shadow(radius: 4)
        }
        .alert("Toggle Recording Mode", isPresented: $showTogglePrompt) {
            Button(recordingModeEnabled ? "Turn Off" : "Turn On") { recordingModeEnabled.toggle() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(recordingModeEnabled
                 ? "Disable recording mode for now?"
                 : "Enable recording mode for follow-up training?")
        }
        .sheet(isPresented: $showPromo) {
            RecordingStudioPromo {
                // onUnlock
                studioUnlocked = true
                showPromo = false

                // 👉 Full-screen dim + confetti
                showCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    showCelebration = false
                    showWalkthrough = true
                }
            }
        }
        .sheet(isPresented: $showWalkthrough) {
            RecordingStudioWalkthrough { showWalkthrough = false }
        }
        // NEW: the full-screen cover that dims and shows confetti
        .fullScreenCover(isPresented: $showCelebration) {
            FullScreenCelebrationView()
        }
    }
}
