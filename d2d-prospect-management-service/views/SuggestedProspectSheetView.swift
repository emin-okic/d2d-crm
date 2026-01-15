//
//  SuggestedProspectSheetView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI

struct SuggestedProspectSheetView: View {
    
    let suggestion: Prospect
    var onAdd: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            
            // 🔹 Map snapshot at the top
            MapSnapshotView(address: suggestion.address)
                .frame(height: 180)
                .cornerRadius(12)
                .padding(.horizontal)
            
            // 🔹 Prospect info
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Neighbor")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(suggestion.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 🔹 Buttons
            HStack(spacing: 20) {
                
                Button(action: {
                    // ✅ Haptics & Sound for adding a suggested prospect
                    ContactDetailsHapticsController.shared.propertyAdded()
                    ContactScreenSoundController.shared.playPropertyAdded()
                    
                    onAdd()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    // ✅ Subtle haptics & sound for dismiss
                    ContactDetailsHapticsController.shared.mapTap()
                    ContactScreenSoundController.shared.playPropertyOpen()
                    
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Dismiss")
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
