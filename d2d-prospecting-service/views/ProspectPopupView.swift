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
    var onOutcomeSelected: (String) -> Void

    @State private var showConvertConfirm = false
    @State private var showFollowUpConfirm = false

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

            HStack(spacing: 16) {
                iconButton(
                    systemName: "house.slash.fill",
                    label: "Not Home",
                    color: .gray
                ) {
                    onOutcomeSelected("Wasn't Home")
                }

                iconButton(
                    systemName: "checkmark.seal.fill",
                    label: "Sale",
                    color: .green
                ) {
                    showConvertConfirm = true
                }

                iconButton(
                    systemName: "calendar.badge.clock",
                    label: "Follow Up",
                    color: .orange
                ) {
                    showFollowUpConfirm = true
                }
            }
            .padding(.top, 6)
        }
        .padding()
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 6)
        .alert("Convert to Customer?", isPresented: $showConvertConfirm) {
            Button("Yes") { onOutcomeSelected("Converted To Sale") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Convert this lead to a customer?")
        }
        .alert("Schedule Follow-Up?", isPresented: $showFollowUpConfirm) {
            Button("Yes") { onOutcomeSelected("Follow Up Later") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Schedule a follow-up for this address?")
        }
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

    private func findProspectName(for address: String) -> String {
        return "Prospect"
    }
}
