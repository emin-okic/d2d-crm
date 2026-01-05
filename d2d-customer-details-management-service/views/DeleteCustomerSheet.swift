//
//  DeleteCustomerSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/15/25.
//

import SwiftUI

@available(iOS 18.0, *)
struct DeleteCustomerSheet: View {
    var customerName: String
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Delete Customer")
                .font(.headline)
                .padding(.top, 8)

            // Description
            Text("Are you sure you want to delete \(customerName)? This action cannot be undone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button("Delete") {
                    onDelete()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.bottom, 16)
        }
        .padding()
    }
}
