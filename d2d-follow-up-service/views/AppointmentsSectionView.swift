//
//  AppointmentsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//

import SwiftUI
import SwiftData

struct AppointmentsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    // Parent bindings for multi-delete
    @Binding var isEditing: Bool
    @Binding var selectedAppointments: Set<Appointment>

    @State private var selectedAppointment: Appointment?
    
    @State private var appointmentToDelete: Appointment?
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var filter: AppointmentFilter = .upcoming
    private let filterKey = "lastSelectedAppointmentFilter"

    private var now: Date { Date() }

    private var upcomingCount: Int { appointments.filter { $0.date >= now }.count }
    private var pastCount: Int { appointments.filter { $0.date <  now }.count }
    
    @Binding var filteredAppointments: [Appointment]

    private var filteredAppointmentsInternal: [Appointment] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case .today:
            return appointments
                .filter { calendar.isDate($0.date, inSameDayAs: now) }
                .sorted { $0.date < $1.date }
        case .upcoming:
            return appointments
                .filter { $0.date >= now && !calendar.isDateInToday($0.date) }
                .sorted { $0.date < $1.date }
        case .past:
            return appointments
                .filter { $0.date < now && !calendar.isDateInToday($0.date) }
                .sorted { $0.date > $1.date }
        }
    }
    
    private let rowHeight: CGFloat = 74
    var maxScrollHeight: CGFloat? = nil

    var body: some View {
        ZStack {
                VStack(alignment: .leading, spacing: 12) {

                    // ===== White pill header =====
                    VStack(spacing: 4) {
                        Text("Appointments")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        let calendar = Calendar.current
                        let now = Date()
                        Text(filter == .today
                             ? "\(appointments.filter { calendar.isDate($0.date, inSameDayAs: now) }.count) Today's Appointments"
                             : filter == .upcoming
                             ? "\(appointments.filter { $0.date >= now && !calendar.isDateInToday($0.date) }.count) Upcoming Appointments"
                             : "\(appointments.filter { $0.date < now && !calendar.isDateInToday($0.date) }.count) Past Appointments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    
                    // Toggle chips
                    HStack(spacing: 8) {
                        toggleChip("Today", isOn: filter == .today) { filter = .today }
                        toggleChip("Upcoming", isOn: filter == .upcoming) { filter = .upcoming }
                        toggleChip("Past", isOn: filter == .past) { filter = .past }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                    // MARK: Appointments list or empty state
                    if filteredAppointmentsInternal.isEmpty {
                        VStack(spacing: 24) {
                            Text("No \(filter.rawValue) Appointments")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 16)
                    } else {
                        List {
                            ForEach(filteredAppointmentsInternal) { appt in
                                AppointmentRowView(
                                    appt: appt,
                                    isEditing: isEditing,
                                    isSelected: selectedAppointments.contains(appt)
                                )
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    
                                    // ✅ Haptic + sound on row tap
                                    FollowUpScreenHapticsController.shared.lightTap()
                                    FollowUpScreenSoundController.shared.playSound1()
                                    
                                    if isEditing {
                                        
                                        toggleSelection(for: appt)
                                        
                                    } else {
                                        
                                        selectedAppointment = appt
                                        
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    
                                    Button(role: .destructive) {
                                        
                                        // ✅ Haptic + sound
                                        FollowUpScreenHapticsController.shared.mediumTap()
                                        FollowUpScreenSoundController.shared.playSound1()
                                        
                                        appointmentToDelete = appt
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 12)
                .sheet(item: $selectedAppointment) { appt in
                    AppointmentDetailsView(appointment: appt)
                }
        }
        .alert("Delete Appointment?", isPresented: $showDeleteConfirmation, presenting: appointmentToDelete) { appt in
            Button("Delete", role: .destructive) {
                
                // ✅ Stronger feedback on destructive action
                FollowUpScreenHapticsController.shared.mediumTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                deleteAppointment(appt)
            }
            Button("Cancel", role: .cancel) {
                
                // ✅ Subtle cancel feedback
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                
            }
        } message: { appt in
            Text("Are you sure you want to delete this appointment? This action cannot be undone.")
        }
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: filterKey),
               let parsed = AppointmentFilter(rawValue: saved) {
                filter = parsed
            } else {
                filter = .upcoming
            }
        }
        .onChange(of: filter) {
            UserDefaults.standard.set(filter.rawValue, forKey: filterKey)
        }
        .onChange(of: filteredAppointmentsInternal) { newValue in
            filteredAppointments = newValue
        }
    }

    // MARK: - Multi-select helpers
    private func toggleSelection(for appt: Appointment) {
        if selectedAppointments.contains(appt) {
            selectedAppointments.remove(appt)
        } else {
            selectedAppointments.insert(appt)
        }
    }
    
    private func deleteAppointment(_ appt: Appointment) {
        withAnimation {
            // Deselect if needed
            selectedAppointments.remove(appt)
            
            // Delete from context
            modelContext.delete(appt)
            do {
                try modelContext.save()
            } catch {
                print("Error saving after appointment deletion: \(error)")
            }
        }
    }

    @ViewBuilder
    private func toggleChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            // ✅ Play haptics + sound on tap
            FollowUpScreenHapticsController.shared.lightTap()
            FollowUpScreenSoundController.shared.playSound1()
            
            // Execute the actual filter change
            action()
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(minWidth: 72)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
    
}
