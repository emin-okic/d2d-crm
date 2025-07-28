//
//  CancelAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import SwiftUI
import SwiftData

struct AppointmentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let appointment: Appointment

    // — NEW STATE —
    @State private var showRescheduleSheet = false
    @State private var newDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Follow-Up Appointment")
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
                    Button("Reschedule") {
                        newDate = appointment.date
                        showRescheduleSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

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
                }
            }
            .padding()
            .navigationTitle("Appointment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // — NEW SHEET —
            .sheet(isPresented: $showRescheduleSheet) {
                RescheduleAppointmentView(
                    original: appointment,
                    newDate: $newDate
                ) {
                    // onSave: delete old, insert new, then close both
                    context.delete(appointment)
                    let recreated = Appointment(
                        title: appointment.title,
                        location: appointment.location,
                        clientName: appointment.clientName,
                        date: newDate,
                        type: appointment.type,
                        notes: appointment.notes,
                        prospect: appointment.prospect!
                    )
                    context.insert(recreated)
                    try? context.save()
                    showRescheduleSheet = false
                    dismiss()
                }
            }
        }
    }
}
