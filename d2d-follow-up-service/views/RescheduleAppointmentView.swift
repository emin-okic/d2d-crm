//
//  RescheduleAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/28/25.
//


import SwiftUI

struct RescheduleAppointmentView: View {
    let original: Appointment
    @Binding var newDate: Date
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pick New Date & Time")) {
                    DatePicker("Reschedule to", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Reschedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // just dismiss
                        newDate = original.date
                        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(newDate == original.date)
                }
            }
        }
    }
}
