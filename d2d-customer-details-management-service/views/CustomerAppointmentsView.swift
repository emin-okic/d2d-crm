//
//  CustomerAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

@available(iOS 18.0, *)
struct CustomerAppointmentsView: View {
    @Bindable var customer: Customer
    @StateObject private var controller = CustomerAppointmentsController()

    // Fixed height for appointments container
    let containerHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable appointment list
            ScrollView {
                LazyVStack(spacing: 12) {
                    let upcoming = customer.appointments
                        .filter { $0.date >= Date() }
                        .sorted { $0.date < $1.date }

                    if upcoming.isEmpty {
                        Text("No upcoming follow-ups.")
                            .foregroundColor(.gray)
                            .font(.callout)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                    } else {
                        ForEach(upcoming) { appt in
                            Button {
                                
                                // ✅ Haptics + sound for selecting an appointment
                                ContactDetailsHapticsController.shared.mapTap()
                                ContactScreenSoundController.shared.playPropertyOpen()
                                
                                controller.selectedAppointment = appt
                                
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Follow Up With \(customer.fullName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(customer.address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(appt.date.formatted(date: .abbreviated, time: .shortened))
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
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .frame(height: containerHeight)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)

            // Fixed bottom button
            HStack {
                Spacer()
                Button {
                    
                    // ✅ Haptics + sound for opening Add Appointment sheet
                    ContactDetailsHapticsController.shared.mapTap()
                    ContactScreenSoundController.shared.playPropertyOpen()
                    
                    controller.showAppointmentSheet = true
                    
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .buttonStyle(.plain)
                
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 12)
        // Sheets
        .sheet(isPresented: $controller.showAppointmentSheet) {
            NavigationStack {
                ScheduleCustomerAppointmentView(customer: customer)
            }
        }
        .sheet(item: $controller.selectedAppointment) { appointment in
            AppointmentDetailsView(appointment: appointment)
        }
    }
}
