//
//  AppointmentDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import Foundation
import SwiftData
import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment

    var body: some View {
        Form {
            Text("\(appointment.title)")
            Text("\(appointment.clientName)")
            Text("\(appointment.type)")
            Text("\(appointment.date.formatted(date: .complete, time: .shortened))")
            Text("Notes: \(appointment.notes ?? "None")")
        }
        .navigationTitle("Details")
    }
}
