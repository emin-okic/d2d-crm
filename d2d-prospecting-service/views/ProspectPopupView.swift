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
    var onClose: () -> Void
    var onOutcomeSelected: (String, String?) -> Void  // Includes optional fileName

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

            Text(place.address)
                .font(.headline)
                .multilineTextAlignment(.leading)

            Text("Name: \(findProspectName(for: place.address))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider().padding(.vertical, 4)

            if !isRecording && !showOutcomeButtons {
                Button(action: startRecording) {
                    Label("Start Recording", systemImage: "mic.circle.fill")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
            } else if isRecording {
                Button(action: stopRecording) {
                    Label("Stop Recording", systemImage: "stop.circle.fill")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                }
            } else if showOutcomeButtons {
                Text("Select Knock Outcome")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 16) {
                    iconButton(systemName: "house.slash.fill", label: "Not Home", color: .gray) {
                        discardRecording()
                        onOutcomeSelected("Wasn't Home", nil)
                    }

                    iconButton(systemName: "checkmark.seal.fill", label: "Sale", color: .green) {
                        onOutcomeSelected("Converted To Sale", currentFileName)
                    }

                    iconButton(systemName: "calendar.badge.clock", label: "Follow Up", color: .orange) {
                        onOutcomeSelected("Follow Up Later", currentFileName)
                    }
                }
                .padding(.top, 4)
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

    private func startRecording() {
        let result = recorder.start()
        if result.started {
            isRecording = true
            currentFileName = result.fileName
        }
    }

    private func stopRecording() {
        recorder.stop()
        isRecording = false
        showOutcomeButtons = true
    }

    private func discardRecording() {
        if let file = currentFileName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
        currentFileName = nil
        showOutcomeButtons = false
        isRecording = false
    }

    private func findProspectName(for address: String) -> String {
        return "Prospect"
    }
}
