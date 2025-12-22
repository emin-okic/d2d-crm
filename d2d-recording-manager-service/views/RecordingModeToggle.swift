//
//  RecordingModeToggle.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/22/25.
//

import SwiftUI
import StoreKit

struct RecordingModeToggle: View {
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false

    @State private var pendingValue: Bool?
    @State private var showConfirm = false
    @State private var showPromo = false
    @State private var showWalkthrough = false
    @State private var showCelebration = false

    private let width: CGFloat = 44
    private let height: CGFloat = 24
    private let knobSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            Text("Recording")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                guard studioUnlocked else {
                    showPromo = true
                    return
                }

                pendingValue = !recordingModeEnabled
                showConfirm = true
            } label: {
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(recordingModeEnabled ? Color.green : Color.red)
                        .frame(width: width, height: height)

                    // Knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: knobSize, height: knobSize)
                        .offset(x: recordingModeEnabled
                                ? width - knobSize - 2
                                : 2)
                        .shadow(radius: 1)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8),
                                   value: recordingModeEnabled)
                }
            }
            .buttonStyle(.plain)
        }
        .alert("Recording Mode", isPresented: $showConfirm) {
            Button("Confirm") {
                if let pendingValue {
                    recordingModeEnabled = pendingValue
                }
                pendingValue = nil
            }
            Button("Cancel", role: .cancel) {
                pendingValue = nil
            }
        } message: {
            Text(
                (pendingValue ?? recordingModeEnabled)
                ? "Enable recording mode for knock follow-ups and training?"
                : "Disable recording mode? Recording Studio will still be available."
            )
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
            RecordingStudioWalkthrough {
                showWalkthrough = false
            }
        }
        .fullScreenCover(isPresented: $showCelebration) {
            FullScreenCelebrationView(dimOpacity: 0.08)
        }
    }
}
