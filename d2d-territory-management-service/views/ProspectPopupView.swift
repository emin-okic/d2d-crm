//
//  ProspectPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/26/25.
//

import SwiftUI
import MapKit
import SwiftData

struct ProspectPopupView: View {
    
    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    
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
    
    var onViewDetails: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                contactRow
                propertySummary

                if recordingFeaturesActive {
                    if showOutcomeButtons {
                        outcomesSection
                    }
                } else {
                    outcomesSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if recordingFeaturesActive {
                startRecording()
            } else {
                showOutcomeButtons = true
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: statusIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)

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

    private var contactRow: some View {
        Button(action: openContactDetails) {
            HStack(spacing: 12) {
                Image(systemName: isCustomer ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(findProspectName())
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("View contact timeline and details")
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

    private var propertySummary: some View {
        HStack(spacing: 10) {
            metricTile(value: "\(place.count)", label: knockSubtitle, systemName: "hand.tap.fill", tint: place.markerColor)
            metricTile(value: "\(place.contactCount)", label: place.contactCount == 1 ? "Contact" : "Contacts", systemName: "person.2.fill", tint: .blue)
            metricTile(value: "\(place.unitCount)", label: place.unitCount == 1 ? "Unit" : "Units", systemName: "building.2.fill", tint: .indigo)
        }
    }

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Log Knock Outcome")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            outcomeButtons
        }
    }

    @ViewBuilder
    private var outcomeButtons: some View {
        if !isCustomer {
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: 8) {
                if place.isUnqualified {
                    iconButton(
                        systemName: "house.slash.fill",
                        label: "Not Home",
                        color: .gray
                    ) { stopAndHandleOutcome("Wasn't Home") }

                    iconButton(
                        systemName: "arrow.uturn.backward.circle.fill",
                        label: "Requalified",
                        color: .green
                    ) { stopAndHandleOutcome("Requalified") }
                } else {
                    iconButton(
                        systemName: "xmark.octagon.fill",
                        label: "Unqualified",
                        color: .red
                    ) { stopAndHandleOutcome("Unqualified") }

                    iconButton(
                        systemName: "house.slash.fill",
                        label: "Not Home",
                        color: .gray
                    ) { stopAndHandleOutcome("Wasn't Home") }

                    iconButton(
                        systemName: "calendar.badge.clock",
                        label: "Follow Up",
                        color: .orange
                    ) { stopAndHandleOutcome("Follow Up Later") }

                    iconButton(
                        systemName: "checkmark.seal.fill",
                        label: "Sale",
                        color: .green
                    ) { stopAndHandleOutcome("Converted To Sale") }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        } else {
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: 8) {
                iconButton(
                    systemName: "person.crop.circle.badge.xmark",
                    label: "Lost",
                    color: .red
                ) { stopAndHandleOutcome("Customer Lost") }

                iconButton(
                    systemName: "house.slash.fill",
                    label: "Not Home",
                    color: .gray
                ) { stopAndHandleOutcome("Wasn't Home") }

                iconButton(
                    systemName: "calendar.badge.clock",
                    label: "Follow Up",
                    color: .orange
                ) { stopAndHandleOutcome("Follow Up Later") }
            }
        }
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

    private func metricTile(value: String, label: String, systemName: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Helpers

    private var statusTitle: String {
        if isCustomer {
            return "Customer"
        }

        return place.isUnqualified ? "Unqualified Prospect" : "Prospect"
    }

    private var statusIcon: String {
        if isCustomer {
            return "checkmark.seal.fill"
        }

        return place.isUnqualified ? "xmark.octagon.fill" : "mappin.and.ellipse"
    }

    private var accentColor: Color {
        if isCustomer {
            return .green
        }

        return place.isUnqualified ? .red : .blue
    }

    private var knockSubtitle: String {
        place.count == 1 ? "Knock" : "Knocks"
    }

    private func closePopup() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onClose()
    }

    private func openContactDetails() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onViewDetails()
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

    private func startRecording() {
        guard recordingFeaturesActive else {
            showOutcomeButtons = true
            return
        }

        let result = recorder.start()
        if result.started {
            isRecording = true
            currentFileName = result.fileName
            showOutcomeButtons = true   // show outcomes alongside recording
        }
    }

    private func stopAndHandleOutcome(_ outcome: String) {
        
        // ✅ Play the same haptic and sound as adding a property
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
        showOutcomeButtons = false
    }

    private func discardRecording() {
        if let file = currentFileName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func findProspectName() -> String {
        if let contact = place.selectedContact {
            switch contact {
            case .prospect(let p): return p.fullName
            case .customer(let c): return c.fullName
            }
        }

        // fallback (single-contact markers)
        if isCustomer {
            return customers.first(where: { $0.address == place.address })?.fullName ?? "Customer"
        } else {
            return prospects.first(where: { $0.address == place.address })?.fullName ?? "Prospect"
        }
    }
}
