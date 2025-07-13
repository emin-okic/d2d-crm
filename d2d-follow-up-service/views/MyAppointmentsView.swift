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
    @State private var showProspectPicker = false
    @State private var selectedProspect: Prospect?

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
                Button {
                    showProspectPicker = true
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showProspectPicker) {
                NavigationStack {
                    ProspectPickerView { prospect in
                        selectedProspect = prospect
                    }
                }
            }
            .sheet(item: $selectedProspect) { prospect in
                ScheduleAppointmentView(prospect: prospect)
            }
        }
    }
}
