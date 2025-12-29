//
//  FullScreenAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI
import SwiftData

struct FullScreenAppointmentsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var prospects: [Prospect]

    @State private var showProspectPicker = false
    @State private var showScheduleAppointment = false
    @State private var prospectToSchedule: Prospect?

    // Multi-delete state
    @State private var isEditing = false
    @State private var selectedAppointments: Set<Appointment> = []
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false

    @State private var selectedAppointment: Appointment?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {

                AppointmentsSectionView(
                    isEditing: $isEditing,
                    selectedAppointments: $selectedAppointments,
                    maxScrollHeight: UIScreen.main.bounds.height * 0.50
                )
                .navigationTitle("Appointments")
                .navigationBarTitleDisplayMode(.inline)

                // Bottom-left toolbar with trash button
                VStack(spacing: 12) {
                    
                    // Add Appointment button
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

                    // Trash button (toggle multi-delete / confirm)
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }

            // Prospect Picker sheet
            .sheet(isPresented: $showProspectPicker) {
                NavigationStack {
                    List(prospects) { prospect in
                        Button {
                            prospectToSchedule = prospect
                            showProspectPicker = false
                            showScheduleAppointment = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prospect.fullName)
                                Text(prospect.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .navigationTitle("Pick Prospect")
                    .listStyle(.plain)
                }
            }

            // Schedule Appointment sheet
            .sheet(isPresented: $showScheduleAppointment, onDismiss: {
                prospectToSchedule = nil
            }) {
                if let prospect = prospectToSchedule {
                    ScheduleAppointmentView(prospect: prospect)
                }
            }

            // Delete confirmation
            .alert("Delete selected appointments?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteSelected()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isEditing = false
                        trashPulse = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action can’t be undone.")
            }
        }
    }

    private func toggleSelection(for appt: Appointment) {
        if selectedAppointments.contains(appt) {
            selectedAppointments.remove(appt)
        } else {
            selectedAppointments.insert(appt)
        }
    }

    private func deleteSelected() {
        withAnimation {
            // Copy the selection to avoid mutating the set while iterating
            let appointmentsToDelete = selectedAppointments
            selectedAppointments.removeAll() // remove before deleting from context

            for appt in appointmentsToDelete {
                modelContext.delete(appt)
            }

            do {
                try modelContext.save()
            } catch {
                print("Error saving after deletion: \(error)")
            }
        }
    }
}
