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

    @State private var title = "Follow-Up "
    @State private var location = ""
    @State private var clientName = ""
    @State private var date = Date()
    @State private var type = "Follow-Up"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Customer Card
                    card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Customer")
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
                    if !customer.notes.isEmpty {
                        card {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Customer Notes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)

                                ForEach(customer.notes.prefix(3), id: \.id) { note in
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
                            title: "\(customer.fullName)",
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
                    } label: {
                        Text("Schedule Appointment")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        FollowUpScreenHapticsController.shared.lightTap()
                        FollowUpScreenSoundController.shared.playSound1()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                clientName = customer.fullName
                location = customer.address
            }
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
