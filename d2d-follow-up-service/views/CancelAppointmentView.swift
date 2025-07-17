//
//  CancelAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import SwiftUI
import SwiftData

struct CancelAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let appointment: Appointment

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Follow‑Up Appointment")
                        .font(.headline)
                    Text(appointment.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // MARK: Who & Where
                VStack(alignment: .leading, spacing: 6) {
                    Label(appointment.clientName, systemImage: "person.crop.circle")
                        .font(.title3)
                    Label(appointment.location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Notes
                if !appointment.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        ForEach(appointment.notes, id: \.self) { note in
                            Text("• \(note)")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // MARK: Actions
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        context.delete(appointment)
                        try? context.save()
                        dismiss()
                    } label: {
                        Text("Cancel Appointment")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button("Keep Appointment") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Appointment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
