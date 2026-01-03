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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if prospect.appointments.filter({ $0.date >= Date() }).isEmpty {
                Text("No upcoming follow-ups.")
                    .foregroundColor(.gray)
                    .font(.callout)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(prospect.appointments.filter { $0.date >= Date() }.sorted { $0.date < $1.date }) { appt in
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
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 60) // extra padding so last row isn't cut off by floating toolbar
                }
            }

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
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
    }
}
