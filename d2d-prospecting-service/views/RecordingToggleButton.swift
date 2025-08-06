//
//  RecordingToggleButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/6/25.
//
import SwiftUI

struct RecordingToggleButton: View {
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @State private var showTogglePrompt = false

    var body: some View {
        Button(action: {
            showTogglePrompt = true
        }) {
            Image(systemName: recordingModeEnabled ? "mic.circle.fill" : "mic.slash.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(recordingModeEnabled ? .blue : .red)
                .opacity(recordingModeEnabled ? 1.0 : 0.5)
                .shadow(radius: 4)
        }
        .alert("Toggle Recording Mode", isPresented: $showTogglePrompt) {
            Button(recordingModeEnabled ? "Turn Off" : "Turn On") {
                recordingModeEnabled.toggle()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(recordingModeEnabled
                 ? "Would you like to disable recording mode for now?"
                 : "Would you like to enable recording mode for follow-up training?")
        }
    }
}
