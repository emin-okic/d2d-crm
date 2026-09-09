//
//  AppointmentsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct AppointmentsToolbar: View {

    @Binding var showProspectPicker: Bool
    @Binding var isEditing: Bool
    @Binding var selectedAppointments: Set<Appointment>
    @Binding var showDeleteConfirm: Bool

    @State private var trashPulse = false

    var body: some View {
        VStack {
            Spacer()

            assistantToolbar
                .padding(.leading, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }

    private var assistantToolbar: some View {
        VStack(spacing: 0) {
            toolbarButton(
                icon: "plus",
                color: .blue,
                accessibilityLabel: "Add Appointment"
            ) {
                FollowUpScreenHapticsController.shared.successConfirmationTap()
                FollowUpScreenSoundController.shared.playSound1()

                showProspectPicker = true
            }

            toolbarDivider

            ZStack(alignment: .topTrailing) {
                toolbarButton(
                    icon: "trash.fill",
                    color: isEditing ? .red : .blue,
                    accessibilityLabel: isEditing ? "Delete Selected Appointments" : "Enter Appointment Delete Mode"
                ) {
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()

                    if isEditing {
                        selectedAppointments.isEmpty
                        ? exitEditMode()
                        : showDeleteConfirm.toggle()
                    } else {
                        enterEditMode()
                    }
                }

                if isEditing && !selectedAppointments.isEmpty {
                    Text("\(selectedAppointments.count)")
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

    private var toolbarDivider: some View {
        Divider()
            .frame(width: 30)
    }

    // MARK: Helpers

    private func enterEditMode() {
        withAnimation(.spring()) {
            isEditing = true
            trashPulse = true
        }
    }

    private func exitEditMode() {
        withAnimation(.spring()) {
            isEditing = false
            trashPulse = false
        }
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
                .scaleEffect(isEditing && icon == "trash.fill" ? (trashPulse ? 1.06 : 1.0) : 1.0)
                .rotationEffect(.degrees(isEditing && icon == "trash.fill" ? (trashPulse ? 2 : -2) : 0))
                .animation(
                    isEditing && icon == "trash.fill"
                    ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                    : .default,
                    value: trashPulse
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
