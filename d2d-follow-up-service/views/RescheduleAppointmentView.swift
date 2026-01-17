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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {

            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("Reschedule")
                    .font(.title3.bold())
                Text("Pick a new date and time")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // Card
            VStack(alignment: .leading, spacing: 12) {
                Text("New Date & Time")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                DatePicker(
                    "",
                    selection: $newDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            )

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    FollowUpScreenHapticsController.shared.lightTap()
                    FollowUpScreenSoundController.shared.playSound1()

                    newDate = original.date
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)

                Button("Save") {
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()

                    onSave()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(newDate == original.date ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(newDate == original.date)
            }
            .padding(.top, 4)

            Spacer(minLength: 8)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color(.systemGroupedBackground))
    }
}
