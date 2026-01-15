//
//  DeleteProspectSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/15/25.
//
import SwiftUI

struct DeleteProspectSheet: View {
    var prospectName: String
    var onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Delete Contact")
                .font(.headline)
            
            Text("Are you sure you want to delete \(prospectName)? This action cannot be undone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    
                    // Haptic + Sound on sheet appear
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                
                Button("Delete") {
                    
                    // Haptic + Sound on sheet appear
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    onDelete()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
    }
}
