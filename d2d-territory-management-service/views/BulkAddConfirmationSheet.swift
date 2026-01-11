//
//  BulkAddConfirmationSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/26/25.
//

import SwiftUI

struct BulkAddConfirmationSheet: View {
    let bulk: PendingBulkAdd
    let onConfirm: ([PendingAddProperty]) -> Void  // Pass selected addresses
    let onCancel: () -> Void

    // Track selection state
    @State private var selectedProperties: Set<UUID> = []

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Properties")
                .font(.title3)
                .bold()
                .padding(.top, 8)

            ScrollView {
                if bulk.properties.isEmpty {
                    Text("No new addresses found in this area.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(bulk.properties) { prop in
                            Button(action: {
                                toggleSelection(prop)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedProperties.contains(prop.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedProperties.contains(prop.id) ? .blue : .gray)
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
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            .frame(maxHeight: 300)

            HStack {
                Button("Cancel", role: .cancel) {
                    
                    MapScreenHapticsController.shared.lightTap()
                    MapScreenSoundController.shared.playPropertyOpen()
                    
                    onCancel()
                }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                    )

                Spacer()

                Button("Add Selected (\(selectedProperties.count))") {
                    
                    let selected = bulk.properties.filter { selectedProperties.contains($0.id) }
                    
                    // 🏆 Strong reward feedback
                    MapScreenHapticsController.shared.propertyAdded()
                    MapScreenSoundController.shared.playPropertyAdded()
                    
                    onConfirm(selected)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProperties.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .padding(.top)
        .onAppear {
            // Preselect all by default
            selectedProperties = Set(bulk.properties.map { $0.id })
        }
    }

    private func toggleSelection(_ prop: PendingAddProperty) {
        if selectedProperties.contains(prop.id) {
            
            selectedProperties.remove(prop.id)
            
            // 🔹 Soft deselect feedback
            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            
        } else {
            
            selectedProperties.insert(prop.id)
            
            // 🔹 Soft deselect feedback
            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            
        }
    }
}
