//
//  MyAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct MyAppointmentsView: View {
    @Query(sort: \Appointment.date) var appointments: [Appointment]

    var body: some View {
        NavigationStack {
            List {
                ForEach(appointments) { appt in
                    NavigationLink(destination: AppointmentDetailView(appointment: appt)) {
                        VStack(alignment: .leading) {
                            Text(appt.title)
                                .font(.headline)
                            Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Appointments")
            .toolbar {
                NavigationLink(destination: ScheduleAppointmentView()) {
                    Label("New", systemImage: "plus")
                }
            }
        }
    }
}
