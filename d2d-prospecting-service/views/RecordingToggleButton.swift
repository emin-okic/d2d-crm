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
    @State private var showCelebration = false

    var body: some View {
        Button {
            if studioUnlocked { showTogglePrompt = true } else { showPromo = true }
        } label: {
            Group {
                if studioUnlocked {
                    UnlockedMicIcon(isOn: recordingModeEnabled)   // ✅ new style you liked
                } else {
                    HiddenMicIcon()                               // ✅ old hidden style you liked
                }
            }
        }
        .alert("Toggle Recording Mode", isPresented: $showTogglePrompt) {
            Button(recordingModeEnabled ? "Turn Off" : "Turn On") { recordingModeEnabled.toggle() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(recordingModeEnabled
                 ? "Disable recording mode for now?"
                 : "Enable recording mode for follow-up training?")
        }
        .sheet(isPresented: $showPromo) {
            RecordingStudioPromo {
                studioUnlocked = true
                showPromo = false
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
        .fullScreenCover(isPresented: $showCelebration) {
            FullScreenCelebrationView(dimOpacity: 0.08)
        }
    }
}

private struct HiddenMicIcon: View {
    var body: some View {
        Image(systemName: "mic.circle.fill")
            .resizable()
            .frame(width: 48, height: 48)
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(Color(.darkGray))
            .shadow(radius: 4)
    }
}

private struct UnlockedMicIcon: View {
    let isOn: Bool
    var body: some View {
        Image(systemName: "mic.circle.fill")
            .resizable()
            .frame(width: 48, height: 48)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                .white,          // mic glyph
                isOn ? .blue : .red  // circle color when unlocked: blue(on)/red(off)
            )
            .shadow(radius: 4)
    }
}
