//
//  BulkAddConfirmationSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/26/25.
//

import SwiftUI

struct BulkAddConfirmationSheet: View {
    let bulk: PendingBulkAdd
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add These Properties?")
                .font(.headline)

            ScrollView {
                if bulk.properties.isEmpty {
                    Text("No new addresses found in this area.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bulk.properties) { prop in
                            Text(prop.address)
                                .font(.subheadline)
                        }
                    }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }

                Spacer()

                Button("Add All (\(bulk.properties.count))") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(bulk.properties.isEmpty)
            }
        }
        .padding()
    }
}
