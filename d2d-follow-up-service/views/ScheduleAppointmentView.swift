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
        ScrollView {
            VStack(spacing: 16) {

                // Prospect Card
                card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prospect")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text(clientName)
                            .font(.title3.weight(.semibold))

                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Appointment Details
                card {
                    VStack(alignment: .leading, spacing: 14) {

                        labeledField("Type") {
                            Text(type)
                                .foregroundColor(.secondary)
                        }

                        labeledField("Date & Time") {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                    }
                }

                // Notes Preview
                if !prospect.notes.isEmpty {
                    card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes from Knocks")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            ForEach(prospect.notes.prefix(3), id: \.id) { note in
                                Text("• \(note.content)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Save Button
                Button {
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
                } label: {
                    Text("Save Appointment")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(title.isEmpty || clientName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(title.isEmpty || clientName.isEmpty)
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Schedule Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            clientName = prospect.fullName
            location = prospect.address
        }
    }

    // MARK: - Helpers

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            content()
        }
    }
}
