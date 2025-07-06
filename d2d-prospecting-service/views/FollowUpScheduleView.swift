//
//  FollowUpScheduleView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct FollowUpScheduleView: View {
    let address: String
    let prospectName: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    @State private var followUpDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Follow-Up")) {
                    Text("Prospect: \(prospectName)")
                    Text("Address: \(address)")
                    DatePicker("Follow-Up Date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Note", text: $note)
                }

                Button("Save Follow-Up") {
                    let appt = Appointment(
                        title: "Follow-Up",
                        location: address,
                        clientName: prospectName,
                        date: followUpDate,
                        type: "Follow-Up",
                        notes: note
                    )
                    context.insert(appt)
                    dismiss()
                }
                .disabled(prospectName.isEmpty || address.isEmpty)
            }
            .navigationTitle("Follow-Up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
