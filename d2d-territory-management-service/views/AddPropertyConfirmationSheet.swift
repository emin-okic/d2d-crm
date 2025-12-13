//
//  AddPropertyConfirmationSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/13/25.
//
import SwiftUI

/// This class provides the essential UI for adding new properties to the map screen
struct AddPropertyConfirmationSheet: View {
    let address: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Map preview
            MapSnapshotView(address: address)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 6) {
                Text("Add Property?")
                    .font(.headline)

                Text(address)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .frame(maxWidth: .infinity)

                Button("Add") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
