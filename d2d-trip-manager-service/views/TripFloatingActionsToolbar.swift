//
//  TripFloatingActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//
import SwiftUI

struct TripFloatingActionsToolbar: View {
    private let toolbarButtonSize: CGFloat = 46

    let isEditing: Bool
    let selectedCount: Int
    let trashPulse: Bool

    let onAdd: () -> Void
    let onTrashTap: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                // ➕ Add Trip
                Button {
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: toolbarButtonSize, height: toolbarButtonSize)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(width: 30)

                // 🗑 Trash / Multi-delete
                Button {
                    TripManagerHapticsController.shared.lightTap()
                    TripManagerSoundController.shared.playSound1()
                    onTrashTap()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(isEditing ? Color.red : Color.blue)
                            .frame(width: toolbarButtonSize, height: toolbarButtonSize)
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
                .buttonStyle(.plain)
                .accessibilityLabel(isEditing ? "Delete selected trips" : "Enter delete mode")
            }
            .frame(width: 52)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground).opacity(0.58))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
            .shadow(color: Color.blue.opacity(0.08), radius: 6, x: 0, y: 2)
            .padding(.leading, 20)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
