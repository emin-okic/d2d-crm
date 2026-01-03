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
        let upcoming = prospect.appointments
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .prefix(3)

        VStack(alignment: .leading, spacing: 8) {
            if upcoming.isEmpty {
                Text("No upcoming follow-ups.")
                    .foregroundColor(.gray)
            } else {
                ForEach(upcoming) { appt in
                    Button {
                        controller.selectedAppointmentDetails = appt
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow Up With \(prospect.fullName)")
                                .font(.subheadline).fontWeight(.medium)
                            Text(prospect.address)
                                .font(.caption).foregroundColor(.gray)
                            Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                controller.showAppointmentSheet = true
            } label: {
                Label("Add Appointment", systemImage: "calendar.badge.plus")
            }
            .padding(.top, 6)
        }
    }
}
