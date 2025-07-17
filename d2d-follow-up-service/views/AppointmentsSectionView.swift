//
//  AppointmentsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct AppointmentsSectionView: View {
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    @State private var showingProspectPicker = false
    @State private var selectedProspect: Prospect?
    @State private var selectedAppointment: Appointment?

    private var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Appointments")
                    .font(.headline)
                Spacer()
                Button {
                    showingProspectPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)

            if upcomingAppointments.isEmpty {
                Text("No upcoming appointments.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                List(upcomingAppointments) { appointment in
                    Button {
                        selectedAppointment = appointment
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Text("Follow Up With \(appointment.prospect?.fullName ?? "Unknown")")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(appointment.prospect?.address ?? "No Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)

                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingProspectPicker) {
            NavigationStack {
                List(prospects) { prospect in
                    Button {
                        selectedProspect = prospect
                        showingProspectPicker = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(prospect.fullName)
                            Text(prospect.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("Choose Prospect")
            }
        }
        .sheet(item: $selectedProspect) { prospect in
            ScheduleAppointmentView(prospect: prospect)
        }
        .sheet(item: $selectedAppointment) { appt in
            CancelAppointmentView(appointment: appt)
        }
    }
}
