//
//  ObjectionPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import SwiftUI

struct ObjectionPickerView: View {
    var objections: [Objection]
    var onSelect: (Objection) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(objections) { objection in
                        Button {
                            
                            // Haptics & sound on selection
                             RecordingScreenHapticsController.shared.lightTap()
                             RecordingScreenSoundController.shared.playSound1()
                            
                            dismiss()
                            DispatchQueue.main.async {
                                onSelect(objection)
                            }
                        } label: {
                            HStack {
                                Text(objection.text)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Objection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        
                        // Haptics & sound on selection
                        RecordingScreenHapticsController.shared.lightTap()
                        RecordingScreenSoundController.shared.playSound1()
                        
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.25)])
        .presentationDragIndicator(.visible)
        .background(Color(.secondarySystemBackground))
    }
}
