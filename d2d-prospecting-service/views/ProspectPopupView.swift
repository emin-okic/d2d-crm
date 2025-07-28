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
    var onLogKnock: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Button(action: onLogKnock) {
                Text("Log Knock")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 240)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 6)
    }

    func findProspectName(for address: String) -> String {
        // You can improve this by passing a name directly or querying from outside
        return "Prospect"
    }
}
