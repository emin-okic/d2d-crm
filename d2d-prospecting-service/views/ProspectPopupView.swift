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
                ProspectPopupOutcomeButtons(isCustomer: isCustomer) { outcome in
                    stopAndHandleOutcome(outcome)
                }
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
    
    private var formattedAddressLines: [String] {
        let parts = place.address.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if parts.count >= 3 {
            let street = parts[0] // e.g. "10320 Norfolk Dr"
            let city = parts[1]   // e.g. "Johnston"
            let stateZip = parts[2] // e.g. "IA 50131"
            return [street, "\(city), \(stateZip)"]
        }

        // fallback if address isn't comma-separated
        let words = place.address.components(separatedBy: " ")
        if words.count >= 5 {
            let street = words.prefix(3).joined(separator: " ") // e.g. "10320 Norfolk Dr"
            let rest = words.dropFirst(3).joined(separator: " ") // "Johnston IA 50131"
            return [street, rest]
        }

        return [place.address]
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
