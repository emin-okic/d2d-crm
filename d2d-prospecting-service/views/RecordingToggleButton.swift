//
//  RecordingToggleButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/6/25.
//


import SwiftUI

struct RecordingToggleButton: View {
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true

    var body: some View {
        Button(action: {
            recordingModeEnabled.toggle()
        }) {
            Image(systemName: recordingModeEnabled ? "mic.circle.fill" : "mic.slash.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(recordingModeEnabled ? .blue : .red)
                .opacity(recordingModeEnabled ? 1.0 : 0.5)
                .shadow(radius: 4)
        }
    }
}
