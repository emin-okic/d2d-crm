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
                HStack {
                    Spacer()
                    Button(action: startRecording) {
                        VStack(spacing: 4) {
                            Image(systemName: "mic.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.red)
                                .shadow(radius: 4)

                            Text("Start Recording")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.top, 8)
            }

            if showOutcomeButtons {
                Text("Select Knock Outcome")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Spacer()
                    HStack(spacing: 16) {
                        iconButton(systemName: "house.slash.fill", label: "Not Home", color: .gray) {
                            stopAndHandleOutcome("Wasn't Home")
                        }

                        if !isCustomer {
                            iconButton(systemName: "checkmark.seal.fill", label: "Sale", color: .green) {
                                stopAndHandleOutcome("Converted To Sale")
                            }
                        }

                        iconButton(systemName: "calendar.badge.clock", label: "Follow Up", color: .orange) {
                            stopAndHandleOutcome("Follow Up Later")
                        }
                    }
                    Spacer()
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
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func findProspectName(for address: String) -> String {
        return "Prospect"
    }
}
