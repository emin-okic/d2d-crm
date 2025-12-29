//
//  AppointmentsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct AppointmentsToolbar: View {
    
    // MARK: - Bindings & State
    @Binding var showProspectPicker: Bool
    @Binding var isEditing: Bool
    @Binding var selectedAppointments: Set<Appointment>
    @Binding var showDeleteConfirm: Bool
    @State private var trashPulse: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            
            // Add Appointment
            Button {
                showProspectPicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 4)
            }

            // Trash / Delete button
            Button {
                if isEditing {
                    if selectedAppointments.isEmpty {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            isEditing = false
                            trashPulse = false
                        }
                    } else {
                        showDeleteConfirm = true
                    }
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isEditing = true
                        trashPulse = true
                    }
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(isEditing ? Color.red : Color.blue))
                        .scaleEffect(isEditing ? (trashPulse ? 1.06 : 1.0) : 1.0)
                        .rotationEffect(.degrees(isEditing ? (trashPulse ? 2 : -2) : 0))
                        .shadow(color: (isEditing ? Color.red.opacity(0.45) : Color.black.opacity(0.25)),
                                radius: 6, x: 0, y: 2)
                        .animation(
                            isEditing
                            ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                            : .default,
                            value: trashPulse
                        )

                    if isEditing && !selectedAppointments.isEmpty {
                        Text("\(selectedAppointments.count)")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .accessibilityLabel(isEditing ? "Delete selected appointments" : "Enter delete mode")
        }
        .padding(.bottom, 30)
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
