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
            // Title
            Text("Add Properties")
                .font(.title3)
                .bold()
                .padding(.top, 8)

            // Address list
            ScrollView {
                if bulk.properties.isEmpty {
                    Text("No new addresses found in this area.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(bulk.properties) { prop in
                            HStack(spacing: 12) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prop.address)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            .frame(maxHeight: 300) // limit height so scroll appears if needed

            // Buttons
            HStack {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                )

                Spacer()

                Button("Add All (\(bulk.properties.count))") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(bulk.properties.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .padding(.top)
    }
}
