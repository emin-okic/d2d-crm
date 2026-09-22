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
        .animation(.easeInOut(duration: 0.22), value: isEditing)
        .zIndex(999)
    }

    @ViewBuilder
    private var toolbarContent: some View {
        if isEditing {
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
                accessibilityLabel: "Add Appointment"
            ) {
                FollowUpScreenHapticsController.shared.successConfirmationTap()
                FollowUpScreenSoundController.shared.playSound1()

                showProspectPicker = true
            }

            toolbarDivider

            toolbarButton(
                icon: "trash",
                color: .blue,
                accessibilityLabel: "Select Appointments to Delete"
            ) {
                FollowUpScreenHapticsController.shared.successConfirmationTap()
                FollowUpScreenSoundController.shared.playSound1()

                withAnimation(.easeInOut(duration: 0.22)) {
                    isEditing = true
                }
            }
        }
        .frame(width: 52)
        .background(toolbarBackground)
    }

    private var deleteActionBar: some View {
        HStack(spacing: 10) {
            Button {
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()

                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedAppointments.removeAll()
                    isEditing = false
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

            Text("\(selectedAppointments.count) selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedAppointments.isEmpty ? .secondary : .primary)
                .contentTransition(.numericText(value: Double(selectedAppointments.count)))
                .frame(minWidth: 76)

            Button {
                FollowUpScreenHapticsController.shared.mediumTap()
                FollowUpScreenSoundController.shared.playSound1()
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(
                        Capsule()
                            .fill(selectedAppointments.isEmpty ? Color.secondary.opacity(0.35) : Color.red)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedAppointments.isEmpty)
            .accessibilityLabel(
                selectedAppointments.count == 1
                    ? "Delete 1 selected appointment"
                    : "Delete \(selectedAppointments.count) selected appointments"
            )
        }
        .padding(6)
        .background(toolbarBackground)
    }

    private var toolbarDivider: some View {
        Divider()
            .frame(width: 30)
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
