//
//  CustomerPopupView.swift
//  d2d-studio
//

import SwiftUI
import SwiftData

struct CustomerPopupView: View {
    @Query private var customers: [Customer]

    let place: IdentifiablePlace
    var onClose: () -> Void
    var onOutcomeSelected: (String, String?) -> Void
    let recordingModeEnabled: Bool
    var onViewDetails: () -> Void

    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    @State private var isRecording = false
    @State private var currentFileName: String?

    private let recorder = RecordingManager()
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            customerRow
            actionsSection
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if recordingFeaturesActive {
                startRecording()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Customer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)

                    if isRecording {
                        Label("Recording", systemImage: "waveform")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1), in: Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(formattedAddressLines, id: \.self) { line in
                        Text(line)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
            }

            Spacer(minLength: 0)

            Button(action: closePopup) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var customerRow: some View {
        Button(action: openCustomerDetails) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 34, height: 34)
                    .background(Color.green.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(customerName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(place.count) \(place.count == 1 ? "knock" : "knocks") logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log Customer Knock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                actionButton(
                    systemName: "person.crop.circle.badge.xmark",
                    label: "Lost",
                    color: .red
                ) { stopAndHandleOutcome("Customer Lost") }

                actionButton(
                    systemName: "house.slash.fill",
                    label: "Not Home",
                    color: .gray
                ) { stopAndHandleOutcome("Wasn't Home") }

                actionButton(
                    systemName: "calendar.badge.clock",
                    label: "Follow Up",
                    color: .orange
                ) { stopAndHandleOutcome("Follow Up Later") }
            }
        }
    }

    private func actionButton(systemName: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.11), in: Circle())

                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

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

    private var customerName: String {
        if case .customer(let customer)? = place.selectedContact {
            return customer.fullName
        }

        return customers.first(where: { $0.address == place.address })?.fullName ?? "Customer"
    }

    private func closePopup() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onClose()
    }

    private func openCustomerDetails() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onViewDetails()
    }

    private func startRecording() {
        let result = recorder.start()
        if result.started {
            isRecording = true
            currentFileName = result.fileName
        }
    }

    private func stopAndHandleOutcome(_ outcome: String) {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()

        recorder.stop()
        isRecording = false

        if outcome == "Wasn't Home" {
            discardRecording()
            onOutcomeSelected(outcome, nil)
        } else {
            onOutcomeSelected(outcome, currentFileName)
        }

        currentFileName = nil
    }

    private func discardRecording() {
        if let file = currentFileName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
