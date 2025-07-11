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
    @State private var showingAddAppointment = false
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
                    showingAddAppointment = true
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
                            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading) {
                                Text(appointment.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let note = appointment.notes {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingAddAppointment) {
            ScheduleAppointmentView()
        }
        .sheet(item: $selectedAppointment) { appt in
            CancelAppointmentView(appointment: appt)
        }
    }
}
