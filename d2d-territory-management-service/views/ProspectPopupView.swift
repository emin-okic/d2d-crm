//
//  ProspectPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/26/25.
//

import SwiftUI
import MapKit

struct ProspectPopupView: View {
    let place: IdentifiablePlace
    let isCustomer: Bool
    var onClose: () -> Void
    var onOutcomeSelected: (String, String?) -> Void

    // Passed from parent (on/off)
    let recordingModeEnabled: Bool
    // Also check if the studio is unlocked (hidden == locked)
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    @State private var isRecording = false
    @State private var showOutcomeButtons = false
    @State private var currentFileName: String?

    private let recorder = RecordingManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(formattedAddressLines, id: \.self) { line in
                    Text(line)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 5)

            Text("Name: \(findProspectName(for: place.address))")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)

            Divider().padding(.vertical, 4)

            // When features are active: show Record/Skip first, then outcomes.
            // When locked or off: always show outcomes (no recording UI).
            if recordingFeaturesActive {
                if !isRecording && !showOutcomeButtons {
                    HStack(spacing: 24) {
                        Spacer()

                        recordingActionButton(
                            systemName: "mic.circle.fill",
                            label: "Start Recording",
                            color: .red,
                            action: startRecording
                        )

                        recordingActionButton(
                            systemName: "arrowshape.turn.up.right.circle.fill",
                            label: "Skip Recording",
                            color: .blue,
                            action: { showOutcomeButtons = true }
                        )

                        Spacer()
                    }
                }

                if showOutcomeButtons {
                    outcomeHeader
                    outcomeButtons
                }
            } else {
                // Locked or turned off: act like recording is off and show outcomes only
                outcomeHeader
                outcomeButtons
            }
        }
        .onAppear {
            if !recordingFeaturesActive {
                showOutcomeButtons = true
            }
        }
        .padding()
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .cornerRadius(16)
        .shadow(radius: 6)
    }

    // MARK: - Subviews

    private var outcomeHeader: some View {
        Text("Select Knock Outcome")
            .font(.caption)
            .foregroundColor(.gray)
    }

    private var outcomeButtons: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            
            // 🔴 UNQUALIFIED PROSPECT FLOW
            if place.isUnqualified && !isCustomer {

                iconButton(
                    systemName: "house.slash.fill",
                    label: "Wasn't Home",
                    color: .gray
                ) {
                    stopAndHandleOutcome("Wasn't Home")
                }

                iconButton(
                    systemName: "arrow.uturn.backward.circle.fill",
                    label: "Requalified",
                    color: .green
                ) {
                    stopAndHandleOutcome("Requalified")
                }

                // return
            }
            
            if !isCustomer && !place.isUnqualified {
                
                iconButton(
                    systemName: "xmark.octagon.fill",
                    label: "Unqualified",
                    color: .red
                ) {
                    stopAndHandleOutcome("Unqualified")
                }
                
                iconButton(
                    systemName: "house.slash.fill",
                    label: "Not Home",
                    color: .gray
                ) {
                    stopAndHandleOutcome("Wasn't Home")
                }

                iconButton(
                    systemName: "calendar.badge.clock",
                    label: "Follow Up",
                    color: .orange
                ) {
                    stopAndHandleOutcome("Follow Up Later")
                }
                
                iconButton(
                    systemName: "checkmark.seal.fill",
                    label: "Sale",
                    color: .green
                ) {
                    stopAndHandleOutcome("Converted To Sale")
                }
            }
            
            if isCustomer {
                
                iconButton(
                    systemName: "house.slash.fill",
                    label: "Not Home",
                    color: .gray
                ) {
                    stopAndHandleOutcome("Wasn't Home")
                }

                iconButton(
                    systemName: "calendar.badge.clock",
                    label: "Follow Up",
                    color: .orange
                ) {
                    stopAndHandleOutcome("Follow Up Later")
                }
                
            }
            
        }
        .padding(.top, 4)
    }

    private func recordingActionButton(systemName: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(color)
                    .shadow(radius: 3)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconButton(systemName: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var formattedAddressLines: [String] {
        let parts = place.address.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if parts.count >= 3 {
            let street = parts[0]
            let city = parts[1]
            let stateZip = parts[2]
            return [street, "\(city), \(stateZip)"]
        }

        let words = place.address.components(separatedBy: " ")
        if words.count >= 5 {
            let street = words.prefix(3).joined(separator: " ")
            let rest = words.dropFirst(3).joined(separator: " ")
            return [street, rest]
        }

        return [place.address]
    }

    private func startRecording() {
        // If locked/off, just reveal outcomes; do not attempt to start recording
        guard recordingFeaturesActive else {
            showOutcomeButtons = true
            return
        }

        let result = recorder.start()
        if result.started {
            isRecording = true
            currentFileName = result.fileName
            showOutcomeButtons = true
        }
    }

    private func stopAndHandleOutcome(_ outcome: String) {
        recorder.stop()
        isRecording = false

        if outcome == "Wasn't Home" {
            discardRecording()
            onOutcomeSelected(outcome, nil)
        } else {
            onOutcomeSelected(outcome, currentFileName)
        }

        currentFileName = nil
        showOutcomeButtons = false
    }

    private func discardRecording() {
        if let file = currentFileName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func findProspectName(for address: String) -> String {
        return "Prospect"
    }
}
