//
//  FollowUpScheduleView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct FollowUpScheduleView: View {
    let prospect: Prospect
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    @State private var followUpDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Follow-Up")) {
                    Text("Prospect: \(prospect.fullName)")
                    Text("Address: \(prospect.address)")
                    DatePicker("Follow-Up Date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Note", text: $note)
                }

                Button("Save Follow-Up") {
                    let appt = Appointment(
                        title: "Follow-Up",
                        location: prospect.address,
                        clientName: prospect.fullName,
                        date: followUpDate,
                        type: "Follow-Up",
                        notes: prospect.notes.map { $0.content },
                        prospect: prospect
                    )
                    context.insert(appt)
                    dismiss()
                }
                .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
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
