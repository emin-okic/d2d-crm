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

    let todaysAppointments: [Appointment]

    @State private var trashPulse = false

    var body: some View {
        VStack {
            Spacer()

            LiquidGlassToolbarContainer {

                // MARK: Add Appointment
                toolbarButton(
                    icon: "plus",
                    color: .blue
                ) {
                    showProspectPicker = true
                }

                // MARK: Delete / Edit Mode
                toolbarButton(
                    icon: "trash.fill",
                    color: isEditing ? .red : .blue
                ) {
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
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                }

                // MARK: Apple Maps Button (NEW LOCATION)
                OpenInAppleMapsButton(
                    appointments: todaysAppointments
                )
            }
            .frame(width: 72)
            .frame(maxHeight: 130)
            .padding(.leading, 16)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .zIndex(999)
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
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(color))
        }
    }
}
