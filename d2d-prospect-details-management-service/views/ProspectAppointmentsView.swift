//
//  ProspectAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

struct ProspectAppointmentsView: View {
    
    @Bindable var prospect: Prospect
    @ObservedObject var controller: ProspectDetailsController

    // ~3 rows worth of height (tweak if needed)
    private let maxListHeight: CGFloat = 220

    var body: some View {
        VStack(spacing: 12) {

            ScrollView {
                LazyVStack(spacing: 12) {
                    let upcoming = prospect.appointments
                        .filter { $0.date >= Date() }
                        .sorted { $0.date < $1.date }

                    if upcoming.isEmpty {
                        Text("No upcoming follow-ups.")
                            .foregroundColor(.gray)
                            .font(.callout)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(upcoming) { appt in
                            Button {
                                
                                // ✅ Haptics + sound for selecting an appointment
                                ContactDetailsHapticsController.shared.mapTap()
                                ContactScreenSoundController.shared.playPropertyOpen()
                                
                                controller.selectedAppointmentDetails = appt
                                
                            } label: {
                                appointmentRow(appt)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: maxListHeight) // ✅ THIS is the magic
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 4)

            // Fixed bottom action
            HStack {
                Spacer()
                Button {
                    
                    // ✅ Haptics + sound for opening Add Appointment sheet
                    ContactDetailsHapticsController.shared.mapTap()
                    ContactScreenSoundController.shared.playPropertyOpen()
                    
                    controller.showAppointmentSheet = true
                    
                } label: {
                    Label("Add Appointment", systemImage: "calendar.badge.plus")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 12)
        .sheet(isPresented: $controller.showAppointmentSheet) {
            NavigationStack {
                ScheduleAppointmentView(prospect: prospect)
            }
        }
        .sheet(item: $controller.selectedAppointmentDetails) { appointment in
            AppointmentDetailsView(appointment: appointment)
        }
    }

    // MARK: - Row View (kept clean)
    @ViewBuilder
    private func appointmentRow(_ appt: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Follow Up With \(prospect.fullName)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(prospect.address)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(
                    appt.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4)
        )
    }
}
