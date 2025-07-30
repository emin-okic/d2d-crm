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

            VStack(spacing: 8) {
                Button("Wasn't Home") {
                    onOutcomeSelected("Wasn't Home")
                }
                .buttonStyle(.borderedProminent)

                Button("Converted To Sale") {
                    onOutcomeSelected("Converted To Sale")
                }
                .buttonStyle(.borderedProminent)

                Button("Follow-Up Later") {
                    onOutcomeSelected("Follow Up Later")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 6)
    }

    func findProspectName(for address: String) -> String {
        return "Prospect" // Improve with external lookup if needed
    }
}
