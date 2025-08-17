//
//  TodaysAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/13/25.
//

import SwiftUI
import SwiftData
import MapKit

struct TodaysAppointmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    @State private var selectedAppointment: Appointment?
    @State private var showingProspectPicker = false
    @State private var prospectForToday: Prospect?

    // ✅ Feedback banner
    @State private var showBanner = false
    @State private var bannerMessage = ""

    // ✅ Multi-delete state (matches Recordings/Trips)
    @State private var isEditing = false
    @State private var selectedAppointments: Set<Appointment> = []
    @State private var showDeleteConfirm = false
    @State private var trashPulse = false

    private var todaysAppointments: [Appointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appointments
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            Group {
                if todaysAppointments.isEmpty {
                    Text("No appointments scheduled for today.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                } else {
                    
                    List {
                        ForEach(todaysAppointments) { appt in
                            HStack(alignment: .top, spacing: 10) {
                                if isEditing {
                                    Image(systemName: selectedAppointments.contains(appt) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Follow Up With \(appt.prospect?.fullName ?? appt.title)")
                                        .font(.subheadline).fontWeight(.medium)
                                    Text(appt.prospect?.address ?? appt.location)
                                        .font(.caption).foregroundColor(.gray)
                                    Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                            .background(
                                (isEditing && selectedAppointments.contains(appt))
                                ? Color.red.opacity(0.06)
                                : Color.clear
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditing {
                                    toggleSelection(for: appt)
                                } else {
                                    selectedAppointment = appt
                                }
                            }
                        }

                        // 🚗 NEW: Open in Apple Maps row
                        // 🚗 NEW: Open in Apple Maps row
                        if !todaysAppointments.isEmpty {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        // tap feedback animation
                                    }
                                    Task {
                                        if todaysUpcomingCount == 0 {
                                            show("No upcoming appointments left today.")
                                            return
                                        }
                                        await RoutePlannerController.planAndOpenTodaysRoute(
                                            appointments: todaysAppointments,
                                            modelContext: modelContext
                                        )
                                        show("Opened route in Apple Maps and logged trip.")
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "car.fill")
                                        Text("Open in Apple Maps")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue)
                                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                    )
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        }
                        
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 5)
                    
                }
            }

            // ⬅️ Bottom-left toolbar (plus + trash)
            VStack(spacing: 12) {
                // Add Appointment
                Button {
                    showingProspectPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }

                // Trash (multi-delete toggle/confirm)
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
                            .background(
                                Circle().fill(isEditing ? Color.red : Color.blue)
                            )
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

            // ✅ Banner
            if showBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(bannerMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(1000)
            }
        }
        .alert("Delete selected appointments?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                deleteSelected()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isEditing = false
                    trashPulse = false
                }
                show("Deleted.")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action can’t be undone.")
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
        .sheet(isPresented: $showingProspectPicker) {
            NavigationStack {
                List(prospects) { prospect in
                    Button {
                        prospectForToday = prospect
                        showingProspectPicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prospect.fullName)
                            Text(prospect.address).font(.caption).foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .navigationTitle("Pick Prospect")
                .listStyle(.plain)
            }
        }
        .sheet(item: $prospectForToday) { p in
            ScheduleAppointmentView(prospect: p, defaultDate: Date())
        }
    }

    private var todaysUpcomingCount: Int {
        let now = Date()
        return todaysAppointments.filter { $0.date >= now }.count
    }

    private func show(_ message: String) {
        bannerMessage = message
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showBanner = false }
        }
    }

    // MARK: - Multi-delete helpers

    private func toggleSelection(for appt: Appointment) {
        if selectedAppointments.contains(appt) {
            selectedAppointments.remove(appt)
        } else {
            selectedAppointments.insert(appt)
        }
    }

    private func deleteSelected() {
        for appt in selectedAppointments {
            modelContext.delete(appt)
        }
        try? modelContext.save()
        selectedAppointments.removeAll()
    }
}
