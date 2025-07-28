//
//  TodaysAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/13/25.
//

import SwiftUI
import SwiftData

struct TodaysAppointmentsView: View {
    @Query private var appointments: [Appointment]
    @State private var selectedAppointment: Appointment?

    private var todaysAppointments: [Appointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appointments
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        Group {
            if todaysAppointments.isEmpty {
                Text("No appointments scheduled for today.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                List(todaysAppointments) { appointment in
                    Button {
                        selectedAppointment = appointment
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow Up With \(appointment.prospect?.fullName ?? appointment.title)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(appointment.prospect?.address ?? "")
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
        .sheet(item: $selectedAppointment) { appt in
            CancelAppointmentView(appointment: appt)
        }
    }
}
