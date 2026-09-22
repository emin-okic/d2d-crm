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
    var onCancelDelete: () -> Void
    var onDeleteConfirmed: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                toolbarContent
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.92, anchor: .bottomLeading).combined(with: .opacity),
                            removal: .opacity
                        )
                    )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .animation(.easeInOut(duration: 0.22), value: isDeleting)
        .allowsHitTesting(true)
        .zIndex(998)
    }

    @ViewBuilder
    private var toolbarContent: some View {
        if isDeleting {
            deleteActionBar
        } else {
            standardToolbar
        }
    }

    private var standardToolbar: some View {
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

            toolbarButton(
                icon: "trash",
                color: .blue,
                accessibilityLabel: "Select Objections to Delete"
            ) {
                RecordingScreenHapticsController.shared.mediumTap()
                RecordingScreenSoundController.shared.playSound1()

                withAnimation(.easeInOut(duration: 0.22)) {
                    isDeleting = true
                }
            }
        }
        .frame(width: 52)
        .background(toolbarBackground)
    }

    private var deleteActionBar: some View {
        HStack(spacing: 10) {
            Button {
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()

                withAnimation(.easeInOut(duration: 0.22)) {
                    onCancelDelete()
                    isDeleting = false
                }
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 24)

            Text("\(selectedCount) selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedCount == 0 ? .secondary : .primary)
                .contentTransition(.numericText(value: Double(selectedCount)))
                .frame(minWidth: 76)

            Button {
                RecordingScreenHapticsController.shared.mediumTap()
                RecordingScreenSoundController.shared.playSound1()
                onDeleteConfirmed()
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(
                        Capsule()
                            .fill(selectedCount > 0 ? Color.red : Color.secondary.opacity(0.35))
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedCount == 0)
            .accessibilityLabel(
                selectedCount == 1
                    ? "Delete 1 selected objection"
                    : "Delete \(selectedCount) selected objections"
            )
        }
        .padding(6)
        .background(toolbarBackground)
    }

    private var toolbarBackground: some View {
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
            .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 7)
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
