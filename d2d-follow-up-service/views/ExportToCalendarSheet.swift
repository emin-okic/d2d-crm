//
//  ExportToCalendarSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//
import SwiftUI

struct ExportToCalendarSheet: View {
    let appointment: Appointment
    let calendarHelper: CalendarHelper
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            
            Spacer()

            VStack(spacing: 4) {
                Text("Export to Calendar")
                    .font(.headline)
                Text("Choose where to save this appointment")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                calendarButton(
                    title: "Apple Calendar",
                    icon: "applelogo",
                    color: .black
                ) {
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()

                    calendarHelper.addToAppleCalendar(appointment: appointment) { _ in }
                    dismiss()
                }

                calendarButton(
                    title: "Google Calendar",
                    icon: "g.circle",
                    color: .blue
                ) {
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()

                    calendarHelper.addToGoogleCalendar(appointment: appointment)
                    dismiss()
                }
            }

            Button("Cancel") {
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                dismiss()
            }
            .foregroundColor(.secondary)
            .padding(.top, 4)

            Spacer(minLength: 4)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private func calendarButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.body.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}
