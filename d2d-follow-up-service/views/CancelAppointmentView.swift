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
            Text("Your Appointment Details")
                .font(.title2)

            Text(appointment.title)
            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))

            if !appointment.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes at Time of Scheduling:")
                        .font(.headline)

                    ForEach(appointment.notes, id: \.self) { note in
                        Text("• \(note)")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }

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
