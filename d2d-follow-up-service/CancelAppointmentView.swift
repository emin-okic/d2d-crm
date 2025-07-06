//
//  CancelAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//


import SwiftUI
import SwiftData

struct CancelAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    var appointment: Appointment

    var body: some View {
        VStack(spacing: 20) {
            Text("Cancel this appointment?")
                .font(.title2)

            Text(appointment.title)
            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))

            Button(role: .destructive) {
                context.delete(appointment)
                dismiss()
            } label: {
                Label("Cancel Appointment", systemImage: "trash")
            }

            Button("Keep") {
                dismiss()
            }
        }
        .padding()
    }
}
