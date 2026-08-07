//
//  CustomerFloatingActionsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI

struct CustomerFloatingActionsView: View {
    let onDeleteTapped: () -> Void
    let onNotesTapped: () -> Void

    var body: some View {
        LiquidGlassToolbarBackground {
            HStack(spacing: 12) {
                Button(action: onNotesTapped) {
                    Label("Notes", systemImage: "note.text")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: onDeleteTapped) {
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
