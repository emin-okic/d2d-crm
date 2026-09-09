//
//  ObjectionScreenToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//

import SwiftUI

struct ObjectionScreenToolbar: View {
    var onAddTapped: () -> Void
    @Binding var isDeleting: Bool
    var selectedCount: Int
    var onDeleteConfirmed: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Spacer()

                HStack {
                    objectionToolbar

                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 16)
            }
        }
        .allowsHitTesting(true)
        .zIndex(998)
    }

    private var objectionToolbar: some View {
        VStack(spacing: 0) {
            toolbarButton(
                icon: "plus",
                color: .blue,
                accessibilityLabel: "Add Objection"
            ) {
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()
                onAddTapped()
            }

            Divider()
                .frame(width: 30)

            ZStack(alignment: .topTrailing) {
                toolbarButton(
                    icon: "trash.fill",
                    color: isDeleting || selectedCount > 0 ? .red : .blue,
                    accessibilityLabel: selectedCount > 0 ? "Delete Selected Objections" : "Enter Objection Delete Mode"
                ) {
                    RecordingScreenHapticsController.shared.mediumTap()
                    RecordingScreenSoundController.shared.playSound1()
                    if selectedCount > 0 {
                        onDeleteConfirmed()
                    } else {
                        isDeleting.toggle()
                    }
                }

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.68)))
                        .offset(x: 8, y: 2)
                }
            }
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
    }

    private func toolbarButton(
        icon: String,
        color: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
