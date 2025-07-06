//
//  ScheduleAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct ScheduleAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    @State private var title = ""
    @State private var location = ""
    @State private var clientName = ""
    @State private var date = Date()
    @State private var type = ""
    @State private var notes = ""

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Location", text: $location)
            TextField("Client Name", text: $clientName)
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            TextField("Type", text: $type)
            TextField("Notes", text: $notes)

            Button("Save Appointment") {
                let appointment = Appointment(title: title, location: location, clientName: clientName, date: date, type: type, notes: notes)
                context.insert(appointment)
                dismiss()
            }
            .disabled(title.isEmpty || clientName.isEmpty)
        }
        .navigationTitle("New Appointment")
    }
}
