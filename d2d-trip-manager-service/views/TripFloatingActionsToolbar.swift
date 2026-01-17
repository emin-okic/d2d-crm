//
//  TripFloatingActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//
import SwiftUI

struct TripFloatingActionsToolbar: View {
    let isEditing: Bool
    let selectedCount: Int
    let trashPulse: Bool

    let onAdd: () -> Void
    let onTrashTap: () -> Void

    var body: some View {
        VStack {
            Spacer()

            LiquidGlassToolbarContainer {

                // ➕ Add Trip
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Color.blue))
                }

                // 🗑 Trash / Multi-delete
                Button(action: onTrashTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle().fill(isEditing ? Color.red : Color.blue)
                            )
                            .scaleEffect(isEditing ? (trashPulse ? 1.06 : 1.0) : 1.0)
                            .rotationEffect(.degrees(isEditing ? (trashPulse ? 2 : -2) : 0))
                            .animation(
                                isEditing
                                ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                                : .default,
                                value: trashPulse
                            )

                        if isEditing && selectedCount > 0 {
                            Text("\(selectedCount)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.black.opacity(0.6)))
                        }
                    }
                }
                .accessibilityLabel(isEditing ? "Delete selected trips" : "Enter delete mode")
            }
            .frame(width: 72)
            .frame(maxHeight: 130)
            .padding(.leading, 16)
            .padding(.bottom, 30)   // same as other screens
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
