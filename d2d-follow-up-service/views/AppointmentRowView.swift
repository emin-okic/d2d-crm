//
//  AppointmentRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//
import SwiftUI
import SwiftData

struct AppointmentRowView: View {
    let appt: Appointment
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Follow Up With \(appt.prospect?.fullName ?? appt.title)")
                .font(.body).fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(appt.prospect?.address ?? appt.location)
                .font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20) // match your list horizontal padding
        .background(Color(.systemGray6))
    }
}
