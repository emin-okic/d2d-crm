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
        return appointments.filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            if todaysAppointments.isEmpty {
                Text("No appointments scheduled for today.")
                    .foregroundColor(.gray)
            } else {
                ForEach(todaysAppointments) { appt in
                    Button {
                        selectedAppointment = appt
                    } label: {
                        VStack(alignment: .leading) {
                            Text(appt.title)
                                .font(.headline)
                            Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedAppointment) { appt in
            CancelAppointmentView(appointment: appt)
        }
    }
}
