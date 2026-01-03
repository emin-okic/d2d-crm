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
    @ObservedObject var controller: ProspectController

    // Fixed height for the appointments container
    let containerHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable appointment list
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
                            .padding(.top, 16)
                    } else {
                        ForEach(upcoming) { appt in
                            Button {
                                controller.selectedAppointmentDetails = appt
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Follow Up With \(prospect.fullName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(prospect.address)
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
                .padding(.bottom, 8) // extra padding inside scroll
            }
            .frame(height: containerHeight)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)

            // Fixed bottom button
            HStack {
                Spacer()
                Button {
                    controller.showAppointmentSheet = true
                } label: {
                    Label("Add Appointment", systemImage: "calendar.badge.plus")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 12)
    }
}
