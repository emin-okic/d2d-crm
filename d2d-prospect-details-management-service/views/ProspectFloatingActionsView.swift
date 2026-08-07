//
//  ProspectFloatingActionsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct ProspectFloatingActionsView: View {
    let onDeleteTapped: () -> Void
    let onNotesTapped: () -> Void

    var body: some View {
        LiquidGlassToolbarBackground {
            HStack(spacing: 12) {
                Button(action: {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    onNotesTapped()
                }) {
                    Label("Notes", systemImage: "note.text")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    onDeleteTapped()
                }) {
                    Label("Delete", systemImage: "trash.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            .padding(10)
        }
    }
}
