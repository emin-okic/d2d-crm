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

    let prospect: Prospect
    
    var defaultDate: Date? = nil

    @State private var title = "Follow-Up"
    @State private var location = ""
    @State private var clientName = ""
    @State private var date = Date()
    @State private var type = "Follow-Up"
    @State private var notes = ""
    
    init(prospect: Prospect, defaultDate: Date? = nil) {
            self.prospect = prospect
            self.defaultDate = defaultDate
            _date = State(initialValue: defaultDate ?? Date())
        }

    var body: some View {
        Form {
            Section(header: Text("Prospect Info")) {
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
                
                let appointment = Appointment(
                    title: title,
                    location: location,
                    clientName: clientName,
                    date: date,
                    type: type,
                    notes: prospect.notes.map { $0.content },
                    prospect: prospect
                )
                context.insert(appointment)
                dismiss()
            }
            .disabled(title.isEmpty || clientName.isEmpty)
        }
        .onAppear {
            clientName = prospect.fullName
            location = prospect.address
        }
        .navigationTitle("New Appointment")
    }
}
