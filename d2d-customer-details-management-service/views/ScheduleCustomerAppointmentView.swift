//
//  ScheduleCustomerAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 10/17/25.
//

import SwiftUI
import SwiftData

struct ScheduleCustomerAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    let customer: Customer

    @State private var title = "Follow-Up"
    @State private var location = ""
    @State private var clientName = ""
    @State private var date = Date()
    @State private var type = "Follow-Up"
    @State private var notes = ""

    var body: some View {
        Form {
            Section(header: Text("Customer Info")) {
                HStack {
                    Text("Client Name")
                    Spacer()
                    Text(clientName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Location")
                    Spacer()
                    Text(location)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

            Button("Save Appointment") {
                
                // ✅ Success feedback
                FollowUpScreenHapticsController.shared.successConfirmationTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                // ✅ Create appointment directly linked to customer
                let appointment = Appointment(
                    title: title,
                    location: location,
                    clientName: clientName,
                    date: date,
                    type: type,
                    notes: customer.notes.map { $0.content }
                )

                customer.appointments.append(appointment)
                context.insert(appointment)
                try? context.save()
                dismiss()
            }
            .disabled(title.isEmpty || clientName.isEmpty)
        }
        .onAppear {
            clientName = customer.fullName
            location = customer.address
        }
        .navigationTitle("New Appointment")
    }
}
